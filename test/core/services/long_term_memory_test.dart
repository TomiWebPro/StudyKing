import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm_agent/agent_memory.dart';
import 'package:studyking/core/services/long_term_memory.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';

class _FakeAgentMemoryStore extends AgentMemoryStore {
  final Map<String, String> _store = {};
  final Map<String, Map<String, dynamic>> _profiles = {};
  final Map<String, List<String>> _sessionLists = {};
  final Map<String, String> _sessionSummaries = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> rememberFact(String studentId, String key, String value) async {
    _store['agent_fact_${studentId}_$key'] = value;
  }

  @override
  String? recallFact(String studentId, String key) {
    return _store['agent_fact_${studentId}_$key'];
  }

  @override
  Future<void> storeSessionSummary(
      String studentId, String sessionId, String summary) async {
    _sessionSummaries['agent_session_${studentId}_$sessionId'] = summary;
    final listKey = 'agent_sessions_$studentId';
    _sessionLists.putIfAbsent(listKey, () => []);
    if (!_sessionLists[listKey]!.contains(sessionId)) {
      _sessionLists[listKey]!.add(sessionId);
    }
  }

  @override
  String? getSessionSummary(String studentId, String sessionId) {
    return _sessionSummaries['agent_session_${studentId}_$sessionId'];
  }

  @override
  List<String> getSessionIds(String studentId) {
    return _sessionLists['agent_sessions_$studentId'] ?? [];
  }

  @override
  Future<void> storeStudentProfile(
      String studentId, Map<String, dynamic> profile) async {
    _profiles[studentId] = profile;
  }

  @override
  Map<String, dynamic>? getStudentProfile(String studentId) {
    return _profiles[studentId];
  }

  @override
  Future<void> clearStudentMemory(String studentId) async {
    _store.removeWhere((k, _) => k.contains(studentId));
    _profiles.remove(studentId);
    _sessionLists.remove('agent_sessions_$studentId');
    _sessionSummaries.removeWhere((k, _) => k.contains(studentId));
  }
}

class _FakePendingActionRepository extends PendingActionRepository {
  final List<PendingActionModel> _actions = [];

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<void>> create(PendingActionModel action) async {
    _actions.add(action);
    return Result.success(null);
  }

