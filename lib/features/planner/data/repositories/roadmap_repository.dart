import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';

class RoadmapRepository extends Repository<RoadmapModel> {
  Future<void> init() async {
    await openBox(HiveBoxNames.roadmaps);
  }

  Future<void> create(RoadmapModel roadmap) async {
    await super.save(roadmap.id, roadmap);
  }

  Future<void> saveRoadmap(RoadmapModel roadmap) async {
    await create(roadmap);
  }

  Future<RoadmapModel?> loadRoadmap(String id) async {
    final result = await super.get(id);
    return result.data;
  }

  Future<List<RoadmapModel>> getRoadmapsByStudent(String studentId) async {
    final byStudent = filterBy((r) => r.studentId, studentId)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return byStudent;
  }

  Future<List<RoadmapModel>> getAllRoadmaps() async {
    final result = await super.getAll();
    return result.data ?? [];
  }

  Future<void> deleteRoadmap(String id) async {
    await super.delete(id);
  }

  Future<bool> hasRoadmap(String id) async {
    return box.containsKey(id);
  }
}
