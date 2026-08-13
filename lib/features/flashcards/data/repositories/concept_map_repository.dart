import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/flashcards/data/models/concept_map_model.dart';

class ConceptMapRepository extends Repository<ConceptMap> {
  ConceptMapRepository() : super(boxName: HiveBoxNames.conceptMaps);

  Future<Result<void>> init() async {
    try {
      await openBox(HiveBoxNames.conceptMaps);
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> create(ConceptMap map) async {
    return super.put(map.id, map);
  }

  Future<Result<List<ConceptMap>>> getBySource(String sourceId) async {
    return Result.captureSync(
      () => filterBy((m) => m.sourceId, sourceId),
      context: 'getBySource',
    );
  }

  Future<Result<List<ConceptMap>>> getByTopic(String topicId) async {
    return Result.captureSync(
      () => filterBy((m) => m.topicId, topicId),
      context: 'getByTopic',
    );
  }
}
