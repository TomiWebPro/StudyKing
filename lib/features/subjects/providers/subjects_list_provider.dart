import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';

final _subjectListLogger = const Logger('SubjectListProvider');

final subjectListProvider = FutureProvider<List<Subject>>((ref) async {
  try {
    final repo = await ref.watch(subjectsRepositoryProvider.future);
    final result = await repo.getAll();
    return result.data ?? [];
  } catch (e, st) {
    _subjectListLogger.w('Failed to load subject list', e, st);
    return [];
  }
});

final subjectSessionCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final subjects = await ref.watch(subjectListProvider.future);
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final counts = <String, int>{};
  for (final subject in subjects) {
    final sessionResult = await sessionRepo.getBySubject(subject.id);
    counts[subject.id] = (sessionResult.data ?? []).length;
  }
  return counts;
});
