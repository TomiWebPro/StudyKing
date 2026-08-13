import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/services/llm/llm_response_cache.dart';

void main() {
  late String hivePath;

  setUpAll(() {
    hivePath = Directory.systemTemp.createTempSync('llm_cache_test_').path;
    Hive.init(hivePath);
  });

  tearDownAll(() async {
    await Hive.close();
    Directory(hivePath).deleteSync(recursive: true);
  });

  group('LlmResponseCache', () {
    late LlmResponseCache cache;

    setUp(() async {
      cache = LlmResponseCache();
      await cache.init();
    });

    tearDown(() async {
      cache.clear();
    });

    test('returns null for cache miss', () {
      final result = cache.get('model-a', 'system prompt', 'user message');
      expect(result, isNull);
    });

    test('stores and retrieves cached response', () {
      cache.set('model-a', 'system prompt', 'user message', 'cached response');
      final result = cache.get('model-a', 'system prompt', 'user message');
      expect(result, equals('cached response'));
    });

    test('generates deterministic keys for same inputs', () {
      final key1 = cache.buildKey('model-a', 'system prompt', 'user message');
      final key2 = cache.buildKey('model-a', 'system prompt', 'user message');
      expect(key1, equals(key2));
    });

    test('generates different keys for different inputs', () {
      final key1 = cache.buildKey('model-a', 'system prompt', 'message 1');
      final key2 = cache.buildKey('model-a', 'system prompt', 'message 2');
      expect(key1, isNot(equals(key2)));
    });

    test('different modelId produces different key', () {
      final key1 = cache.buildKey('model-a', 'system prompt', 'message');
      final key2 = cache.buildKey('model-b', 'system prompt', 'message');
      expect(key1, isNot(equals(key2)));
    });

    test('different systemPrompt produces different key', () {
      final key1 = cache.buildKey('model-a', 'prompt-1', 'message');
      final key2 = cache.buildKey('model-a', 'prompt-2', 'message');
      expect(key1, isNot(equals(key2)));
    });

    test('returns expired entry as null', () async {
      cache.set(
        'model-a',
        'system prompt',
        'user message',
        'cached response',
        ttl: const Duration(milliseconds: 1),
      );
      await Future.delayed(const Duration(milliseconds: 10));
      final result = cache.get('model-a', 'system prompt', 'user message');
      expect(result, isNull);
    });

    test('invalidate removes entries for specific model', () {
      cache.set('model-a', 'sp', 'msg', 'resp-a');
      cache.set('model-b', 'sp', 'msg', 'resp-b');
      expect(cache.size, equals(2));

      cache.invalidate('model-a');
      expect(cache.size, equals(1));
      expect(cache.get('model-b', 'sp', 'msg'), equals('resp-b'));
      expect(cache.get('model-a', 'sp', 'msg'), isNull);
    });

    test('clear removes all entries', () {
      cache.set('model-a', 'sp', 'msg1', 'resp1');
      cache.set('model-b', 'sp', 'msg2', 'resp2');
      expect(cache.size, equals(2));

      cache.clear();
      expect(cache.size, equals(0));
    });

    test('size returns 0 when box is not initialized', () {
      final uninitCache = LlmResponseCache();
      expect(uninitCache.size, equals(0));
    });

    test('get returns null when box is not initialized', () {
      final uninitCache = LlmResponseCache();
      expect(uninitCache.get('m', 's', 'msg'), isNull);
    });

    test('set is no-op when box is not initialized', () {
      final uninitCache = LlmResponseCache();
      uninitCache.set('m', 's', 'msg', 'resp');
      expect(uninitCache.size, equals(0));
    });

    test('ttlForFeature returns correct TTLs', () {
      expect(cache.ttlForFeature('classification'), equals(const Duration(hours: 24)));
      expect(cache.ttlForFeature('lesson_plan'), equals(const Duration(hours: 1)));
      expect(cache.ttlForFeature('tutor'), equals(const Duration(minutes: 5)));
      expect(cache.ttlForFeature('chat'), equals(const Duration(minutes: 5)));
      expect(cache.ttlForFeature('general'), equals(const Duration(minutes: 10)));
      expect(cache.ttlForFeature('unknown_feature'), equals(const Duration(minutes: 10)));
    });

    test('overwrites existing entry for same key', () {
      cache.set('model-a', 'sp', 'msg', 'original');
      cache.set('model-a', 'sp', 'msg', 'updated');
      final result = cache.get('model-a', 'sp', 'msg');
      expect(result, equals('updated'));
    });

    test('entries are independent', () {
      cache.set('model-a', 'sp', 'msg1', 'resp1');
      cache.set('model-a', 'sp', 'msg2', 'resp2');
      expect(cache.get('model-a', 'sp', 'msg1'), equals('resp1'));
      expect(cache.get('model-a', 'sp', 'msg2'), equals('resp2'));
      expect(cache.size, equals(2));
    });
  });
}
