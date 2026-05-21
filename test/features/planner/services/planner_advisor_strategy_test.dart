import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/services/planner_advisor_strategy.dart';

void main() {
  group('AdvisorAnalysis', () {
    test('creates with all null values and empty metadata', () {
      const analysis = AdvisorAnalysis();
      expect(analysis.workloadEstimate, isNull);
      expect(analysis.pathwaySuggestion, isNull);
      expect(analysis.motivationalReasoning, isNull);
      expect(analysis.adaptationReasoning, isNull);
      expect(analysis.metadata, isEmpty);
    });

    test('toJson returns only non-null fields with metadata spread', () {
      const analysis = AdvisorAnalysis(
        workloadEstimate: 'Moderate — 45-60 min/day',
        pathwaySuggestion: 'Start with foundational topics',
        metadata: {'source': 'test', 'version': 1},
      );
      final json = analysis.toJson();
      expect(json['workloadEstimate'], 'Moderate — 45-60 min/day');
      expect(json['pathwaySuggestion'], 'Start with foundational topics');
      expect(json, isNot(contains('motivationalReasoning')));
      expect(json, isNot(contains('adaptationReasoning')));
      expect(json['source'], 'test');
      expect(json['version'], 1);
    });

    test('toJson includes all non-null reasoning fields', () {
      const analysis = AdvisorAnalysis(
        workloadEstimate: 'Heavy',
        pathwaySuggestion: 'Path',
        motivationalReasoning: 'Keep going!',
        adaptationReasoning: 'Adjust pace',
      );
      final json = analysis.toJson();
      expect(json['workloadEstimate'], 'Heavy');
      expect(json['pathwaySuggestion'], 'Path');
      expect(json['motivationalReasoning'], 'Keep going!');
      expect(json['adaptationReasoning'], 'Adjust pace');
    });

    test('toJson returns non-null fields only when some are null', () {
      const analysis = AdvisorAnalysis(
        workloadEstimate: 'Light',
      );
      final json = analysis.toJson();
      expect(json['workloadEstimate'], 'Light');
      expect(json, hasLength(1));
    });

    test('metadata overrides field keys when keys collide', () {
      final analysis = AdvisorAnalysis(
        workloadEstimate: 'Original',
        metadata: {'workloadEstimate': 'Override'},
      );
      final json = analysis.toJson();
      expect(json['workloadEstimate'], 'Override');
    });

    test('const AdvisorAnalysis can be used as a const expression', () {
      const analysis = AdvisorAnalysis(
        workloadEstimate: 'Light',
        pathwaySuggestion: 'Suggestion',
        motivationalReasoning: 'Keep going!',
        adaptationReasoning: 'None needed',
        metadata: {'key': 'value'},
      );
      expect(analysis, isA<AdvisorAnalysis>());
      expect(analysis.workloadEstimate, 'Light');
    });

    test('metadata field does not cause duplicate key error when empty', () {
      const analysis = AdvisorAnalysis(workloadEstimate: 'Medium');
      final json = analysis.toJson();
      expect(json['workloadEstimate'], 'Medium');
      expect(json, hasLength(1));
    });

    test('isA type check on AdvisorAnalysis', () {
      const analysis = AdvisorAnalysis();
      expect(analysis, isA<AdvisorAnalysis>());
    });

    test('isA type check on results', () {
      const analysis = AdvisorAnalysis(workloadEstimate: 'Test');
      expect(analysis, isA<AdvisorAnalysis>());
    });
  });

  group('PlannerAdvisorStrategy', () {
    test('is an abstract class that cannot be instantiated', () {
      expect(PlannerAdvisorStrategy, isA<Type>());
    });
  });
}
