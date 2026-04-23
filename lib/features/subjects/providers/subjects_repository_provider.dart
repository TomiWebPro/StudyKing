// Repository Provider for subjects
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/subject_repository.dart';

final subjectsRepositoryProvider = AsyncNotifierProvider<SubjectsRepositoryNotifier, SubjectRepository>(
  () => SubjectsRepositoryNotifier(),
);

class SubjectsRepositoryNotifier extends AsyncNotifier<SubjectRepository> {
  @override
  Future<SubjectRepository> build() async {
    final repository = SubjectRepository();
    await repository.init();
    return repository;
  }
}
