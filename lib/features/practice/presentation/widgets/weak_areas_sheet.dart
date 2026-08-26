import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/providers/service_providers.dart';
import 'package:studyking/core/theme/app_theme.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/practice/presentation/widgets/subject_selection_sheet.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

/// Loads the weak topics for the given student from [MasteryGraphService].
///
/// Returns an empty list when the underlying call fails so the sheet can fall
/// back to its empty state instead of crashing.
final _weakTopicsProvider =
    FutureProvider.autoDispose.family<List<MasteryState>, String>(
  (ref, studentId) async {
    final service = ref.watch(masteryGraphServiceProvider);
    await service.init();
    final result = await service.getWeakTopics(studentId);
    if (result.isFailure) return <MasteryState>[];
    return result.data ?? <MasteryState>[];
  },
);

/// Presents only the subjects that actually contain weak topics, each annotated
/// with a weak-topic count badge, so the student is guided to where they need
/// review most. Falls back to the [AppLocalizations.noWeakAreasFound] empty
/// state when no weak topics exist.
class WeakAreasSheet extends ConsumerWidget {
  final List<Subject> subjects;
  final void Function(Subject) onSubjectSelected;

  const WeakAreasSheet({
    super.key,
    required this.subjects,
    required this.onSubjectSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final studentId = ref.read(studentIdServiceProvider).getStudentId().data ?? '';
    final weakTopicsAsync = ref.watch(_weakTopicsProvider(studentId));

    return weakTopicsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildEmptyState(context, l10n),
      data: (weakTopics) => _buildContent(context, l10n, weakTopics),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    List<MasteryState> weakTopics,
  ) {
    final weakBySubject = <String, int>{};
    for (final topic in weakTopics) {
      for (final subject in subjects) {
        if (subject.topicIds.contains(topic.topicId)) {
          weakBySubject[subject.id] = (weakBySubject[subject.id] ?? 0) + 1;
        }
      }
    }

    final weakSubjects = subjects
        .where((subject) => weakBySubject.containsKey(subject.id))
        .toList();

    if (weakSubjects.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return SubjectSelectionSheet(
      subjects: weakSubjects,
      onSubjectSelected: onSubjectSelected,
      subtitleBuilder: (subject) =>
          l10n.weakTopicsCount(weakBySubject[subject.id]!),
      trailingBuilder: (subject) => _WeakTopicBadge(
        label: l10n.weakTopicsCount(weakBySubject[subject.id]!),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noWeakAreasFound,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> show(BuildContext context, {
    required List<Subject> subjects,
    required void Function(Subject) onSubjectSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: AppTheme.bottomSheetShape,
      builder: (_) => WeakAreasSheet(
        subjects: subjects,
        onSubjectSelected: onSubjectSelected,
      ),
    );
  }
}

class _WeakTopicBadge extends StatelessWidget {
  final String label;

  const _WeakTopicBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      label: Text(label),
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onPrimaryContainer,
      ),
      backgroundColor: theme.colorScheme.primaryContainer,
      padding: EdgeInsets.zero,
    );
  }
}
