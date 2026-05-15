import 'package:hive_flutter/hive_flutter.dart';
import 'adapters/markscheme_adapter.dart';
import 'adapters/question_evaluation_adapter.dart';

void registerQuestionAdapters() {
  if (!Hive.isAdapterRegistered(12)) {
    Hive.registerAdapter(MarkschemeAdapter());
    Hive.registerAdapter(MarkSchemeStepAdapter());
  }
  if (!Hive.isAdapterRegistered(14)) {
    Hive.registerAdapter(QuestionEvaluationAdapter());
    Hive.registerAdapter(EvaluationStepAdapter());
  }
}
