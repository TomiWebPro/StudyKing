import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository();
});

final sourceRepositoryProvider = Provider<SourceRepository>((ref) {
  return SourceRepository();
});
