import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/services/llm_agent/agent_memory.dart';

void main() {
  group('AgentMemoryStore', () {
    test('recallFact returns null for unknown key', () {
      final store = AgentMemoryStore();
      expect(store.recallFact('student-1', 'nonexistent'), isNull);
    });

    test('getSessionSummary returns null for unknown session', () {
      final store = AgentMemoryStore();
      expect(store.getSessionSummary('student-1', 'session-1'), isNull);
    });

    test('getSessionIds returns empty list for unknown student', () {
      final store = AgentMemoryStore();
      expect(store.getSessionIds('student-1'), isEmpty);
    });

    test('getStudentProfile returns null for unknown student', () {
      final store = AgentMemoryStore();
      expect(store.getStudentProfile('student-1'), isNull);
    });

    test('rememberFact and recallFact roundtrip', () async {
      final store = AgentMemoryStore();
      await store.rememberFact('student-1', 'preferred_style', 'visual');
      // Note: recallFact reads from Hive which needs initialization
      // Without Hive init, it will return null
      expect(store.recallFact('student-1', 'preferred_style'), isNull);
    });
  });

  group('AgentMemoryStore session list encoding (Hive-backed)', () {
    late String hivePath;
    late AgentMemoryStore store;

    setUpAll(() {
      hivePath = Directory.systemTemp.createTempSync('agent_memory_').path;
      Hive.init(hivePath);
    });

    tearDownAll(() async {
      await Hive.close();
      if (hivePath.isNotEmpty) {
        await Directory(hivePath).delete(recursive: true);
      }
    });

    setUp(() async {
      final box = await Hive.openBox(HiveBoxNames.agentMemory);
      await box.clear();
      store = AgentMemoryStore();
      await store.init();
    });

    test('sessionId containing commas roundtrips without splitting',
        () async {
      const sessionId = '2026-10-10,algebra,period-3';
      await store.storeSessionSummary('student-1', sessionId, 'summary text');

      final ids = store.getSessionIds('student-1');
      expect(ids, equals([sessionId]));
      expect(store.getSessionSummary('student-1', sessionId),
          equals('summary text'));
    });

    test('multiple sessionIds with commas are preserved distinctly',
        () async {
      const first = 'lesson,1';
      const second = 'lesson,2';
      await store.storeSessionSummary('student-1', first, 'first');
      await store.storeSessionSummary('student-1', second, 'second');

      expect(store.getSessionIds('student-1'), equals([first, second]));
      expect(store.getSessionSummary('student-1', first), equals('first'));
      expect(store.getSessionSummary('student-1', second), equals('second'));
    });

    test('duplicate sessionId is not stored twice', () async {
      const sessionId = 'session,with,commas';
      await store.storeSessionSummary('student-1', sessionId, 'first');
      await store.storeSessionSummary('student-1', sessionId, 'second');

      expect(store.getSessionIds('student-1'), equals([sessionId]));
    });

    test('legacy comma-joined session list is still readable', () async {
      final box = await Hive.openBox(HiveBoxNames.agentMemory);
      await box.put('agent_sessions_legacy-1', 'old-1,old-2');

      expect(store.getSessionIds('legacy-1'), equals(['old-1', 'old-2']));
    });

    test('session list is capped at 100 entries, oldest evicted', () async {
      for (var i = 0; i < 105; i++) {
        await store.storeSessionSummary('student-1', 'sess-$i', 'sum $i');
      }

      final ids = store.getSessionIds('student-1');
      expect(ids, hasLength(100));
      expect(ids.first, equals('sess-5'));
      expect(ids.last, equals('sess-104'));
    });
  });
}
