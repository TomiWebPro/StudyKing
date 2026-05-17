import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/core/data/models/session_model.dart';

void main() {
  group('TutorSession', () {
    final startTime = DateTime(2026, 5, 16, 10, 0);
    const id = 'session-1';
    const studentId = 'student-1';
    const subjectId = 'subject-1';
    const topicId = 'topic-1';
    const topicTitle = 'Kinematics';

    group('constructor', () {
      test('creates instance with required fields', () {
        final session = TutorSession(
          id: id, studentId: studentId,
          subjectId: subjectId, topicId: topicId,
          topicTitle: topicTitle, startTime: startTime,
        );
        expect(session.id, id);
        expect(session.studentId, studentId);
        expect(session.subjectId, subjectId);
        expect(session.topicId, topicId);
        expect(session.topicTitle, topicTitle);
        expect(session.startTime, startTime);
        expect(session.status, SessionStatus.planned);
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

      test('accepts all optional fields', () {
        final endTime = DateTime(2026, 5, 16, 11, 0);
        final session = TutorSession(
          id: id, studentId: studentId,
          subjectId: subjectId, topicId: topicId,
          topicTitle: topicTitle, startTime: startTime,
          status: SessionStatus.completed, endTime: endTime,
          plannedDurationMinutes: 60, lessonPlanJson: '{"plan": true}',
          questionsAsked: 10, questionsCorrect: 8, confidenceRating: 4,
          tutorNotes: 'Good session', topicsCovered: ['Kinematics'],
          totalMessages: 25, totalTokensUsed: 5000,
        );
        expect(session.status, SessionStatus.completed);
        expect(session.endTime, endTime);
        expect(session.plannedDurationMinutes, 60);
        expect(session.questionsAsked, 10);
        expect(session.questionsCorrect, 8);
        expect(session.confidenceRating, 4);
        expect(session.tutorNotes, 'Good session');
        expect(session.topicsCovered, ['Kinematics']);
        expect(session.totalMessages, 25);
        expect(session.totalTokensUsed, 5000);
      });
    });

    group('accuracy', () {
      test('computes accuracy correctly', () {
        final session = TutorSession(
          id: id, studentId: studentId,
          subjectId: subjectId, topicId: topicId,
          topicTitle: topicTitle, startTime: startTime,
          questionsAsked: 10, questionsCorrect: 7,
        );
        expect(session.accuracy, 0.7);
      });

      test('returns 0 when no questions asked', () {
        final session = TutorSession(
          id: id, studentId: studentId,
          subjectId: subjectId, topicId: topicId,
          topicTitle: topicTitle, startTime: startTime,
        );
        expect(session.accuracy, 0.0);
      });
    });

    group('elapsedMinutes', () {
      test('returns positive elapsed time', () {
        final recent = DateTime.now().subtract(const Duration(minutes: 30));
        final session = TutorSession(
          id: id, studentId: studentId,
          subjectId: subjectId, topicId: topicId,
          topicTitle: topicTitle, startTime: recent,
        );
        expect(session.elapsedMinutes, greaterThanOrEqualTo(28));
      });
    });

    group('remainingMinutes', () {
      test('returns remaining time', () {
        final recent = DateTime.now().subtract(const Duration(minutes: 10));
        final session = TutorSession(
          id: id, studentId: studentId,
          subjectId: subjectId, topicId: topicId,
          topicTitle: topicTitle, startTime: recent,
          plannedDurationMinutes: 45,
        );
        expect(session.remainingMinutes, greaterThanOrEqualTo(33));
      });

      test('clamps to 0 when overtime', () {
        final longAgo = DateTime.now().subtract(const Duration(hours: 2));
        final session = TutorSession(
          id: id, studentId: studentId,
          subjectId: subjectId, topicId: topicId,
          topicTitle: topicTitle, startTime: longAgo,
          plannedDurationMinutes: 45,
        );
        expect(session.remainingMinutes, 0);
      });
    });

    group('isOverTime', () {
      test('returns false within duration', () {
        final recent = DateTime.now();
        final session = TutorSession(
          id: id, studentId: studentId,
          subjectId: subjectId, topicId: topicId,
          topicTitle: topicTitle, startTime: recent,
          plannedDurationMinutes: 60,
        );
        expect(session.isOverTime, isFalse);
      });

      test('returns true when over duration', () {
        final longAgo = DateTime.now().subtract(const Duration(hours: 2));
        final session = TutorSession(
          id: id, studentId: studentId,
          subjectId: subjectId, topicId: topicId,
          topicTitle: topicTitle, startTime: longAgo,
          plannedDurationMinutes: 45,
        );
        expect(session.isOverTime, isTrue);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final endTime = DateTime(2026, 5, 16, 11, 0);
        final session = TutorSession(
          id: id, studentId: studentId,
          subjectId: subjectId, topicId: topicId,
          topicTitle: topicTitle, startTime: startTime,
          status: SessionStatus.inProgress, endTime: endTime,
          plannedDurationMinutes: 30, lessonPlanJson: '{"title": "Algebra"}',
          questionsAsked: 5, questionsCorrect: 4, confidenceRating: 3,
          tutorNotes: 'Notes', topicsCovered: ['Algebra'],
          totalMessages: 10, totalTokensUsed: 2000,
        );
        final json = session.toJson();
        expect(json['id'], id);
        expect(json['status'], 'inProgress');
        expect(json['startTime'], startTime.toIso8601String());
        expect(json['endTime'], endTime.toIso8601String());
        expect(json['plannedDurationMinutes'], 30);
        expect(json['questionsAsked'], 5);
        expect(json['totalTokensUsed'], 2000);
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'id': id, 'studentId': studentId,
          'subjectId': subjectId, 'topicId': topicId,
          'topicTitle': topicTitle,
          'status': 'completed',
          'startTime': startTime.toIso8601String(),
          'plannedDurationMinutes': 50,
          'lessonPlanJson': '{}',
          'questionsAsked': 8, 'questionsCorrect': 6,
          'confidenceRating': 4,
          'topicsCovered': ['Kinematics'],
          'totalMessages': 20, 'totalTokensUsed': 3000,
        };
        final session = TutorSession.fromJson(json);
        expect(session.status, SessionStatus.completed);
        expect(session.plannedDurationMinutes, 50);
        expect(session.questionsCorrect, 6);
        expect(session.confidenceRating, 4);
        expect(session.totalMessages, 20);
      });

      test('handles missing optional fields', () {
        final json = {
          'id': id, 'studentId': studentId,
          'subjectId': subjectId, 'topicId': topicId,
          'topicTitle': topicTitle, 'status': 'planned',
          'startTime': startTime.toIso8601String(),
        };
        final session = TutorSession.fromJson(json);
        expect(session.endTime, isNull);
        expect(session.plannedDurationMinutes, 45);
        expect(session.questionsAsked, 0);
        expect(session.questionsCorrect, 0);
        expect(session.tutorNotes, isNull);
        expect(session.topicsCovered, []);
        expect(session.totalMessages, 0);
        expect(session.totalTokensUsed, 0);
      });
    });

    group('serialization roundtrip', () {
      test('preserves all fields', () {
        final endTime = DateTime(2026, 5, 16, 11, 0);
        final original = TutorSession(
          id: id, studentId: studentId,
          subjectId: subjectId, topicId: topicId,
          topicTitle: topicTitle, startTime: startTime,
          status: SessionStatus.completed, endTime: endTime,
          questionsAsked: 15, questionsCorrect: 12,
          totalMessages: 30,
        );
        final restored = TutorSession.fromJson(original.toJson());
        expect(restored.id, original.id);
        expect(restored.status, original.status);
        expect(restored.questionsCorrect, original.questionsCorrect);
        expect(restored.totalMessages, original.totalMessages);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final session = TutorSession(
          id: id, studentId: studentId,
          subjectId: subjectId, topicId: topicId,
          topicTitle: topicTitle, startTime: startTime,
        );
        final copy = session.copyWith();
        expect(copy.id, session.id);
        expect(copy.status, session.status);
      });

      test('updates specified fields', () {
        final session = TutorSession(
          id: id, studentId: studentId,
          subjectId: subjectId, topicId: topicId,
          topicTitle: topicTitle, startTime: startTime,
        );
        final copy = session.copyWith(
          status: SessionStatus.inProgress, questionsAsked: 5,
          tutorNotes: 'Going well',
        );
        expect(copy.status, SessionStatus.inProgress);
        expect(copy.questionsAsked, 5);
        expect(copy.tutorNotes, 'Going well');
      });
    });

    group('equality', () {
      test('identical instances are equal', () {
        final a = TutorSession(
          id: id, studentId: studentId,
          subjectId: subjectId, topicId: topicId,
          topicTitle: topicTitle, startTime: startTime,
        );
        expect(a == a, isTrue);
      });

      test('different instances are not equal', () {
        final a = TutorSession(
          id: id, studentId: studentId,
          subjectId: subjectId, topicId: topicId,
          topicTitle: topicTitle, startTime: startTime,
        );
        final b = TutorSession(
          id: 'other', studentId: studentId,
          subjectId: subjectId, topicId: topicId,
          topicTitle: topicTitle, startTime: startTime,
        );
        expect(a == b, isFalse);
      });

      test('hashCode is consistent', () {
        final a = TutorSession(
          id: id, studentId: studentId,
          subjectId: subjectId, topicId: topicId,
          topicTitle: topicTitle, startTime: startTime,
        );
        expect(a.hashCode, a.hashCode);
      });
    });
  });

  group('SessionStatus enum', () {
    test('has correct values in order', () {
      expect(SessionStatus.values, [
        SessionStatus.planned,
        SessionStatus.inProgress,
        SessionStatus.completed,
        SessionStatus.cancelled,
      ]);
    });
  });
}
