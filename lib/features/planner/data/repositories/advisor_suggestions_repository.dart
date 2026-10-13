import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/planner/data/models/plan_advisor_suggestion_model.dart';

class AdvisorSuggestionsRepository extends Repository<PlanAdvisorSuggestionModel> {
  static final Logger _logger = const Logger('AdvisorSuggestionsRepository');

  AdvisorSuggestionsRepository() : super(boxName: HiveBoxNames.planAdvisorSuggestions);

  Future<Result<void>> init() async {
    return Result.capture(
      () async => openBox(HiveBoxNames.planAdvisorSuggestions),
      context: 'AdvisorSuggestionsRepository.init',
    );
  }

  Future<Result<void>> create(PlanAdvisorSuggestionModel suggestion) async {
    return super.put(suggestion.id, suggestion);
  }

  Future<Result<PlanAdvisorSuggestionModel?>> getLatestByStudent(
      String studentId) async {
    return Result.capture(() async {
      final suggestions = filterBy((s) => s.studentId, studentId)
        ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
      return suggestions.isNotEmpty ? suggestions.first : null;
    }, context: 'AdvisorSuggestionsRepository.getLatestByStudent');
  }

  Future<Result<List<PlanAdvisorSuggestionModel>>> getByStudent(
      String studentId) async {
    return Result.capture(() async {
      final suggestions = filterBy((s) => s.studentId, studentId)
        ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
      return suggestions;
    }, context: 'AdvisorSuggestionsRepository.getByStudent');
  }

  Future<Result<void>> markApplied(String id) async {
    try {
      final existing = box.get(id);
      if (existing == null) {
        return Result.success(null);
      }
      final result = await super.put(id, existing.copyWith(applied: true));
      if (result.isFailure) {
        _logger.w('Failed to mark suggestion $id as applied', result.error);
      }
      return result;
    } catch (e) {
      _logger.w('Failed to mark suggestion $id as applied', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> deleteSuggestion(String id) async {
    return super.delete(id);
  }

  Future<Result<List<PlanAdvisorSuggestionModel>>> getUnappliedByStudent(
      String studentId) async {
    return Result.capture(() async {
      return filterBy((s) => s.studentId, studentId)
          .where((s) => !s.applied)
          .toList()
        ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
    }, context: 'AdvisorSuggestionsRepository.getUnappliedByStudent');
  }
}
