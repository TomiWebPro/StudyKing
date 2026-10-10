import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/flashcards/data/models/study_guide_model.dart';

class StudyGuideRepository extends Repository<StudyGuide> {
  static final Logger _logger = const Logger('StudyGuideRepository');

  StudyGuideRepository() : super(boxName: HiveBoxNames.studyGuides);

  Future<Result<void>> init() async {
    try {
      await openBox(HiveBoxNames.studyGuides);
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to initialize study guides box', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> create(StudyGuide guide) async {
    return super.put(guide.id, guide);
  }

  Future<Result<List<StudyGuide>>> getBySource(String sourceId) async {
    return Result.captureSync(
      () => filterBy((g) => g.sourceId, sourceId),
      context: 'getBySource',
    );
  }

  Future<Result<List<StudyGuide>>> getByTopic(String topicId) async {
    return Result.captureSync(
      () => filterBy((g) => g.topicId, topicId),
      context: 'getByTopic',
    );
  }
}
