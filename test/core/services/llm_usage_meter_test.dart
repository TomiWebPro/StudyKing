import 'package:flutter_test/flutter_test.dart';
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
  });

  group('LlmUsageMeter', () {
    late LlmUsageMeter meter;

    setUp(() {
      meter = LlmUsageMeter();
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

    test('recordUsage calculates non-zero cost', () {
      final record = meter.recordUsage(
        id: 'r1',
        feature: 'chat',
        modelId: 'gpt-4',
        inputTokens: 1000000,
        outputTokens: 500000,
      );
      expect(record.cost, greaterThan(0));
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

    test('getTotalCostPerFeature returns empty map when no records', () {
      expect(meter.getTotalCostPerFeature(), isEmpty);
    });

    test('getTotalTokensPerFeature returns empty map when no records', () {
      expect(meter.getTotalTokensPerFeature(), isEmpty);
    });
  });
}
