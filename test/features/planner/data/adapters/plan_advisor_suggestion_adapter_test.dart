import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:studyking/features/planner/data/adapters/plan_advisor_suggestion_adapter.dart';
import 'package:studyking/features/planner/data/models/plan_advisor_suggestion_model.dart';

void main() {
  group('PlanAdvisorSuggestionAdapter', () {
    test('typeId is 37', () {
      expect(PlanAdvisorSuggestionAdapter().typeId, 37);
    });

    test('write/read round-trips all 9 fields', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(PlanAdvisorSuggestionAdapter());
      final adapter = PlanAdvisorSuggestionAdapter();
      final now = DateTime(2025, 6, 15, 10, 30);
      final source = PlanAdvisorSuggestionModel(
        id: 'suggestion-001',
        studentId: 'student-1',
        generatedAt: now,
        suggestionType: 'plan_generation',
        workloadEstimate: '~2h/day for 30 days',
        pathwaySuggestion: 'Focus on algebra fundamentals first',
        motivationalReasoning: 'You have shown great progress in geometry',
        metadata: {'confidence': 0.85, 'model': 'gpt-4'},
        applied: true,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.id, 'suggestion-001');
      expect(restored.studentId, 'student-1');
      expect(restored.generatedAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(restored.suggestionType, 'plan_generation');
      expect(restored.workloadEstimate, '~2h/day for 30 days');
      expect(restored.pathwaySuggestion, 'Focus on algebra fundamentals first');
      expect(restored.motivationalReasoning, 'You have shown great progress in geometry');
      expect(restored.metadata['confidence'], 0.85);
      expect(restored.metadata['model'], 'gpt-4');
      expect(restored.applied, isTrue);
    });

    test('write/read with minimal fields defaults', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(PlanAdvisorSuggestionAdapter());
      final adapter = PlanAdvisorSuggestionAdapter();
      final now = DateTime(2025, 6, 15);
      final source = PlanAdvisorSuggestionModel(
        id: 'suggestion-002',
        studentId: 'student-2',
        generatedAt: now,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.id, 'suggestion-002');
      expect(restored.studentId, 'student-2');
      expect(restored.suggestionType, 'plan_generation');
      expect(restored.workloadEstimate, isNull);
      expect(restored.pathwaySuggestion, isNull);
      expect(restored.motivationalReasoning, isNull);
      expect(restored.metadata, {});
      expect(restored.applied, isFalse);
    });

    test('write/read with null fields', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(PlanAdvisorSuggestionAdapter());
      final adapter = PlanAdvisorSuggestionAdapter();
      final now = DateTime(2025, 6, 15);
      final source = PlanAdvisorSuggestionModel(
        id: 'suggestion-003',
        studentId: 'student-3',
        generatedAt: now,
        workloadEstimate: null,
        pathwaySuggestion: null,
        motivationalReasoning: null,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.workloadEstimate, isNull);
      expect(restored.pathwaySuggestion, isNull);
      expect(restored.motivationalReasoning, isNull);
      expect(restored.applied, isFalse);
    });

    test('hashCode and equality', () {
      final a1 = PlanAdvisorSuggestionAdapter();
      final a2 = PlanAdvisorSuggestionAdapter();
      expect(a1.hashCode, a2.hashCode);
      expect(a1 == a2, isTrue);
      expect(a1 == Object(), isFalse);
    });
  });
}
