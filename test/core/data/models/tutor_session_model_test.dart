import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/tutor_session_model.dart';

void main() {
  group('SessionStatus', () {
    test('has all expected values', () {
      expect(SessionStatus.values.length, 4);
      expect(SessionStatus.planned.index, 0);
      expect(SessionStatus.inProgress.index, 1);
      expect(SessionStatus.completed.index, 2);
      expect(SessionStatus.cancelled.index, 3);
    });
  });

  group('TutorSession', () {
    final startTime = DateTime(2025, 1, 15, 10, 0, 0);
    final endTime = DateTime(2025, 1, 15, 10, 45, 0);

    TutorSession createSession({
      String id = 'session-1',
      String studentId = 'student-1',
      String subjectId = 'subject-1',
      String topicId = 'topic-1',
      String topicTitle = 'Algebra',
      SessionStatus status = SessionStatus.planned,
      DateTime? start,
      DateTime? end,
      int plannedDurationMinutes = 45,
      String lessonPlanJson = '{}',
      int questionsAsked = 0,
      int questionsCorrect = 0,
      int confidenceRating = 0,
      String? tutorNotes,
      List<String>? topicsCovered,
      int totalMessages = 0,
      int totalTokensUsed = 0,
    }) {
      return TutorSession(
        id: id,
        studentId: studentId,
        subjectId: subjectId,
        topicId: topicId,
        topicTitle: topicTitle,
        status: status,
        startTime: start ?? startTime,
        endTime: end,
        plannedDurationMinutes: plannedDurationMinutes,
        lessonPlanJson: lessonPlanJson,
        questionsAsked: questionsAsked,
        questionsCorrect: questionsCorrect,
        confidenceRating: confidenceRating,
        tutorNotes: tutorNotes,
        topicsCovered: topicsCovered ?? [],
        totalMessages: totalMessages,
        totalTokensUsed: totalTokensUsed,
      );
    }

    test('creates with required fields', () {
      final session = TutorSession(
        id: 'session-1',
        studentId: 'student-1',
        subjectId: 'subject-1',
        topicId: 'topic-1',
        topicTitle: 'Algebra',
        startTime: startTime,
      );
      expect(session.id, 'session-1');
      expect(session.studentId, 'student-1');
      expect(session.subjectId, 'subject-1');
      expect(session.topicId, 'topic-1');
      expect(session.topicTitle, 'Algebra');
      expect(session.status, SessionStatus.planned);
      expect(session.startTime, startTime);
      expect(session.endTime, isNull);
      expect(session.plannedDurationMinutes, 45);
      expect(session.lessonPlanJson, '{}');
      expect(session.questionsAsked, 0);
      expect(session.questionsCorrect, 0);
      expect(session.confidenceRating, 0);
      expect(session.tutorNotes, isNull);
      expect(session.topicsCovered, []);
      expect(session.totalMessages, 0);
      expect(session.totalTokensUsed, 0);
    });

    test('creates with all fields', () {
      final session = TutorSession(
        id: 'session-1',
        studentId: 'student-1',
        subjectId: 'subject-1',
        topicId: 'topic-1',
        topicTitle: 'Algebra',
        status: SessionStatus.completed,
        startTime: startTime,
        endTime: endTime,
        plannedDurationMinutes: 60,
        lessonPlanJson: '{"plan": "test"}',
        questionsAsked: 10,
        questionsCorrect: 7,
        confidenceRating: 4,
        tutorNotes: 'Good progress',
        topicsCovered: ['algebra', 'equations'],
        totalMessages: 25,
        totalTokensUsed: 5000,
      );
      expect(session.endTime, endTime);
      expect(session.status, SessionStatus.completed);
      expect(session.plannedDurationMinutes, 60);
      expect(session.lessonPlanJson, '{"plan": "test"}');
      expect(session.questionsAsked, 10);
      expect(session.questionsCorrect, 7);
      expect(session.confidenceRating, 4);
      expect(session.tutorNotes, 'Good progress');
      expect(session.topicsCovered, ['algebra', 'equations']);
      expect(session.totalMessages, 25);
      expect(session.totalTokensUsed, 5000);
    });

    group('accuracy', () {
      test('returns 0 when no questions asked', () {
        final session = createSession();
        expect(session.accuracy, 0.0);
      });

      test('returns correct ratio', () {
        final session = createSession(questionsAsked: 10, questionsCorrect: 7);
        expect(session.accuracy, 0.7);
      });

      test('returns 1.0 when all correct', () {
        final session = createSession(questionsAsked: 5, questionsCorrect: 5);
        expect(session.accuracy, 1.0);
      });
    });

    group('elapsedMinutes', () {
      test('returns positive value', () {
        final session = createSession(start: DateTime.now().subtract(const Duration(minutes: 30)));
        expect(session.elapsedMinutes, greaterThanOrEqualTo(29));
      });
    });

    group('remainingMinutes', () {
      test('returns planned duration minus elapsed', () {
        final session = createSession(
          start: DateTime.now().subtract(const Duration(minutes: 10)),
          plannedDurationMinutes: 45,
        );
        expect(session.remainingMinutes, lessThanOrEqualTo(45));
        expect(session.remainingMinutes, greaterThanOrEqualTo(0));
      });

      test('clamps to 0 when overtime', () {
        final session = createSession(
          start: DateTime.now().subtract(const Duration(minutes: 60)),
          plannedDurationMinutes: 45,
        );
        expect(session.remainingMinutes, 0);
      });
    });

    group('isOverTime', () {
      test('returns false when within time', () {
        final session = createSession(
          start: DateTime.now().subtract(const Duration(minutes: 30)),
          plannedDurationMinutes: 45,
        );
        expect(session.isOverTime, isFalse);
      });

      test('returns true when overtime', () {
        final session = createSession(
          start: DateTime.now().subtract(const Duration(minutes: 60)),
          plannedDurationMinutes: 45,
        );
        expect(session.isOverTime, isTrue);
      });
    });

    test('creates with all status variants', () {
      for (final status in SessionStatus.values) {
        final session = createSession(status: status);
        expect(session.status, status);
      }
    });

    group('toJson', () {
      test('serializes all fields', () {
        final session = createSession(
          status: SessionStatus.completed,
          end: endTime,
          questionsAsked: 10,
          questionsCorrect: 7,
          tutorNotes: 'Good',
          topicsCovered: ['algebra'],
          totalMessages: 20,
          totalTokensUsed: 1000,
        );
        final json = session.toJson();
        expect(json['id'], 'session-1');
        expect(json['studentId'], 'student-1');
        expect(json['subjectId'], 'subject-1');
        expect(json['topicId'], 'topic-1');
        expect(json['topicTitle'], 'Algebra');
        expect(json['status'], 'completed');
        expect(json['startTime'], startTime.toIso8601String());
        expect(json['endTime'], endTime.toIso8601String());
        expect(json['plannedDurationMinutes'], 45);
        expect(json['questionsAsked'], 10);
        expect(json['questionsCorrect'], 7);
        expect(json['tutorNotes'], 'Good');
        expect(json['topicsCovered'], ['algebra']);
        expect(json['totalMessages'], 20);
        expect(json['totalTokensUsed'], 1000);
      });

      test('serializes with null endTime and tutorNotes', () {
        final session = createSession();
        final json = session.toJson();
        expect(json['endTime'], isNull);
        expect(json['tutorNotes'], isNull);
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'id': 'session-1',
          'studentId': 'student-1',
          'subjectId': 'subject-1',
          'topicId': 'topic-1',
          'topicTitle': 'Algebra',
          'status': 'completed',
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
          'plannedDurationMinutes': 60,
          'lessonPlanJson': '{}',
          'questionsAsked': 10,
          'questionsCorrect': 7,
          'confidenceRating': 4,
          'tutorNotes': 'Good session',
          'topicsCovered': ['algebra'],
          'totalMessages': 30,
          'totalTokensUsed': 6000,
        };
        final session = TutorSession.fromJson(json);
        expect(session.id, 'session-1');
        expect(session.studentId, 'student-1');
        expect(session.status, SessionStatus.completed);
        expect(session.endTime, endTime);
        expect(session.plannedDurationMinutes, 60);
        expect(session.questionsAsked, 10);
        expect(session.questionsCorrect, 7);
        expect(session.confidenceRating, 4);
        expect(session.tutorNotes, 'Good session');
        expect(session.topicsCovered, ['algebra']);
        expect(session.totalMessages, 30);
        expect(session.totalTokensUsed, 6000);
      });

      test('deserializes with missing optionals', () {
        final json = {
          'id': 'session-1',
          'studentId': 'student-1',
          'subjectId': 'subject-1',
          'topicId': 'topic-1',
          'topicTitle': 'Algebra',
          'status': 'planned',
          'startTime': startTime.toIso8601String(),
        };
        final session = TutorSession.fromJson(json);
        expect(session.endTime, isNull);
        expect(session.plannedDurationMinutes, 45);
        expect(session.lessonPlanJson, '{}');
        expect(session.questionsAsked, 0);
        expect(session.questionsCorrect, 0);
        expect(session.confidenceRating, 0);
        expect(session.tutorNotes, isNull);
        expect(session.topicsCovered, []);
        expect(session.totalMessages, 0);
        expect(session.totalTokensUsed, 0);
      });

      test('deserializes all status values', () {
        for (final status in SessionStatus.values) {
          final json = {
            'id': 's', 'studentId': 'stu', 'subjectId': 'sub', 'topicId': 't',
            'topicTitle': 'T', 'status': status.name, 'startTime': startTime.toIso8601String(),
          };
          final session = TutorSession.fromJson(json);
          expect(session.status, status);
        }
      });
    });

    group('serialization roundtrip', () {
      test('toJson then fromJson preserves data', () {
        final original = createSession(
          status: SessionStatus.inProgress,
          plannedDurationMinutes: 30,
          questionsAsked: 5,
          questionsCorrect: 4,
          confidenceRating: 3,
          tutorNotes: 'Well done',
          topicsCovered: ['math'],
          totalMessages: 10,
          totalTokensUsed: 2000,
        );
        final json = original.toJson();
        final restored = TutorSession.fromJson(json);
        expect(restored.id, original.id);
        expect(restored.studentId, original.studentId);
        expect(restored.subjectId, original.subjectId);
        expect(restored.topicId, original.topicId);
        expect(restored.topicTitle, original.topicTitle);
        expect(restored.status, original.status);
        expect(restored.startTime, original.startTime);
        expect(restored.plannedDurationMinutes, original.plannedDurationMinutes);
        expect(restored.questionsAsked, original.questionsAsked);
        expect(restored.questionsCorrect, original.questionsCorrect);
        expect(restored.tutorNotes, original.tutorNotes);
        expect(restored.topicsCovered, original.topicsCovered);
      });
    });

    group('copyWith', () {
      test('creates new instance with updated fields', () {
        final original = createSession();
        final copy = original.copyWith(status: SessionStatus.inProgress, tutorNotes: 'Updated notes');
        expect(copy.status, SessionStatus.inProgress);
        expect(copy.tutorNotes, 'Updated notes');
        expect(original.status, SessionStatus.planned);
      });

      test('copyWith preserves original values when no args', () {
        final original = createSession(
          status: SessionStatus.completed, end: endTime, questionsAsked: 10, questionsCorrect: 8,
        );
        final copy = original.copyWith();
        expect(copy.id, original.id);
        expect(copy.studentId, original.studentId);
        expect(copy.subjectId, original.subjectId);
        expect(copy.topicId, original.topicId);
        expect(copy.topicTitle, original.topicTitle);
        expect(copy.status, original.status);
        expect(copy.startTime, original.startTime);
        expect(copy.endTime, original.endTime);
        expect(copy.plannedDurationMinutes, original.plannedDurationMinutes);
        expect(copy.questionsAsked, original.questionsAsked);
        expect(copy.questionsCorrect, original.questionsCorrect);
      });

      test('copyWith updates all fields', () {
        final original = createSession();
        final copy = original.copyWith(
          id: 'session-2',
          studentId: 'student-2',
          subjectId: 'subject-2',
          topicId: 'topic-2',
          topicTitle: 'Calculus',
          status: SessionStatus.completed,
          startTime: endTime,
          endTime: startTime,
          plannedDurationMinutes: 90,
          lessonPlanJson: '{"plan": "advanced"}',
          questionsAsked: 20,
          questionsCorrect: 18,
          confidenceRating: 5,
          tutorNotes: 'Excellent',
          topicsCovered: ['calculus', 'derivatives'],
          totalMessages: 50,
          totalTokensUsed: 10000,
        );
        expect(copy.id, 'session-2');
        expect(copy.studentId, 'student-2');
        expect(copy.subjectId, 'subject-2');
        expect(copy.topicTitle, 'Calculus');
        expect(copy.status, SessionStatus.completed);
        expect(copy.confidenceRating, 5);
        expect(copy.tutorNotes, 'Excellent');
        expect(copy.totalTokensUsed, 10000);
      });
    });
  });
}
