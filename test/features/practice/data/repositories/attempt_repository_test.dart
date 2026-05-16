import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';

class _MockAttemptRepository extends AttemptRepository {
  final Map<String, StudentAttempt> _storage = {};

  @override
  Future<void> init() async {
  }

  @override
  Future<void> create(StudentAttempt attempt) async {
    _storage[attempt.id] = attempt;
  }

  @override
  Future<StudentAttempt?> get(String id) async {
    return _storage[id];
  }

  @override
  Future<List<StudentAttempt>> getAll() async {
    return _storage.values.toList();
  }

  @override
  Future<List<StudentAttempt>> getByStudent(String studentId) async {
    return _storage.values.where((a) => a.studentId == studentId).toList();
  }

  @override
  Future<List<StudentAttempt>> getByStudentAndSubject(String studentId, String subjectId) async {
    return _storage.values
        .where((a) => a.studentId == studentId && a.subjectId == subjectId)
        .toList();
  }

  @override
  Future<List<StudentAttempt>> getByQuestion(String questionId) async {
    return _storage.values.where((a) => a.questionId == questionId).toList();
  }

  @override
  Future<List<StudentAttempt>> getBySubject(String subjectId) async {
    return _storage.values.where((a) => a.subjectId == subjectId).toList();
  }

  @override
  Future<Map<String, dynamic>> getSubjectStats(String subjectId) async {
    final attempts = await getBySubject(subjectId);
    final correct = attempts.where((a) => a.isCorrect).length;
    final total = attempts.length;
    return {
      'total': total,
      'correct': correct,
      'incorrect': total - correct,
      'accuracy': total > 0 ? correct / total : 0.0,
    };
  }

  @override
  Future<void> delete(String id) async {
    _storage.remove(id);
  }
}

