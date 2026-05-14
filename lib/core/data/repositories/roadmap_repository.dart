import 'package:hive_flutter/hive_flutter.dart';
import '../models/roadmap_model.dart';

class RoadmapRepository {
  late Box<RoadmapModel> _box;

  Future<void> init() async {
    _box = await Hive.openBox<RoadmapModel>('roadmaps');
  }

  Future<void> saveRoadmap(RoadmapModel roadmap) async {
    await _box.put(roadmap.id, roadmap);
  }

  Future<RoadmapModel?> loadRoadmap(String id) async {
    return _box.get(id);
  }

  Future<List<RoadmapModel>> getRoadmapsByStudent(String studentId) async {
    return _box.values
        .where((r) => r.studentId == studentId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<RoadmapModel>> getAllRoadmaps() async {
    return _box.values.toList();
  }

  Future<void> deleteRoadmap(String id) async {
    await _box.delete(id);
  }

  Future<bool> hasRoadmap(String id) async {
    return _box.containsKey(id);
  }
}
