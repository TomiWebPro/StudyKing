import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

class TopicDependencyRepository {
  static final Logger _logger = const Logger('TopicDependencyRepository');
  late Box<TopicDependency> _box;

  Future<void> init() async {
    _box = await Hive.openBox<TopicDependency>(HiveBoxNames.topicDependencies);
  }

  void attachBox(Box<TopicDependency> box) {
    _box = box;
  }

  Future<Result<TopicDependency>> getTopicDependency(String topicId) async {
    try {
      final dep = _box.get(topicId);
      if (dep != null) {
        return Result.success(dep);
      }
      final newDep = TopicDependency(topicId: topicId);
      await _box.put(topicId, newDep);
      return Result.success(newDep);
    } catch (e) {
      _logger.w('Error getting topic dependency', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> updateTopicDependency(
      TopicDependency dependency) async {
    try {
      await _box.put(dependency.topicId, dependency);
      return Result.success(null);
    } catch (e) {
      _logger.w('Error updating topic dependency', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<TopicDependency>>> getAllDependencies() async {
    try {
      return Result.success(_box.values.toList());
    } catch (e) {
      _logger.w('Error getting all dependencies', e);
      return Result.failure(e.toString());
    }
  }
}
