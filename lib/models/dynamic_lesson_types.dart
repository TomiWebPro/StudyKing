import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// API-driven lesson/generator types
/// All types fetched from OpenRouter API - NO hardcoded values
class DynamicLessonTypes {
  Map<String, String> _lessonTypesMap = {};
  final Dio dio;

  DynamicLessonTypes({Dio? dio}) : dio = dio ?? Dio();

  /// Fetch from OpenRouter
  Future<void> fetchLessonTypes() async {
    try {
      // Get available models/types from API
      final response = await dio.get('/models/platform/database.json');
      if (response.statusCode == 200 && response.data is Map) {
        _lessonTypesMap = {};
        // Parse all available lesson types
        final data = response.data as Map;
        final types = data['types'] as List?;
        if (types != null) {
          for (var type in types) {
            if (type is Map) {
              _lessonTypesMap.addAll(type.cast<String, String>());
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching lesson types: $e');
      _lessonTypesMap = {};
    }
  }

  /// Get lesson types from database
  List<String> getLessonTypes() {
    return _lessonTypesMap.keys.cast<String>().toList();
  }

  /// Get lesson type by ID
  String? getLessonTypeById(String typeId) {
    return _lessonTypesMap[typeId];
  }

  /// Check if type exists
  bool containsLessonType(String typeId) {
    return _lessonTypesMap.containsKey(typeId);
  }

  /// Fetch lesson type with validation
  Future<LessonType> fetchLessonType(String typeId) async {
    try {
      final response = await dio.get(
        '/api/v1/lesson/types',
        queryParameters: {'typeId': typeId},
      );
      return LessonType.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw LessonTypeError('Failed to fetch lesson type: $e');
    }
  }

  /// Add new lesson type
  Future<void> addLessonType(String typeId, String name) async {
    try {
      await dio.post(
        '/api/v1/lesson/types',
        data: {'typeId': typeId, 'name': name},
      );
    } catch (e) {
      debugPrint('Error adding lesson type: $e');
    }
  }

  /// Remove lesson type
  Future<void> removeLessonType(String typeId) async {
    try {
      await dio.delete(
        '/api/v1/lesson/types/$typeId',
      );
    } catch (e) {
      debugPrint('Error removing lesson type: $e');
    }
  }
}

/// Storage lesson types in database
class DBLessonTypes {
  final Map<String, String> _dbStore = {};

  List<String> getAllLessonTypes() {
    return _dbStore.keys.cast<String>().toList();
  }

  List<LessonType> getAllLessonTypesWithMeta() {
    return _dbStore.entries.map((e) => LessonType(
      id: e.key,
      name: e.value,
    )).toList();
  }

  Map<String, String> getStore() {
    return Map.unmodifiable(_dbStore);
  }

  void setLessonType(String id, String name) {
    _dbStore[id] = name;
  }

  void clearStore() {
    _dbStore.clear();
  }

  void removeFromStore(String id) {
    _dbStore.remove(id);
  }
}

/// Lesson type model
class LessonType {
  final String id;
  final String name;
  final String? description;
  final Map<String, dynamic>? config;
  final DateTime? createdAt;

  LessonType({
    required this.id,
    required this.name,
    this.description,
    this.config,
    this.createdAt,
  });

  factory LessonType.fromJson(Map<String, dynamic> json) {
    return LessonType(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      config: (json['config'] as Map?)?.cast<String, dynamic>(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'config': config,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  LessonType copyWith({
    String? id,
    String? name,
    String? description,
    Map<String, dynamic>? config,
    DateTime? createdAt,
  }) {
    return LessonType(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      config: config ?? this.config,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Error thrown when lesson type operations fail
class LessonTypeError implements Exception {
  final String message;
  LessonTypeError(this.message);
  @override String toString() => message;
}
