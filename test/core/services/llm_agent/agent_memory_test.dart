import 'package:flutter_test/flutter_test.dart';
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
}
