import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_model.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_type.dart';
import 'package:studyking/features/focus_mode/data/repositories/focus_session_repository.dart';

void main() {
  group('FocusSessionRepository', () {
    late FocusSessionRepository repository;

    setUp(() {
      repository = FocusSessionRepository();
    });

    test('save returns failure when not initialized', () async {
      final result = await repository.save(FocusSession(
        id: 'test-1',
        studentId: 'student-1',
        startTime: DateTime(2025, 1, 1),
        endTime: DateTime(2025, 1, 1, 1),
      ));
      expect(result.isFailure, isTrue);
    });

    test('get returns failure when not initialized', () async {
      final result = await repository.get('nonexistent');
      expect(result.isFailure, isTrue);
    });

    test('getAll returns failure when not initialized', () async {
      final result = await repository.getAll();
      expect(result.isFailure, isTrue);
    });

    test('getLatest returns failure when not initialized', () async {
      final result = await repository.getLatest();
      expect(result.isFailure, isTrue);
    });

    test('Session model toJson/fromJson round-trip', () {
      final now = DateTime(2025, 6, 1, 10, 30);
      final session = FocusSession(
        id: 'roundtrip-1',
        studentId: 'student-1',
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        durationMinutes: 60,
        questionsAnswered: 20,
        correctAnswers: 15,
        accuracy: 0.75,
        sessionType: FocusSessionType.freeFocus,
        subjectIds: ['subj-1'],
        masteryChanges: {'subj-1': 0.05},
      );
      final json = session.toJson();
      final restored = FocusSession.fromJson(json);

      expect(restored.id, session.id);
      expect(restored.studentId, session.studentId);
      expect(restored.startTime, session.startTime);
      expect(restored.endTime, session.endTime);
      expect(restored.durationMinutes, session.durationMinutes);
      expect(restored.questionsAnswered, session.questionsAnswered);
      expect(restored.correctAnswers, session.correctAnswers);
      expect(restored.accuracy, session.accuracy);
      expect(restored.sessionType, session.sessionType);
    });

    test('Session model toJson without optional fields', () {
      final now = DateTime(2025, 6, 1, 10, 30);
      final session = FocusSession(
        id: 'minimal-1',
        studentId: 'student-1',
        startTime: now,
      );
      final json = session.toJson();
      final restored = FocusSession.fromJson(json);

      expect(restored.id, 'minimal-1');
      expect(restored.startTime, now);
      expect(restored.endTime, isNull);
    });

    test('Session model has correct default values', () {
      final session = FocusSession(
        id: 'defaults-1',
        studentId: 'student-1',
        startTime: DateTime(2025, 6, 1),
      );
      expect(session.durationMinutes, 25);
      expect(session.questionsAnswered, 0);
      expect(session.correctAnswers, 0);
      expect(session.accuracy, 0.0);
      expect(session.sessionType, FocusSessionType.spacedRepetition);
      expect(session.subjectIds, isEmpty);
    });
  });
}
