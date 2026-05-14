import 'package:flutter/material.dart';

class LessonBookingSheet extends StatefulWidget {
  final String topicId;
  final String topicTitle;
  final String subjectId;
  final Future<void> Function(DateTime scheduledTime, int durationMinutes)
      onSchedule;

  const LessonBookingSheet({
    super.key,
    required this.topicId,
    required this.topicTitle,
    required this.subjectId,
    required this.onSchedule,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            'Schedule Lesson',
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
            title: const Text('Date'),
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
                }
              },
              child: const Text('Change'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Time'),
            subtitle: Text(_selectedTime.format(context)),
            trailing: TextButton(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (picked != null) {
                  setState(() => _selectedTime = picked);
                }
              },
              child: const Text('Change'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Duration'),
            subtitle: Text('$_durationMinutes minutes'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _durationMinutes > 15
                      ? () => setState(() => _durationMinutes -= 15)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _durationMinutes < 120
                      ? () => setState(() => _durationMinutes += 15)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isScheduling ? null : _schedule,
              icon: _isScheduling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isScheduling ? 'Scheduling...' : 'Schedule Lesson'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
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
