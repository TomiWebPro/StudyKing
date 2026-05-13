import 'package:dio/dio.dart';

enum DynamicQuestionType {
  multipleChoice,
  input,
  graph,
  calculation,
  trueFalse,
  match,
}

class DynamicTypeFetcher {
  final Dio dio;

  DynamicTypeFetcher({Dio? dio}) : dio = dio ?? Dio();

  Future<void> fetchQuestionTypes() async {
    // stub - no-op
  }

  List<String> getQuestionTypeIds() => [];

  String? getQuestionTypeInfo(String type) => null;

  Future<void> fetchMcqOptions() async {
    // stub - no-op
  }

  int getMcqOptionsForType(String type) => 5;

  int getMinMcqOptions() => 2;

  int getMaxMcqOptions() => 10;
}
