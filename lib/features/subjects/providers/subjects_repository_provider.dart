// Repository Provider for subjects
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';

final _logger = const Logger('SubjectsRepositoryNotifier');

final subjectsRepositoryProvider = AsyncNotifierProvider<SubjectsRepositoryNotifier, SubjectRepository>(
  () => SubjectsRepositoryNotifier(),
);

class SubjectsRepositoryNotifier extends AsyncNotifier<SubjectRepository> {
  @override
  Future<SubjectRepository> build() async {
    try {
      final repository = SubjectRepository();
      await repository.init();
      return repository;
    } catch (e, st) {
      _logger.w('Failed to init SubjectRepository', e, st);
      rethrow;
    }
  }
}
