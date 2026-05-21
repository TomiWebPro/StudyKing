import 'package:flutter/material.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/data/models/subject_model.dart';
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

class MultiSyllabusInput extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...entries.asMap().entries.map((entry) {
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
                            ...allSubjects.map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name, overflow: TextOverflow.ellipsis),
                            )),
                          ],
                          onChanged: (v) => onSubjectChanged(index, v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: Theme.of(context).colorScheme.error),
                        tooltip: l10n.delete,
                        onPressed: entries.length > 1
                            ? () => onRemoveEntry(index)
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
          onPressed: onAddEntry,
        ),
      ],
    );
  }

  Future<int> _getTopicCount(String subjectId) async {
    try {
      final topicRepo = TopicRepository();
      await topicRepo.init();
      final result = await topicRepo.getBySubject(subjectId);
      return result.data?.length ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
