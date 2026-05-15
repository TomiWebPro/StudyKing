import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/repositories/student_availability_repository.dart';
import '../../services/planner_service.dart';

class LessonBookingSheet extends StatefulWidget {
  final String topicId;
  final String topicTitle;
  final String subjectId;
  final Future<void> Function(DateTime scheduledTime, int durationMinutes)
      onSchedule;
  final PlannerService? plannerService;

  const LessonBookingSheet({
    super.key,
    required this.topicId,
    required this.topicTitle,
    required this.subjectId,
    required this.onSchedule,
    this.plannerService,
  });

  @override
  State<LessonBookingSheet> createState() => _LessonBookingSheetState();
}

class _LessonBookingSheetState extends State<LessonBookingSheet> {
  TimeOfDay _selectedTime = TimeOfDay(
    hour: DateTime.now().hour + 1,
    minute: 0,
  );
  DateTime _selectedDate = DateTime.now();
  int _durationMinutes = 30;
  bool _isScheduling = false;
  bool _hasConflict = false;
  bool _isCheckingConflict = false;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    try {
      final repo = StudentAvailabilityRepository();
      await repo.init();
      final availability = await repo.getByStudent(
        widget.plannerService?.studentId ?? '',
      );
      if (availability != null && mounted) {
        setState(() {
          _selectedTime = TimeOfDay(
            hour: availability.preferredStartHour,
            minute: 0,
          );
          _durationMinutes = availability.defaultSessionDurationMinutes;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.scheduleLesson,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            widget.topicTitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(l10n.date),
            subtitle: Text(
              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'),
            trailing: TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                  _checkConflicts(_buildScheduledTime());
                }
              },
              child: Text(l10n.change),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: Text(l10n.time),
            subtitle: Text(_selectedTime.format(context)),
            trailing: TextButton(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (picked != null) {
                  setState(() => _selectedTime = picked);
                  _checkConflicts(_buildScheduledTime());
                }
              },
              child: Text(l10n.change),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: Text(l10n.duration),
            subtitle: Text(l10n.minutesValue(_durationMinutes)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _durationMinutes > 15
                      ? () {
                          setState(() => _durationMinutes -= 15);
                          _checkConflicts(_buildScheduledTime());
                        }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _durationMinutes < 120
                      ? () {
                          setState(() => _durationMinutes += 15);
                          _checkConflicts(_buildScheduledTime());
                        }
                      : null,
                ),
              ],
            ),
          ),
          if (_hasConflict)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 18, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.timeConflict,
                        style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isScheduling || _isCheckingConflict ? null : _schedule,
              icon: _isScheduling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isScheduling ? l10n.scheduling : l10n.scheduleLesson),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  DateTime _buildScheduledTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _checkConflicts(DateTime time) async {
    final service = widget.plannerService;
    if (service == null) return;
    setState(() => _isCheckingConflict = true);
    try {
      final conflict = await service.hasSchedulingConflict(
        startTime: time,
        durationMinutes: _durationMinutes,
      );
      if (mounted) {
        setState(() => _hasConflict = conflict);
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isCheckingConflict = false);
      }
    }
  }

  Future<void> _schedule() async {
    setState(() => _isScheduling = true);
    try {
      final scheduledTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      if (_hasConflict) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.timeConflict)),
          );
        }
        setState(() => _isScheduling = false);
        return;
      }
      await widget.onSchedule(scheduledTime, _durationMinutes);
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isScheduling = false);
      }
    }
  }
}
