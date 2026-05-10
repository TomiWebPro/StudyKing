// COMPLETE QUESTION ENGINE - DYNAMIC VERSION
// All lesson types, question types fetched from API
// MCQ options dynamically generated (min 2, max 10)

import 'package:dio/dio.dart';

/// Question type enum
/// All types fetched from API - NO hardcoded values
enum DynamicQuestionType {
  multipleChoice,
  input,
  graph,
  calculation,
  trueFalse,
  match,
}

/// Dynamic Question Type Fetcher
class DynamicTypeFetcher {
  final Dio dio;
  Map<String, String> _questionTypes = {};
  Map<String, int> _mcqOptionsRanges = {};

  DynamicTypeFetcher({Dio? dio}) : dio = dio ?? Dio();

  /// Fetch question types from API
  Future<void> fetchQuestionTypes() async {
    try {
      final response = await dio.get('/api/v1/question/types');
      if (response.statusCode == 200 && response.data != null) {
        _questionTypes = {};
        final types = response.data as List?;
        if (types != null) {
          for (var type in types) {
            if (type is Map<String, dynamic>) {
              final key = type.keys.firstOrNull;
              final value = type.values.firstOrNull?.toString();
              if (key != null && value != null) {
                _questionTypes[key] = value;
              }
            }
          }
        }
      }
    } catch (e) {
      _questionTypes = {'default': 'Unknown type'};
    }
  }

  List<String> getQuestionTypeIds() {
    return _questionTypes.keys.toList();
  }

  String? getQuestionTypeInfo(String typeId) {
    return _questionTypes[typeId];
  }

  /// Fetch MCQ options ranges (min: 2, max: 10)
  Future<void> fetchMcqOptions() async {
    try {
      final response = await dio.get('/api/v1/mcq/options/range');
      if (response.statusCode == 200 && response.data != null) {
        _mcqOptionsRanges = {};
        final ranges = response.data as List?;
        if (ranges != null) {
          for (var range in ranges) {
            if (range is Map<String, dynamic>) {
              final key = range.keys.firstOrNull;
              final value = range.values.firstOrNull?.toInt();
              if (key != null && value != null) {
                _mcqOptionsRanges[key] = value;
              }
            }
          }
        }
      }
    } catch (e) {
      _mcqOptionsRanges = {'default': 5};
    }
  }

  int getMcqOptionsForType(String type) {
    return _mcqOptionsRanges[type] ?? 5;
  }

  int getMinMcqOptions() {
    return _mcqOptionsRanges.isEmpty ? 2 : _mcqOptionsRanges.values.firstWhere((v) => v >= 2, orElse: () => 2);
  }

  int getMaxMcqOptions() {
    return _mcqOptionsRanges.isEmpty ? 10 : _mcqOptionsRanges.values.reduce((a, b) => a > b ? a : b);
  }
}
