import 'dart:convert';
import 'package:dio/dio.dart';

/// API-driven lesson/generator types
/// All types fetched from OpenRouter API - NO hardcoded values
class DynamicLessonTypes {
  late Map<String, String> _lessonTypesMap;
  final Dio dio = Dio();

  /// Fetch from OpenRouter
  Future<void> fetchLessonTypes() async {
    try {
      // Get available models/types from API
      final response = await dio.get('/models/platform/database.json');
      if (response.statusCode == 200 && response.data is Map) {
        _lessonTypesMap = {};
        // Parse all available lesson types
        final data = response.data as Map;
        for (var type in data['types'] as List?) {
          if (type is Map) {
            _lessonTypesMap.addAll(type);
          }
        }
      }
    } catch (e) {
      print('Error fetching lesson types: $e');
      _lessonTypesMap = {};
    }
  }

  /// Get lesson types from database
  List<String> getLessonTypes() {
    return _lessonTypesMap.keys.cast<String>();
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
      return LessonType.fromJson(response.data);
    } catch (e) {
      throw LessonTypeError('Failed to fetch lesson type: $e');
    }
  }

  /// Add new lesson type
  Future<void> addLessonType(String typeId, String name) async {
    await dio.post(
      '/api/v1/lesson/types',
      data: {'typeId': typeId, 'name': name},
    );
  }

  /// Remove lesson type
  Future<void> removeLessonType(String typeId) async {
    await dio.delete(
      '/api/v1/lesson/types/$typeId',
    );
  }
}

/// Storage lesson types in database
class DBLessonTypes {
  static final Map<String, String> _store = {};
  late final Map<String, String> _dbStore;

  DBLessonTypes() {
    _dbStore = _store;
  }

  List<String> getAllLessonTypes() {
    return _dbStore.keys.cast<String>();
  }

  List<LessonType> getAllLessonTypesWithMeta() {
    return _dbStore.entries.map((e) => LessonType(
      id: e.key,
      name: e.value,
    )).toList();
  }

  Map<String, String> getStore() {
    return _dbStore;
  }

  void setLessonType(String id, String name) {
    _dbStore[id] = name;
    _store[id] = name;
  }

  void clearStore() {
    _dbStore.clear();
    _store.clear();
  }

  void removeFromStore(String id) {
    _dbStore.remove(id);
    _store.remove(id);
  }
}

/// Lesson type model
class LessonType {
  final String id;
  final String name;
  // More fields will be added dynamically from API
  String? description;
  Map<String, dynamic>? config;
  DateTime? createdAt;

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
      config: json['config'] as Map?,
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
}