  @override
  Future<Result<List<PendingActionModel>>> getPending(
      String studentId) async {
    return Result.success(
      _actions
          .where((a) => a.studentId == studentId && a.status == 'pending')
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }
}

void main() {
  late _FakeAgentMemoryStore fakeStore;
  late _FakePendingActionRepository fakeRepo;
  late LongTermMemory ltm;

  setUp(() {
    fakeStore = _FakeAgentMemoryStore();
    fakeRepo = _FakePendingActionRepository();
    ltm = LongTermMemory(
      store: fakeStore,
      pendingActionRepo: fakeRepo,
    );
  });

  group('LongTermMemory - Facts', () {
    test('rememberFact stores and recallFact retrieves', () async {
      await ltm.rememberFact('student1', 'preferredDifficulty', 'hard');
      expect(ltm.recallFact('student1', 'preferredDifficulty'), equals('hard'));
    });

    test('recallFact returns null for missing key', () {
      expect(ltm.recallFact('student1', 'nonexistent'), isNull);
    });

    test('facts are scoped by studentId', () async {
      await ltm.rememberFact('student1', 'preferredStyle', 'visual');
      await ltm.rememberFact('student2', 'preferredStyle', 'auditory');
      expect(ltm.recallFact('student1', 'preferredStyle'), equals('visual'));
      expect(ltm.recallFact('student2', 'preferredStyle'), equals('auditory'));
    });
  });

  group('LongTermMemory - Student Profile', () {
    test('storeStudentProfile and getStudentProfile', () async {
      await ltm.storeStudentProfile('student1', {
        'preferredDifficulty': 'medium',
        'teachingStyle': 'conversational',
      });
      final profile = ltm.getStudentProfile('student1');
      expect(profile, isNotNull);
      expect(profile!['preferredDifficulty'], equals('medium'));
      expect(profile['teachingStyle'], equals('conversational'));
    });

    test('storeStudentProfile merges with existing', () async {
      await ltm.storeStudentProfile('student1', {'preferredDifficulty': 'easy'});
      await ltm.storeStudentProfile('student1', {'teachingStyle': 'visual'});
      final profile = ltm.getStudentProfile('student1');
      expect(profile!['preferredDifficulty'], equals('easy'));
      expect(profile['teachingStyle'], equals('visual'));
    });

    test('getStudentProfile returns null for unknown student', () {
      expect(ltm.getStudentProfile('nonexistent'), isNull);
    });
  });

  group('LongTermMemory - Session Summaries', () {
    test('storeSessionSummary and getSessionSummary', () async {
      await ltm.storeSessionSummary('student1', 'session1', 'Great session');
      final summary = ltm.getSessionSummary('student1', 'session1');
      expect(summary, equals('Great session'));
    });

    test('getSessionSummary returns null for missing session', () {
      expect(ltm.getSessionSummary('student1', 'nonexistent'), isNull);
    });
  });

  group('LongTermMemory - Action Items', () {
    test('addActionItem creates pending action', () async {
      await ltm.addActionItem('student1', 'review',
          topicTitle: 'Stoichiometry');
      final items = await ltm.getPendingActionItems('student1');
      expect(items, hasLength(1));
      expect(items.first.actionType, equals('review'));
      expect(items.first.topicTitle, equals('Stoichiometry'));
    });

    test('getPendingActionItems returns empty list when none', () async {
      final items = await ltm.getPendingActionItems('student1');
      expect(items, isEmpty);
    });

    test('getPendingActionItems only returns pending items', () async {
      await ltm.addActionItem('student1', 'schedule');
      await ltm.addActionItem('student2', 'review', topicTitle: 'Algebra');
      final items = await ltm.getPendingActionItems('student1');
      expect(items, hasLength(1));
      expect(items.first.actionType, equals('schedule'));
    });
  });

  group('LongTermMemory - Memory Context', () {
    test('buildMemoryContext includes profile when available', () async {
      await ltm.storeStudentProfile('student1', {
        'preferredDifficulty': 'hard',
        'teachingStyle': 'visual',
      });
      final context = await ltm.buildMemoryContext('student1');
      expect(context, contains('Student Profile:'));
      expect(context, contains('preferredDifficulty'));
      expect(context, contains('visual'));
    });

    test('buildMemoryContext includes recent summaries', () async {
      await ltm.storeSessionSummary(
          'student1', 's1', 'Covered algebra basics');
      final context = await ltm.buildMemoryContext('student1');
      expect(context, contains('Session Summaries'));
      expect(context, contains('Covered algebra basics'));
    });

    test('buildMemoryContext includes pending action items', () async {
      await ltm.addActionItem('student1', 'review',
          topicTitle: 'Physics review');
      final context = await ltm.buildMemoryContext('student1');
      expect(context, contains('Pending Action Items'));
      expect(context, contains('Physics review'));
    });

    test('buildMemoryContext returns sections with empty data', () async {
      final context = await ltm.buildMemoryContext('student1');
      expect(context, isNotEmpty);
      expect(context, contains('LONG-TERM MEMORY CONTEXT'));
    });
  });

  group('LongTermMemory - getRecentStudentSummaries', () {
    test('returns recent summaries in reverse order', () async {
      await ltm.storeSessionSummary('student1', 's1', 'First session');
      await ltm.storeSessionSummary('student1', 's2', 'Second session');
      final summaries = await ltm.getRecentStudentSummaries('student1');
      expect(summaries, hasLength(2));
      expect(summaries.first, equals('Second session'));
      expect(summaries.last, equals('First session'));
    });

    test('respects limit parameter', () async {
      for (var i = 1; i <= 10; i++) {
        await ltm.storeSessionSummary('student1', 's$i', 'Session $i');
      }
      final summaries = await ltm.getRecentStudentSummaries('student1', limit: 3);
      expect(summaries, hasLength(3));
      expect(summaries.first, equals('Session 10'));
    });

    test('returns empty list for unknown student', () async {
      final summaries = await ltm.getRecentStudentSummaries('nonexistent');
      expect(summaries, isEmpty);
    });
  });

  group('LongTermMemory - clearStudentMemory', () {
    test('clears all data for a student', () async {
      await ltm.rememberFact('student1', 'key', 'value');
      await ltm.storeSessionSummary('student1', 's1', 'summary');
      await ltm.storeStudentProfile('student1', {'key': 'val'});
      await ltm.addActionItem('student1', 'review');

      await ltm.clearStudentMemory('student1');

      expect(ltm.recallFact('student1', 'key'), isNull);
      expect(ltm.getSessionSummary('student1', 's1'), isNull);
      expect(ltm.getStudentProfile('student1'), isNull);
      final items = await ltm.getPendingActionItems('student1');
      expect(items, hasLength(1));
    });
  });

  group('LongTermMemory - init', () {
    test('init initializes dependencies', () async {
      final freshLtm = LongTermMemory(
        store: _FakeAgentMemoryStore(),
        pendingActionRepo: _FakePendingActionRepository(),
      );
      await expectLater(freshLtm.init(), completes);
    });
  });
}
