import 'package:flutter/material.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/features/practice/presentation/widgets/subject_selection_sheet.dart';

/// Thin wrapper around [SubjectSelectionSheet] for weak areas subject selection.
/// Exists for API compatibility — delegates entirely to [SubjectSelectionSheet].
class WeakAreasSheet extends StatelessWidget {
  final List<Subject> subjects;
  final void Function(Subject) onSubjectSelected;

  const WeakAreasSheet({
    super.key,
    required this.subjects,
    required this.onSubjectSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SubjectSelectionSheet(
      subjects: subjects,
      onSubjectSelected: onSubjectSelected,
    );
  }

  static Future<void> show(BuildContext context, {
    required List<Subject> subjects,
    required void Function(Subject) onSubjectSelected,
  }) {
    return SubjectSelectionSheet.show(
      context,
      subjects: subjects,
      onSubjectSelected: onSubjectSelected,
    );
  }
}
