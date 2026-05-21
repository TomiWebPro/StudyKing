import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';

class RoadmapRepository extends Repository<RoadmapModel> {
  Future<Result<void>> init() async {
    return Result.capture(
      () async => openBox(HiveBoxNames.roadmaps),
      context: 'RoadmapRepository.init',
    );
  }

  Future<Result<void>> create(RoadmapModel roadmap) async {
    return super.put(roadmap.id, roadmap);
  }

  Future<Result<void>> saveRoadmap(RoadmapModel roadmap) async {
    return create(roadmap);
  }

  Future<Result<RoadmapModel?>> loadRoadmap(String id) async {
    return super.get(id);
  }

  Future<Result<List<RoadmapModel>>> getRoadmapsByStudent(
      String studentId) async {
    return Result.capture(() async {
      final byStudent = filterBy((r) => r.studentId, studentId)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return byStudent;
    }, context: 'getRoadmapsByStudent');
  }

  Future<Result<List<RoadmapModel>>> getAllRoadmaps() async {
    return super.getAll();
  }

  Future<Result<void>> deleteRoadmap(String id) async {
    return super.delete(id);
  }

  Future<Result<bool>> hasRoadmap(String id) async {
    return Result.capture(
      () async => box.containsKey(id),
      context: 'hasRoadmap',
    );
  }
}
