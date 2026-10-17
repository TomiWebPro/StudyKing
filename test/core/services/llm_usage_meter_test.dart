import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/services/llm/model_router.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';

void main() {
  group('LlmUsageRecord', () {
    test('creates record with all fields', () {
      final now = DateTime.now();
      final record = LlmUsageRecord(
        id: 'rec1',
        feature: 'chat',
        modelId: 'gpt-4',
        inputTokens: 100,
        outputTokens: 50,
        cost: 0.001,
        timestamp: now,
        success: true,
      );
      expect(record.id, equals('rec1'));
      expect(record.feature, equals('chat'));
      expect(record.modelId, equals('gpt-4'));
      expect(record.inputTokens, equals(100));
      expect(record.outputTokens, equals(50));
      expect(record.cost, equals(0.001));
      expect(record.timestamp, equals(now));
      expect(record.success, isTrue);
    });

    test('default success is true', () {
      final record = LlmUsageRecord(
        id: 'r1',
        feature: 'test',
        modelId: 'm1',
        inputTokens: 0,
        outputTokens: 0,
        cost: 0,
        timestamp: DateTime.now(),
      );
      expect(record.success, isTrue);
    });

    test('totalTokens sums input and output', () {
      final record = LlmUsageRecord(
        id: 'r1',
        feature: 'test',
        modelId: 'm1',
        inputTokens: 200,
        outputTokens: 80,
        cost: 0.0,
        timestamp: DateTime.now(),
      );
      expect(record.totalTokens, equals(280));
    });

    test('toJson/fromJson round-trip preserves all fields', () {
      final now = DateTime(2026, 5, 19);
      final original = LlmUsageRecord(
        id: 'rt-1',
        feature: 'chat',
        modelId: 'gpt-4',
        inputTokens: 150,
        outputTokens: 75,
        cost: 0.002,
        timestamp: now,
        success: true,
      );
      final json = original.toJson();
      final restored = LlmUsageRecord.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.feature, original.feature);
      expect(restored.modelId, original.modelId);
      expect(restored.inputTokens, original.inputTokens);
      expect(restored.outputTokens, original.outputTokens);
      expect(restored.cost, original.cost);
      expect(restored.timestamp, original.timestamp);
      expect(restored.success, original.success);
    });

    test('toJson/fromJson round-trip with success=false', () {
      final original = LlmUsageRecord(
        id: 'rt-2',
        feature: 'embedding',
        modelId: 'ada',
        inputTokens: 0,
        outputTokens: 0,
        cost: 0.0,
        timestamp: DateTime(2026, 1, 1),
        success: false,
      );
      final json = original.toJson();
      final restored = LlmUsageRecord.fromJson(json);
      expect(restored.success, isFalse);
      expect(restored.cost, 0.0);
    });
  });

  group('LlmUsageMeter', () {
    late LlmUsageMeter meter;

    setUp(() async {
      await Hive.openBox(HiveBoxNames.llmUsageRecords);
      await Hive.box(HiveBoxNames.llmUsageRecords).clear();
      meter = LlmUsageMeter();
      await meter.init();
    });

    test('starts empty', () {
      expect(meter.getTotalCost(), equals(0.0));
      expect(meter.getTotalTokens(), equals(0));
      expect(meter.getRecords(), isEmpty);
    });

    test('recordUsage creates and stores a record', () {
      final record = meter.recordUsage(
        id: 'r1',
        feature: 'chat',
        modelId: 'gpt-4',
        inputTokens: 100,
        outputTokens: 50,
      );
      expect(record.id, equals('r1'));
      expect(record.feature, equals('chat'));
      expect(meter.getRecords(), hasLength(1));
    });

    test('rapid successive recordUsage calls all persist for the next session',
        () async {
      for (var i = 0; i < 20; i++) {
        meter.recordUsage(
          id: 'burst-$i',
          feature: 'chat',
          modelId: 'gpt-4',
          inputTokens: 1,
          outputTokens: 1,
        );
      }
      // Saves are fire-and-forget; wait for the ordered
      // write chain to finish before reloading from the box.
      await meter.persistenceComplete;

      final reloaded = LlmUsageMeter();
      await reloaded.init();
      expect(reloaded.getRecords().length, 20);
      final ids = reloaded.getRecords().map((r) => r.id).toSet();
      expect(ids, containsAll(['burst-0', 'burst-10', 'burst-19']));
    });

    test('recordUsage stores unsuccessful record', () {
      meter.recordUsage(
        id: 'r1',
        feature: 'chat',
        modelId: 'gpt-4',
        inputTokens: 0,
        outputTokens: 0,
        success: false,
      );
      expect(meter.getRecords().first.success, isFalse);
    });

    test('recordUsage calculates dollar-scale cost for a million tokens',
        () {
      final record = meter.recordUsage(
        id: 'r1',
        feature: 'chat',
        modelId: 'gpt-4',
        inputTokens: 1000000,
        outputTokens: 500000,
      );
      // 1M input ($6.00) + 0.5M output ($1.20) at default per-token prices.
      expect(record.cost, closeTo(7.20, 1e-9));
    });

    test('getRecords returns most recent first', () {
      meter.recordUsage(id: 'r1', feature: 'chat', modelId: 'gpt-4', inputTokens: 10, outputTokens: 5);
      meter.recordUsage(id: 'r2', feature: 'chat', modelId: 'gpt-4', inputTokens: 10, outputTokens: 5);
      final records = meter.getRecords();
      expect(records.first.id, equals('r2'));
      expect(records.last.id, equals('r1'));
    });

    test('getRecords filters by feature', () {
      meter.recordUsage(id: 'r1', feature: 'chat', modelId: 'gpt-4', inputTokens: 10, outputTokens: 5);
      meter.recordUsage(id: 'r2', feature: 'embedding', modelId: 'ada', inputTokens: 20, outputTokens: 0);
      meter.recordUsage(id: 'r3', feature: 'chat', modelId: 'gpt-3', inputTokens: 5, outputTokens: 3);

      final chatRecords = meter.getRecords(feature: 'chat');
      expect(chatRecords, hasLength(2));
      expect(chatRecords.every((r) => r.feature == 'chat'), isTrue);
    });

    test('getRecords respects limit', () {
      meter.recordUsage(id: 'r1', feature: 'chat', modelId: 'gpt-4', inputTokens: 10, outputTokens: 5);
      meter.recordUsage(id: 'r2', feature: 'chat', modelId: 'gpt-4', inputTokens: 10, outputTokens: 5);
      meter.recordUsage(id: 'r3', feature: 'chat', modelId: 'gpt-4', inputTokens: 10, outputTokens: 5);

      expect(meter.getRecords(limit: 2), hasLength(2));
    });

    test('getRecords with limit larger than total returns all', () {
      meter.recordUsage(id: 'r1', feature: 'chat', modelId: 'gpt-4', inputTokens: 10, outputTokens: 5);
      expect(meter.getRecords(limit: 10), hasLength(1));
    });

    test('getTotalTokensPerFeature aggregates correctly', () {
      meter.recordUsage(id: 'r1', feature: 'chat', modelId: 'gpt-4', inputTokens: 100, outputTokens: 50);
      meter.recordUsage(id: 'r2', feature: 'embedding', modelId: 'ada', inputTokens: 30, outputTokens: 0);
      meter.recordUsage(id: 'r3', feature: 'chat', modelId: 'gpt-3', inputTokens: 10, outputTokens: 10);

      final totals = meter.getTotalTokensPerFeature();
      expect(totals['chat'], equals(170));
      expect(totals['embedding'], equals(30));
    });

    test('getTotalCostPerFeature aggregates correctly', () {
      meter.recordUsage(id: 'r1', feature: 'chat', modelId: 'gpt-4', inputTokens: 100, outputTokens: 50);
      meter.recordUsage(id: 'r2', feature: 'embedding', modelId: 'ada', inputTokens: 30, outputTokens: 0);

      final costs = meter.getTotalCostPerFeature();
      expect(costs.containsKey('chat'), isTrue);
      expect(costs.containsKey('embedding'), isTrue);
    });

    test('getTotalTokensPerTaskType classifies feature-derived types as tutor/mentor/summarization',
        () {
      // Mirrors LlmChatService._recordCompletion: the task type is derived from
      // the feature string via LlmTaskType.fromFeature. Live teaching and mentor
      // turns (plus memory compression) must classify as 'tutor', 'mentor', and
      // 'summarization' respectively — never falling into the 'unknown'
      // catch-all bucket (Vision Next-Term §0 token principle).
      meter.recordUsage(
        id: 't1',
        feature: 'teaching',
        modelId: 'gpt-4',
        inputTokens: 100,
        outputTokens: 50,
        taskType: LlmTaskType.fromFeature('teaching')?.name,
      );
      meter.recordUsage(
        id: 'm1',
        feature: 'mentor',
        modelId: 'gpt-4',
        inputTokens: 200,
        outputTokens: 80,
        taskType: LlmTaskType.fromFeature('mentor')?.name,
      );
      meter.recordUsage(
        id: 'mem',
        feature: 'conversation_memory_compression',
        modelId: 'gpt-4',
        inputTokens: 10,
        outputTokens: 40,
        taskType: LlmTaskType.fromFeature('conversation_memory_compression')?.name,
      );

      final byType = meter.getTotalTokensPerTaskType();
      expect(byType['tutor'], equals(150)); // 100 + 50
      expect(byType['mentor'], equals(280)); // 200 + 80
      expect(byType['summarization'], equals(50)); // 10 + 40
      // No live turn should be hidden under the 'unknown' bucket.
      expect(byType.containsKey('unknown'), isFalse);
      expect(meter.getTotalTokens(), equals(480));
    });

    test("'unknown' catch-all never hides classifiable ingestion work (syllabus extraction)", () {
      // Syllabus topic extraction (ContentPipeline) passes feature:
      // 'syllabus_topic_extraction' to the LLM service, which derives the
      // task type via LlmTaskType.fromFeature. It must classify as
      // 'classification' — never null/'unknown' — so prep-token attribution
      // stays auditable in the task-manager portal (Vision §0: students must
      // see and steer where tokens go).
      meter.recordUsage(
        id: 's1',
        feature: 'syllabus_topic_extraction',
        modelId: 'gpt-4o-mini',
        inputTokens: 200,
        outputTokens: 60,
        taskType: LlmTaskType.fromFeature('syllabus_topic_extraction')?.name,
      );

      final byType = meter.getTotalTokensPerTaskType();
      expect(
        byType['classification'],
        equals(260), // 200 + 60, attributed to classification
      );
      // The 'unknown' catch-all must not swallow syllabus-extraction tokens.
      expect(byType.containsKey('unknown'), isFalse);
      expect(meter.getTotalTokens(), equals(260));
    });

    test("'unknown' catch-all never hides planner-advisor plan-generation tokens", () {
      // Planner advisor calls (PersonalLearningPlanService._buildPlan ->
      // LlmPlannerAdvisorStrategy._callAndParse) pass feature:
      // 'planner_advisor_plan_generation' to the LLM service. LlmTaskType
      // .fromFeature now maps it to mentor, so usage lands in the 'mentor'
      // bucket — never 'unknown' (Vision §0: students must see and steer
      // where tokens go).
      meter.recordUsage(
        id: 'p1',
        feature: 'planner_advisor_plan_generation',
        modelId: 'gpt-4o',
        inputTokens: 300,
        outputTokens: 120,
        taskType: LlmTaskType.fromFeature('planner_advisor_plan_generation')?.name,
      );

      final byType = meter.getTotalTokensPerTaskType();
      expect(byType['mentor'], equals(420)); // 300 + 120
      expect(byType.containsKey('unknown'), isFalse,
          reason: 'planner-advisor tokens must not fall into the unknown catch-all');
      expect(meter.getTotalTokens(), equals(420));
    });

    test('pdf_ingestion feature classifies as background — not unknown', () {
      // Vision §0 token principle: students must see where tokens go. Bulk PDF
      // ingestion passes feature: 'pdf_ingestion' to the LLM service;
      // LlmTaskType.fromFeature('pdf_ingestion') maps to LlmTaskType.background,
      // so usage must land in the 'background' bucket — never 'unknown'.
      meter.recordUsage(
        id: 'pdf1',
        feature: 'pdf_ingestion',
        modelId: 'gpt-4o-mini',
        inputTokens: 300,
        outputTokens: 120,
        taskType: LlmTaskType.fromFeature('pdf_ingestion')?.name,
      );

      final byType = meter.getTotalTokensPerTaskType();
      expect(byType['background'], equals(420)); // 300 + 120
      expect(byType.containsKey('unknown'), isFalse,
          reason: 'pdf_ingestion must not fall into the unknown catch-all');
      expect(byType['pdf_ingestion'], isNull,
          reason: 'taskType is derived from feature, not stored as pdf_ingestion');
    });

    test('getTotalCost sums all records', () {
      meter.recordUsage(id: 'r1', feature: 'chat', modelId: 'gpt-4', inputTokens: 100, outputTokens: 50);
      meter.recordUsage(id: 'r2', feature: 'chat', modelId: 'gpt-4', inputTokens: 50, outputTokens: 25);

      final total = meter.getTotalCost();
      expect(total, greaterThan(meter.getTotalCostPerFeature()['chat']! - total));
    });

    test('getTotalTokens sums all records', () {
      meter.recordUsage(id: 'r1', feature: 'chat', modelId: 'gpt-4', inputTokens: 100, outputTokens: 50);
      meter.recordUsage(id: 'r2', feature: 'chat', modelId: 'gpt-4', inputTokens: 50, outputTokens: 25);
      expect(meter.getTotalTokens(), equals(225));
    });

    test('clear removes all records', () {
      meter.recordUsage(id: 'r1', feature: 'chat', modelId: 'gpt-4', inputTokens: 10, outputTokens: 5);
      meter.clear();
      expect(meter.getRecords(), isEmpty);
      expect(meter.getTotalCost(), equals(0.0));
      expect(meter.getTotalTokens(), equals(0));
    });

    test('clear persists to the box so records stay cleared after re-init',
        () async {
      meter.recordUsage(id: 'r1', feature: 'chat', modelId: 'gpt-4', inputTokens: 10, outputTokens: 5);
      // Let the record's own save finish first, so clear() is the
      // only mutation left to persist.
      await meter.persistenceComplete;
      meter.clear();
      // Saves are fire-and-forget; wait for the ordered write
      // chain to finish before reloading from the box.
      await meter.persistenceComplete;

      final reloaded = LlmUsageMeter();
      await reloaded.init();
      expect(reloaded.getRecords(), isEmpty);
      expect(reloaded.getTotalTokens(), equals(0));
      expect(reloaded.getTotalCost(), equals(0.0));
    });

    test('getTotalCostPerFeature returns empty map when no records', () {
      expect(meter.getTotalCostPerFeature(), isEmpty);
    });

    test('getTotalTokensPerFeature returns empty map when no records', () {
      expect(meter.getTotalTokensPerFeature(), isEmpty);
    });

    test('getRecords with non-existent feature returns empty', () {
      expect(meter.getRecords(feature: 'nonexistent'), isEmpty);
    });

    test('getRecords with limit 0 returns empty list', () {
      meter.recordUsage(id: 'r1', feature: 'chat', modelId: 'gpt-4', inputTokens: 10, outputTokens: 5);
      expect(meter.getRecords(limit: 0), isEmpty);
    });

    test('enforces 1000 record cap', () {
      for (int i = 0; i < 1005; i++) {
        meter.recordUsage(id: 'r$i', feature: 'chat', modelId: 'gpt-4', inputTokens: 1, outputTokens: 1);
      }
      expect(meter.getRecords().length, lessThanOrEqualTo(1000));
    });
  });
}
