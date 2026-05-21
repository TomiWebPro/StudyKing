import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';

final subjectRepositoryProvider = Provider<SubjectRepository>((ref) {
  return SubjectRepository();
});
