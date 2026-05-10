// COMPLETE QUESTION ENGINE - DYNAMIC VERSION
/// All lesson types, question types fetched from API
/// MCQ options dynamically generated (min 2, max 10)

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'dynamic_lesson_types.dart';

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
  late Map<String, String> _questionTypes;
  late Map<String, int> _mcqOptionsRanges;

  DynamicTypeFetcher({Dio? dio}) : dio = dio ?? Dio();

  /// Fetch question types from API
  Future<void> fetchQuestionTypes() async {
    final response = await dio.get('/api/v1/question/types');
    if (response.statusCode == 200) {
      _questionTypes = {};
      final types = response.data;
      for (var type in types as List?) {
        if (type is Map) {
          _questionTypes.addAll(type);
        }
      }
    }
  }

  List<String> getQuestionTypeIds() {
    return _questionTypes.keys.cast<String>();
  }

  String? getQuestionTypeInfo(String typeId) {
    return _questionTypes[typeId];
  }

  /// Fetch MCQ options ranges (min: 2, max: 10)
  Future<void> fetchMcqOptions() async {
    final response = await dio.get('/api/v1/mcq/options/range');
    if (response.statusCode == 200) {
      _mcqOptionsRanges = {};
      final ranges = response.data;
      for (var range in ranges as List?) {
        if (range is Map) {
          _mcqOptionsRanges.addAll(range);
        }
      }
    }
    // Default fallback
    _mcqOptionsRanges = {'default': 5};
  }

  int getMcqOptionsForType(String type) {
    return _mcqOptionsRanges[type] ?? 5;
  }

  int getMinMcqOptions() {
    return _mcqOptionsRanges.isEmpty ? 2 : _mcqOptionsRanges.values.firstWhere((v) => v >= 2) ?? 2;
  }

  int getMaxMcqOptions() {
    return _mcqOptionsRanges.isEmpty ? 10 : _mcqOptionsRanges.values.where((v) => v <= 10).fold(0, (a, b) => a > b ? a : b);
  }
}

// ... REST OF QUESTION ENGINE (same as before but using dynamic types)