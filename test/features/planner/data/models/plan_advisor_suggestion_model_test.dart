import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/models/plan_advisor_suggestion_model.dart';

PlanAdvisorSuggestionModel createSuggestion({
  String id = 'suggestion-1',
  String studentId = 'student-1',
  String suggestionType = 'plan_generation',
  String? workloadEstimate,
  String? pathwaySuggestion,
  String? motivationalReasoning,
  Map<String, dynamic> metadata = const {},
  bool applied = false,
}) {
  return PlanAdvisorSuggestionModel(
    id: id,
    studentId: studentId,
    generatedAt: DateTime(2026, 5, 20),
    suggestionType: suggestionType,
    workloadEstimate: workloadEstimate,
    pathwaySuggestion: pathwaySuggestion,
    motivationalReasoning: motivationalReasoning,
    metadata: metadata,
    applied: applied,
  );
}

void main() {
  group('PlanAdvisorSuggestionModel', () {
    group('construction', () {
      test('creates with default values', () {
        final suggestion = createSuggestion();
        expect(suggestion.id, 'suggestion-1');
        expect(suggestion.studentId, 'student-1');
        expect(suggestion.suggestionType, 'plan_generation');
        expect(suggestion.workloadEstimate, isNull);
        expect(suggestion.pathwaySuggestion, isNull);
        expect(suggestion.motivationalReasoning, isNull);
        expect(suggestion.metadata, isEmpty);
        expect(suggestion.applied, false);
        expect(suggestion.generatedAt, DateTime(2026, 5, 20));
      });

      test('creates with all fields', () {
        final suggestion = PlanAdvisorSuggestionModel(
          id: 'adv-1',
          studentId: 's1',
          generatedAt: DateTime(2026, 6, 1),
          suggestionType: 'adaptation',
          workloadEstimate: '~5 hours/week',
          pathwaySuggestion: 'Focus on Algebra before Geometry',
          motivationalReasoning: 'You are making steady progress',
          metadata: {'source': 'llm'},
          applied: true,
        );
        expect(suggestion.id, 'adv-1');
        expect(suggestion.suggestionType, 'adaptation');
        expect(suggestion.workloadEstimate, '~5 hours/week');
        expect(suggestion.metadata['source'], 'llm');
        expect(suggestion.applied, true);
      });
    });

    group('toJson / fromJson', () {
      test('round-trips correctly', () {
        final original = createSuggestion(
          workloadEstimate: '~3h/day',
          pathwaySuggestion: 'Path A',
          motivationalReasoning: 'Keep going!',
          metadata: {'key': 'value'},
        );
        final json = original.toJson();
        final restored = PlanAdvisorSuggestionModel.fromJson(json);
        expect(restored.id, original.id);
        expect(restored.studentId, original.studentId);
        expect(restored.workloadEstimate, original.workloadEstimate);
        expect(restored.pathwaySuggestion, original.pathwaySuggestion);
        expect(restored.motivationalReasoning, original.motivationalReasoning);
        expect(restored.metadata['key'], 'value');
        expect(restored.applied, original.applied);
      });

      test('handles null optional fields', () {
        final json = {
          'id': 'test-id',
          'studentId': 'test-student',
          'generatedAt': '2026-05-20T00:00:00.000',
          'suggestionType': 'plan_generation',
          'applied': false,
        };
        final restored = PlanAdvisorSuggestionModel.fromJson(json);
        expect(restored.workloadEstimate, isNull);
        expect(restored.pathwaySuggestion, isNull);
        expect(restored.motivationalReasoning, isNull);
        expect(restored.metadata, isEmpty);
      });
    });

    group('copyWith', () {
      test('creates a copy with updated fields', () {
        final original = createSuggestion();
        final copied = original.copyWith(
          applied: true,
          workloadEstimate: '~4h/week',
        );
        expect(copied.id, original.id);
        expect(copied.applied, true);
        expect(copied.workloadEstimate, '~4h/week');
        expect(original.applied, false);
      });

      test('copyWith preserves unchanged fields', () {
        final original = createSuggestion(
          workloadEstimate: 'original',
          pathwaySuggestion: 'path',
        );
        final copied = original.copyWith(workloadEstimate: 'updated');
        expect(copied.pathwaySuggestion, 'path');
        expect(copied.workloadEstimate, 'updated');
      });
    });
  });
}
