import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';
import '../../../../../l10n/generated/app_localizations.dart';

class SyllableEntry {
  String? selectedSubjectId;
  String? selectedSubjectTitle;
  final TextEditingController subjectController;
  final TextEditingController daysController;
  final TextEditingController hoursController;

  SyllableEntry()
      : subjectController = TextEditingController(),
        daysController = TextEditingController(),
        hoursController = TextEditingController();

  void dispose() {
    subjectController.dispose();
    daysController.dispose();
    hoursController.dispose();
  }
}

class MultiSyllabusInput extends ConsumerStatefulWidget {
  final List<SyllableEntry> entries;
  final List<Subject> allSubjects;
  final VoidCallback onAddEntry;
  final ValueChanged<int> onRemoveEntry;
  final void Function(int index, String? subjectId) onSubjectChanged;

  const MultiSyllabusInput({
    super.key,
    required this.entries,
    required this.allSubjects,
    required this.onAddEntry,
    required this.onRemoveEntry,
    required this.onSubjectChanged,
  });

  @override
  ConsumerState<MultiSyllabusInput> createState() => _MultiSyllabusInputState();
}

class _MultiSyllabusInputState extends ConsumerState<MultiSyllabusInput> {
  static final _logger = Logger('MultiSyllabusInput');

  // Cache futures per subject so the repository (and its box open) is only
  // initialized once per subject, not on every rebuild of the row.
  final Map<String, Future<int>> _topicCountCache = {};

  Future<int> _getTopicCount(String subjectId) {
    return _topicCountCache.putIfAbsent(subjectId, () async {
      try {
        final topicRepo = ref.read(topicRepositoryProvider);
        final initResult = await topicRepo.init();
        if (initResult.isFailure) {
          _logger.w(
            'Failed to get topic count: could not open topic repository',
            initResult.error,
          );
          return 0;
        }
        final result = await topicRepo.getBySubject(subjectId);
        if (result.isFailure) {
          _logger.w(
            'Failed to get topic count for subject $subjectId',
            result.error,
          );
          return 0;
        }
        return result.data?.length ?? 0;
      } catch (e) {
        _logger.w('Failed to get topic count', e);
        return 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...widget.entries.asMap().entries.map((entry) {
          final index = entry.key;
          final e = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: e.selectedSubjectId,
                          decoration: InputDecoration(
                            labelText: '${l10n.courseSubject} ${index + 1}',
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          hint: Text(l10n.courseHint),
                          isExpanded: true,
                          items: [
                            ...widget.allSubjects.map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name, overflow: TextOverflow.ellipsis),
                            )),
                          ],
                          onChanged: (v) => widget.onSubjectChanged(index, v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: Theme.of(context).colorScheme.error),
                        tooltip: l10n.delete,
                        onPressed: widget.entries.length > 1
                            ? () => widget.onRemoveEntry(index)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: e.daysController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.days,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: e.hoursController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.hoursPerDay,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (e.selectedSubjectId != null) ...[
                    const SizedBox(height: 4),
                    FutureBuilder<int>(
                      future: _getTopicCount(e.selectedSubjectId!),
                      builder: (ctx, snap) {
                        final count = snap.data ?? 0;
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(start: 4),
                          child: Text(
                            l10n.topicCountTemplate(count),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: Text(l10n.addCourseSubject),
          onPressed: widget.onAddEntry,
        ),
      ],
    );
  }
}