void main() {
  group('AttemptRepository', () {
    late _MockAttemptRepository repository;
    late DateTime now;

    setUp(() {
      repository = _MockAttemptRepository();
      now = DateTime(2026, 5, 12);
    });

    group('create', () {
      test('stores an attempt', () async {
        final attempt = StudentAttempt(id: 'a1', studentId: 's1', questionId: 'q1', subjectId: 'sub1', timestamp: now);
        await repository.create(attempt);
        final stored = await repository.get('a1');
        expect(stored?.id, 'a1');
      });
    });

    group('get', () {
      test('returns null for non-existent', () async {
        expect(await repository.get('none'), isNull);
      });
    });

    group('getAll', () {
      test('returns all attempts', () async {
        await repository.create(StudentAttempt(id: 'a1', studentId: 's1', questionId: 'q1', subjectId: 'sub1', timestamp: now));
        await repository.create(StudentAttempt(id: 'a2', studentId: 's1', questionId: 'q2', subjectId: 'sub1', timestamp: now));
        expect((await repository.getAll()).length, 2);
      });

      test('returns empty when no attempts', () async {
        expect(await repository.getAll(), isEmpty);
      });
    });

    group('getByStudent', () {
      test('returns attempts for student', () async {
        await repository.create(StudentAttempt(id: 'a1', studentId: 's1', questionId: 'q1', subjectId: 'sub1', timestamp: now));
        await repository.create(StudentAttempt(id: 'a2', studentId: 's2', questionId: 'q2', subjectId: 'sub1', timestamp: now));
        final result = await repository.getByStudent('s1');
        expect(result.length, 1);
      });

      test('returns empty for student with no attempts', () async {
        expect(await repository.getByStudent('none'), isEmpty);
      });
    });

    group('getByStudentAndSubject', () {
      test('returns filtered attempts', () async {
        await repository.create(StudentAttempt(id: 'a1', studentId: 's1', questionId: 'q1', subjectId: 'sub1', timestamp: now));
        await repository.create(StudentAttempt(id: 'a2', studentId: 's1', questionId: 'q2', subjectId: 'sub2', timestamp: now));
        final result = await repository.getByStudentAndSubject('s1', 'sub1');
        expect(result.length, 1);
      });

      test('returns empty when no match', () async {
        expect(await repository.getByStudentAndSubject('s1', 'sub1'), isEmpty);
      });
    });

    group('getByQuestion', () {
      test('returns attempts for question', () async {
        await repository.create(StudentAttempt(id: 'a1', studentId: 's1', questionId: 'q1', subjectId: 'sub1', timestamp: now));
        await repository.create(StudentAttempt(id: 'a2', studentId: 's2', questionId: 'q1', subjectId: 'sub1', timestamp: now));
        expect((await repository.getByQuestion('q1')).length, 2);
      });

      test('returns empty for question with no attempts', () async {
        expect(await repository.getByQuestion('none'), isEmpty);
      });
    });

    group('getBySubject', () {
      test('returns attempts for subject', () async {
        await repository.create(StudentAttempt(id: 'a1', studentId: 's1', questionId: 'q1', subjectId: 'sub1', timestamp: now));
        await repository.create(StudentAttempt(id: 'a2', studentId: 's1', questionId: 'q2', subjectId: 'sub2', timestamp: now));
        expect((await repository.getBySubject('sub1')).length, 1);
      });

      test('returns empty for subject with no attempts', () async {
        expect(await repository.getBySubject('none'), isEmpty);
      });
    });

    group('getSubjectStats', () {
      test('returns correct stats', () async {
        await repository.create(StudentAttempt(id: 'a1', studentId: 's1', questionId: 'q1', subjectId: 'sub1', isCorrect: true, timestamp: now));
        await repository.create(StudentAttempt(id: 'a2', studentId: 's1', questionId: 'q2', subjectId: 'sub1', isCorrect: false, timestamp: now));
        await repository.create(StudentAttempt(id: 'a3', studentId: 's1', questionId: 'q3', subjectId: 'sub1', isCorrect: true, timestamp: now));
        final stats = await repository.getSubjectStats('sub1');
        expect(stats['total'], 3);
        expect(stats['correct'], 2);
        expect(stats['incorrect'], 1);
        expect(stats['accuracy'], 2 / 3);
      });

      test('returns zero stats for no attempts', () async {
        final stats = await repository.getSubjectStats('empty');
        expect(stats['total'], 0);
        expect(stats['accuracy'], 0.0);
      });
    });

    group('delete', () {
      test('removes attempt', () async {
        await repository.create(StudentAttempt(id: 'a1', studentId: 's1', questionId: 'q1', subjectId: 'sub1', timestamp: now));
        await repository.delete('a1');
        expect(await repository.get('a1'), isNull);
      });
    });
  });

  group('AttemptRepository (init with real Hive)', () {
    late AttemptRepository repository;
    late String hivePath;

    setUpAll(() {
      Hive.registerAdapter(StudentAttemptAdapter());
    });

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('attempt_repo_test_');
      hivePath = dir.path;
      Hive.init(hivePath);
      repository = AttemptRepository();
      await repository.init();
    });

    tearDown(() async {
      await repository.box.close();
      await Hive.deleteBoxFromDisk('attempts');
    });

    test('init opens box and supports CRUD', () async {
      final attempt = StudentAttempt(id: 'hive-1', studentId: 's1', questionId: 'q1', subjectId: 'sub1', timestamp: DateTime.now());
      await repository.create(attempt);
      final stored = await repository.get('hive-1');
      expect(stored, isNotNull);
      expect(stored!.studentId, 's1');
    });

    test('getByStudent works after init', () async {
      await repository.create(StudentAttempt(id: 'a1', studentId: 's1', questionId: 'q1', subjectId: 'sub1', timestamp: DateTime.now()));
      await repository.create(StudentAttempt(id: 'a2', studentId: 's1', questionId: 'q2', subjectId: 'sub1', timestamp: DateTime.now()));
      await repository.create(StudentAttempt(id: 'a3', studentId: 's2', questionId: 'q3', subjectId: 'sub1', timestamp: DateTime.now()));
      expect(await repository.getByStudent('s1'), hasLength(2));
    });

    test('getSubjectStats works after init', () async {
      await repository.create(StudentAttempt(id: 's1', studentId: 's1', questionId: 'q1', subjectId: 'sub1', isCorrect: true, timestamp: DateTime.now()));
      await repository.create(StudentAttempt(id: 's2', studentId: 's1', questionId: 'q2', subjectId: 'sub1', isCorrect: false, timestamp: DateTime.now()));
      final stats = await repository.getSubjectStats('sub1');
      expect(stats['total'], 2);
      expect(stats['correct'], 1);
    });
  });
}
