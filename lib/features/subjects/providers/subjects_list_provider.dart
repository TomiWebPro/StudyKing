import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';

final subjectListProvider = FutureProvider<List<Subject>>((ref) async {
  final repo = await ref.watch(subjectsRepositoryProvider.future);
  final result = await repo.getAll();
  return result.data ?? [];
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
