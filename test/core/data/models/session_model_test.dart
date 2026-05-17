import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';

void main() {
  group('SessionType', () {
    test('has expected values', () {
      expect(SessionType.values, [
        SessionType.practice,
        SessionType.focus,
        SessionType.tutoring,
        SessionType.manual,
      ]);
    });
  });

  group('SessionStatus', () {
    test('has expected values', () {
      expect(SessionStatus.values, [
        SessionStatus.planned,
        SessionStatus.inProgress,
        SessionStatus.completed,
        SessionStatus.cancelled,
      ]);
    });
  });

  group('TutorMetadata', () {
    group('constructor', () {
      test('creates with default values', () {
        final meta = const TutorMetadata();
        expect(meta.topicTitle, isNull);
        expect(meta.lessonPlanJson, isNull);
        expect(meta.confidenceRating, 0);
        expect(meta.tutorNotes, isNull);
        expect(meta.topicsCovered, []);
        expect(meta.totalMessages, 0);
        expect(meta.totalTokensUsed, 0);
      });

      test('creates with all values', () {
        final meta = const TutorMetadata(
          topicTitle: 'Algebra',
          lessonPlanJson: '{"steps": []}',
          confidenceRating: 4,
          tutorNotes: 'Good progress',
          topicsCovered: ['Linear equations', 'Quadratic'],
          totalMessages: 15,
          totalTokensUsed: 2500,
        );
        expect(meta.topicTitle, 'Algebra');
        expect(meta.lessonPlanJson, '{"steps": []}');
        expect(meta.confidenceRating, 4);
        expect(meta.tutorNotes, 'Good progress');
        expect(meta.topicsCovered, ['Linear equations', 'Quadratic']);
        expect(meta.totalMessages, 15);
        expect(meta.totalTokensUsed, 2500);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final meta = const TutorMetadata(
          topicTitle: 'Algebra',
          lessonPlanJson: '{}',
          confidenceRating: 3,
          tutorNotes: 'Notes',
          topicsCovered: ['Topic1'],
          totalMessages: 5,
          totalTokensUsed: 100,
        );
        final json = meta.toJson();
        expect(json['topicTitle'], 'Algebra');
        expect(json['lessonPlanJson'], '{}');
        expect(json['confidenceRating'], 3);
        expect(json['tutorNotes'], 'Notes');
        expect(json['topicsCovered'], ['Topic1']);
        expect(json['totalMessages'], 5);
        expect(json['totalTokensUsed'], 100);
      });

      test('serializes null fields as null', () {
        final meta = const TutorMetadata();
        final json = meta.toJson();
        expect(json['topicTitle'], isNull);
        expect(json['lessonPlanJson'], isNull);
        expect(json['tutorNotes'], isNull);
        expect(json['topicsCovered'], []);
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'topicTitle': 'Algebra',
          'lessonPlanJson': '{}',
          'confidenceRating': 3,
          'tutorNotes': 'Notes',
          'topicsCovered': ['Topic1'],
          'totalMessages': 5,
          'totalTokensUsed': 100,
        };
        final meta = TutorMetadata.fromJson(json);
        expect(meta.topicTitle, 'Algebra');
        expect(meta.lessonPlanJson, '{}');
        expect(meta.confidenceRating, 3);
        expect(meta.tutorNotes, 'Notes');
        expect(meta.topicsCovered, ['Topic1']);
        expect(meta.totalMessages, 5);
        expect(meta.totalTokensUsed, 100);
      });

      test('deserializes with missing fields using defaults', () {
        final json = <String, dynamic>{};
        final meta = TutorMetadata.fromJson(json);
        expect(meta.topicTitle, isNull);
        expect(meta.lessonPlanJson, isNull);
        expect(meta.confidenceRating, 0);
        expect(meta.tutorNotes, isNull);
        expect(meta.topicsCovered, []);
        expect(meta.totalMessages, 0);
        expect(meta.totalTokensUsed, 0);
      });

      test('deserializes with null topicsCovered', () {
        final json = {
          'topicsCovered': null,
        };
        final meta = TutorMetadata.fromJson(json);
        expect(meta.topicsCovered, []);
      });

      test('deserializes with null confidenceRating defaults to 0', () {
        final json = {
          'confidenceRating': null,
        };
        final meta = TutorMetadata.fromJson(json);
        expect(meta.confidenceRating, 0);
      });

      test('deserializes with null totalMessages defaults to 0', () {
        final json = {
          'totalMessages': null,
        };
        final meta = TutorMetadata.fromJson(json);
        expect(meta.totalMessages, 0);
      });

      test('deserializes with null totalTokensUsed defaults to 0', () {
        final json = {
          'totalTokensUsed': null,
        };
        final meta = TutorMetadata.fromJson(json);
        expect(meta.totalTokensUsed, 0);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        const meta = TutorMetadata(
          topicTitle: 'Title',
          lessonPlanJson: '{}',
          confidenceRating: 4,
          tutorNotes: 'Notes',
          topicsCovered: ['T1'],
          totalMessages: 10,
          totalTokensUsed: 500,
        );
        final copy = meta.copyWith();
        expect(copy.topicTitle, meta.topicTitle);
        expect(copy.lessonPlanJson, meta.lessonPlanJson);
        expect(copy.confidenceRating, meta.confidenceRating);
        expect(copy.tutorNotes, meta.tutorNotes);
        expect(copy.topicsCovered, meta.topicsCovered);
        expect(copy.totalMessages, meta.totalMessages);
        expect(copy.totalTokensUsed, meta.totalTokensUsed);
      });

      test('updates specified fields', () {
        const meta = TutorMetadata();
        final copy = meta.copyWith(
          topicTitle: 'New title',
          confidenceRating: 5,
          totalMessages: 20,
        );
        expect(copy.topicTitle, 'New title');
        expect(copy.confidenceRating, 5);
        expect(copy.totalMessages, 20);
      });

      test('clearTopicTitle sets topicTitle to null', () {
        const meta = TutorMetadata(topicTitle: 'Title');
        final copy = meta.copyWith(clearTopicTitle: true);
        expect(copy.topicTitle, isNull);
      });

      test('clearLessonPlan sets lessonPlanJson to null', () {
        const meta = TutorMetadata(lessonPlanJson: '{}');
        final copy = meta.copyWith(clearLessonPlan: true);
        expect(copy.lessonPlanJson, isNull);
      });

      test('clearTutorNotes sets tutorNotes to null', () {
        const meta = TutorMetadata(tutorNotes: 'Notes');
        final copy = meta.copyWith(clearTutorNotes: true);
        expect(copy.tutorNotes, isNull);
      });

      test('preserves fields when null passed without clear flag', () {
        const meta = TutorMetadata(
          topicTitle: 'Title',
          lessonPlanJson: '{}',
          tutorNotes: 'Notes',
        );
        final copy = meta.copyWith(
          topicTitle: null,
          lessonPlanJson: null,
          tutorNotes: null,
        );
        expect(copy.topicTitle, 'Title');
        expect(copy.lessonPlanJson, '{}');
        expect(copy.tutorNotes, 'Notes');
      });
    });

    group('equality', () {
      test('same values are equal', () {
        const a = TutorMetadata(topicTitle: 'T', confidenceRating: 3);
        const b = TutorMetadata(topicTitle: 'T', confidenceRating: 3);
        expect(a == b, isTrue);
      });

      test('different values are not equal', () {
        const a = TutorMetadata(topicTitle: 'T');
        const b = TutorMetadata(topicTitle: 'Different');
        expect(a == b, isFalse);
      });

      test('identical instances are equal', () {
        const a = TutorMetadata();
        expect(a == a, isTrue);
      });

      test('different runtime types are not equal', () {
        const a = TutorMetadata();
        expect(a == Object(), isFalse);
      });

      test('hashCode is consistent', () {
        const a = TutorMetadata(topicTitle: 'T', confidenceRating: 3);
        const b = TutorMetadata(topicTitle: 'T', confidenceRating: 3);
        expect(a.hashCode, b.hashCode);
      });

      test('hashCode differs for different values', () {
        final a = TutorMetadata(topicTitle: 'A', totalMessages: 1);
        final b = TutorMetadata(topicTitle: 'B', totalMessages: 2);
        expect(a.hashCode, isNot(b.hashCode));
      });

      test('== compares all fields for non-identical instances', () {
        final a = TutorMetadata(
          topicTitle: 'T',
          lessonPlanJson: '{}',
          tutorNotes: 'N',
        );
        final b = TutorMetadata(
          topicTitle: 'T',
          lessonPlanJson: '{}',
          tutorNotes: 'N',
        );
        expect(identical(a, b), isFalse);
        expect(a == b, isTrue);
        expect(a.hashCode, b.hashCode);
      });

      test('== detects differing topicTitle', () {
        final a = TutorMetadata(topicTitle: 'A');
        final b = TutorMetadata(topicTitle: 'B');
        expect(a == b, isFalse);
      });

      test('== detects differing confidenceRating', () {
        final a = TutorMetadata(confidenceRating: 1);
        final b = TutorMetadata(confidenceRating: 2);
        expect(a == b, isFalse);
      });

      test('== detects differing lessonPlanJson', () {
        final a = TutorMetadata(lessonPlanJson: '{"a":1}');
        final b = TutorMetadata(lessonPlanJson: '{"b":2}');
        expect(a == b, isFalse);
      });

      test('== detects differing tutorNotes', () {
        final a = TutorMetadata(tutorNotes: 'Good');
        final b = TutorMetadata(tutorNotes: 'Bad');
        expect(a == b, isFalse);
      });

      test('== detects differing topicsCovered length', () {
        final a = TutorMetadata(topicsCovered: ['A']);
        final b = TutorMetadata(topicsCovered: ['A', 'B']);
        expect(a == b, isFalse);
      });

      test('== detects differing totalMessages', () {
        final a = TutorMetadata(totalMessages: 1);
        final b = TutorMetadata(totalMessages: 2);
        expect(a == b, isFalse);
      });

      test('== detects differing totalTokensUsed', () {
        final a = TutorMetadata(totalTokensUsed: 100);
        final b = TutorMetadata(totalTokensUsed: 200);
        expect(a == b, isFalse);
      });
    });

    group('serialization roundtrip', () {
      test('toJson then fromJson preserves data', () {
        const original = TutorMetadata(
          topicTitle: 'Algebra',
          lessonPlanJson: '{}',
          confidenceRating: 4,
          tutorNotes: 'Good',
          topicsCovered: ['T1', 'T2'],
          totalMessages: 10,
          totalTokensUsed: 500,
        );
        final json = original.toJson();
        final restored = TutorMetadata.fromJson(json);
        expect(restored.topicTitle, original.topicTitle);
        expect(restored.lessonPlanJson, original.lessonPlanJson);
        expect(restored.confidenceRating, original.confidenceRating);
        expect(restored.tutorNotes, original.tutorNotes);
        expect(restored.topicsCovered, original.topicsCovered);
        expect(restored.totalMessages, original.totalMessages);
        expect(restored.totalTokensUsed, original.totalTokensUsed);
      });

      test('fromJson then toJson preserves data', () {
        final json = {
          'topicTitle': 'Geometry',
          'lessonPlanJson': '{"plan": true}',
          'confidenceRating': 2,
          'tutorNotes': 'Needs improvement',
          'topicsCovered': ['Angles'],
          'totalMessages': 3,
          'totalTokensUsed': 150,
        };
        final meta = TutorMetadata.fromJson(json);
        final outputJson = meta.toJson();
        expect(outputJson['topicTitle'], 'Geometry');
        expect(outputJson['totalTokensUsed'], 150);
      });
    });
  });

  group('Session', () {
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 5, 12, 10, 0, 0);
    });

    group('constructor', () {
      test('creates with required fields', () {
        final session = Session(
          id: 'session-1',
          studentId: 'student-1',
          startTime: now,
        );
        expect(session.id, 'session-1');
        expect(session.studentId, 'student-1');
        expect(session.startTime, now);
        expect(session.type, SessionType.practice);
        expect(session.subjectId, isNull);
        expect(session.topicId, isNull);
        expect(session.endTime, isNull);
        expect(session.plannedDurationMinutes, isNull);
        expect(session.actualDurationMs, 0);
        expect(session.questionsAnswered, 0);
        expect(session.correctAnswers, 0);
        expect(session.completed, isFalse);
        expect(session.sourceId, isNull);
        expect(session.tags, isEmpty);
      });

      test('creates with all fields', () {
        final session = Session(
          id: 'session-1',
          studentId: 'student-1',
          subjectId: 'subject-1',
          topicId: 'topic-1',
          type: SessionType.tutoring,
          startTime: now,
          endTime: now.add(const Duration(hours: 1)),
          plannedDurationMinutes: 60,
          actualDurationMs: 3600000,
          questionsAnswered: 10,
          correctAnswers: 8,
          completed: true,
          sourceId: 'source-1',
          tags: ['important'],
          createdAt: now,
        );
        expect(session.subjectId, 'subject-1');
        expect(session.topicId, 'topic-1');
        expect(session.type, SessionType.tutoring);
        expect(session.endTime, now.add(const Duration(hours: 1)));
        expect(session.plannedDurationMinutes, 60);
        expect(session.actualDurationMs, 3600000);
        expect(session.questionsAnswered, 10);
        expect(session.correctAnswers, 8);
        expect(session.completed, isTrue);
        expect(session.sourceId, 'source-1');
        expect(session.tags, ['important']);
        expect(session.createdAt, now);
      });

      test('defaults createdAt to now', () {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final session = Session(
          id: 's1',
          studentId: 's1',
          startTime: now,
        );
        final after = DateTime.now().add(const Duration(seconds: 1));
        expect(session.createdAt.isAfter(before), isTrue);
        expect(session.createdAt.isBefore(after), isTrue);
      });

      test('creates with tutorSessionId', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          tutorSessionId: 'tutor-abc',
        );
        expect(session.tutorSessionId, 'tutor-abc');
      });

      test('creates with session status', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          status: SessionStatus.inProgress,
        );
        expect(session.status, SessionStatus.inProgress);
      });

      test('defaults status to planned', () {
        final session = Session(id: 's1', studentId: 's1', startTime: now);
        expect(session.status, SessionStatus.planned);
      });

      test('creates with tutorMetadata', () {
        final meta = const TutorMetadata(topicTitle: 'Algebra');
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          tutorMetadata: meta,
        );
        expect(session.tutorMetadata?.topicTitle, 'Algebra');
      });
    });

    group('isActive', () {
      test('returns true when not completed and no endTime', () {
        final session = Session(id: 's1', studentId: 's1', startTime: now);
        expect(session.isActive, isTrue);
      });

      test('returns false when completed', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          completed: true,
        );
        expect(session.isActive, isFalse);
      });

      test('returns false when endTime is set', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          endTime: now,
        );
        expect(session.isActive, isFalse);
      });

      test('returns false when both completed and endTime are set', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          completed: true,
          endTime: now,
        );
        expect(session.isActive, isFalse);
      });
    });

    group('actualDuration', () {
      test('returns Duration from actualDurationMs', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          actualDurationMs: 5000,
        );
        expect(session.actualDuration, const Duration(milliseconds: 5000));
      });
    });

    group('plannedDuration', () {
      test('returns Duration when plannedDurationMinutes set', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          plannedDurationMinutes: 45,
        );
        expect(session.plannedDuration, const Duration(minutes: 45));
      });

      test('returns null when plannedDurationMinutes is null', () {
        final session = Session(id: 's1', studentId: 's1', startTime: now);
        expect(session.plannedDuration, isNull);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final session = Session(
          id: 'session-1',
          studentId: 'student-1',
          subjectId: 'subject-1',
          topicId: 'topic-1',
          type: SessionType.tutoring,
          startTime: now,
          endTime: now.add(const Duration(hours: 1)),
          plannedDurationMinutes: 60,
          actualDurationMs: 3600000,
          questionsAnswered: 10,
          correctAnswers: 8,
          completed: true,
          sourceId: 'source-1',
          tags: ['important'],
          createdAt: now,
        );
        final json = session.toJson();
        expect(json['id'], 'session-1');
        expect(json['studentId'], 'student-1');
        expect(json['subjectId'], 'subject-1');
        expect(json['topicId'], 'topic-1');
        expect(json['type'], 'tutoring');
        expect(json['startTime'], now.toIso8601String());
        expect(json['endTime'], now.add(const Duration(hours: 1)).toIso8601String());
        expect(json['plannedDurationMinutes'], 60);
        expect(json['actualDurationMs'], 3600000);
        expect(json['questionsAnswered'], 10);
        expect(json['correctAnswers'], 8);
        expect(json['completed'], isTrue);
        expect(json['sourceId'], 'source-1');
        expect(json['tags'], ['important']);
        expect(json['createdAt'], now.toIso8601String());
      });

      test('serializes with null optionals', () {
        final session = Session(id: 's1', studentId: 's1', startTime: now);
        final json = session.toJson();
        expect(json['subjectId'], isNull);
        expect(json['topicId'], isNull);
        expect(json['endTime'], isNull);
        expect(json['plannedDurationMinutes'], isNull);
        expect(json['sourceId'], isNull);
        expect(json['tutorSessionId'], isNull);
        expect(json['sourceIds'], []);
        expect(json['lessonIds'], []);
      });

      test('serializes tutorSessionId and list fields', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          tutorSessionId: 'tutor-1',
          sourceIds: ['src-1', 'src-2'],
          lessonIds: ['lesson-1'],
        );
        final json = session.toJson();
        expect(json['tutorSessionId'], 'tutor-1');
        expect(json['sourceIds'], ['src-1', 'src-2']);
        expect(json['lessonIds'], ['lesson-1']);
      });

      test('serializes status field', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          status: SessionStatus.inProgress,
        );
        final json = session.toJson();
        expect(json['status'], 'inProgress');
      });

      test('serializes tutorMetadata field', () {
        final meta = const TutorMetadata(
          topicTitle: 'Algebra',
          totalMessages: 5,
        );
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          tutorMetadata: meta,
        );
        final json = session.toJson();
        expect(json['tutorMetadata'], isNotNull);
        expect(json['tutorMetadata']['topicTitle'], 'Algebra');
        expect(json['tutorMetadata']['totalMessages'], 5);
      });

      test('serializes tutorMetadata as null when not set', () {
        final session = Session(id: 's1', studentId: 's1', startTime: now);
        final json = session.toJson();
        expect(json['tutorMetadata'], isNull);
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'id': 'session-1',
          'studentId': 'student-1',
          'subjectId': 'subject-1',
          'topicId': 'topic-1',
          'type': 'tutoring',
          'startTime': now.toIso8601String(),
          'endTime': now.add(const Duration(hours: 1)).toIso8601String(),
          'plannedDurationMinutes': 60,
          'actualDurationMs': 3600000,
          'questionsAnswered': 10,
          'correctAnswers': 8,
          'completed': true,
          'sourceId': 'source-1',
          'tags': ['important'],
          'createdAt': now.toIso8601String(),
        };
        final session = Session.fromJson(json);
        expect(session.id, 'session-1');
        expect(session.studentId, 'student-1');
        expect(session.subjectId, 'subject-1');
        expect(session.type, SessionType.tutoring);
        expect(session.endTime, now.add(const Duration(hours: 1)));
        expect(session.plannedDurationMinutes, 60);
        expect(session.questionsAnswered, 10);
        expect(session.completed, isTrue);
        expect(session.tags, ['important']);
      });

      test('deserializes with missing optionals', () {
        final json = {
          'id': 'session-1',
          'studentId': 'student-1',
          'startTime': now.toIso8601String(),
        };
        final session = Session.fromJson(json);
        expect(session.subjectId, isNull);
        expect(session.topicId, isNull);
        expect(session.type, SessionType.practice);
        expect(session.endTime, isNull);
        expect(session.plannedDurationMinutes, isNull);
        expect(session.actualDurationMs, 0);
        expect(session.completed, isFalse);
        expect(session.tags, isEmpty);
      });

      test('handles null type defaults to practice', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
          'type': null,
        };
        final session = Session.fromJson(json);
        expect(session.type, SessionType.practice);
      });

      test('handles invalid type string defaults to practice', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
          'type': 'unknown_type',
        };
        final session = Session.fromJson(json);
        expect(session.type, SessionType.practice);
      });

      test('handles null tags defaults to empty list', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
          'tags': null,
        };
        final session = Session.fromJson(json);
        expect(session.tags, isEmpty);
      });

      test('handles all session types by name', () {
        for (final type in SessionType.values) {
          final json = {
            'id': 's1',
            'studentId': 's1',
            'startTime': now.toIso8601String(),
            'type': type.name,
          };
          final session = Session.fromJson(json);
          expect(session.type, type);
        }
      });

      test('throws on malformed startTime', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': 'not-a-date',
        };
        expect(() => Session.fromJson(json), throwsA(isA<FormatException>()));
      });

      test('handles null createdAt defaults to now', () {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
          'createdAt': null,
        };
        final session = Session.fromJson(json);
        final after = DateTime.now().add(const Duration(seconds: 1));
        expect(session.createdAt.isAfter(before), isTrue);
        expect(session.createdAt.isBefore(after), isTrue);
      });

      test('handles empty tags in JSON', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
          'tags': [],
        };
        final session = Session.fromJson(json);
        expect(session.tags, isEmpty);
      });

      test('handles missing tags key defaults to empty list', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
        };
        final session = Session.fromJson(json);
        expect(session.tags, isEmpty);
      });

      test('handles missing studentId defaults to empty string', () {
        final json = {
          'id': 's1',
          'startTime': now.toIso8601String(),
        };
        final session = Session.fromJson(json);
        expect(session.studentId, '');
      });

      test('deserializes all SessionType values by name', () {
        for (final type in SessionType.values) {
          final json = {
            'id': 's1',
            'studentId': 's1',
            'startTime': now.toIso8601String(),
            'type': type.name,
          };
          final session = Session.fromJson(json);
          expect(session.type, type);
        }
      });

      test('handles null actualDurationMs', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
          'actualDurationMs': null,
        };
        final session = Session.fromJson(json);
        expect(session.actualDurationMs, 0);
      });

      test('handles null questionsAnswered', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
          'questionsAnswered': null,
        };
        final session = Session.fromJson(json);
        expect(session.questionsAnswered, 0);
      });

      test('handles null correctAnswers', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
          'correctAnswers': null,
        };
        final session = Session.fromJson(json);
        expect(session.correctAnswers, 0);
      });

      test('handles null completed', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
          'completed': null,
        };
        final session = Session.fromJson(json);
        expect(session.completed, isFalse);
      });

      test('handles null sourceIds defaults to empty list', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
          'sourceIds': null,
        };
        final session = Session.fromJson(json);
        expect(session.sourceIds, isEmpty);
      });

      test('handles null lessonIds defaults to empty list', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
          'lessonIds': null,
        };
        final session = Session.fromJson(json);
        expect(session.lessonIds, isEmpty);
      });

      test('handles missing sourceIds key defaults to empty list', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
        };
        final session = Session.fromJson(json);
        expect(session.sourceIds, isEmpty);
      });

      test('handles missing lessonIds key defaults to empty list', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
        };
        final session = Session.fromJson(json);
        expect(session.lessonIds, isEmpty);
      });

      test('deserializes status from name', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
          'status': 'completed',
        };
        final session = Session.fromJson(json);
        expect(session.status, SessionStatus.completed);
      });

      test('handles null status defaults to planned', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
          'status': null,
        };
        final session = Session.fromJson(json);
        expect(session.status, SessionStatus.planned);
      });

      test('handles invalid status string defaults to planned', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
          'status': 'invalid_status',
        };
        final session = Session.fromJson(json);
        expect(session.status, SessionStatus.planned);
      });

      test('deserializes all SessionStatus values by name', () {
        for (final status in SessionStatus.values) {
          final json = {
            'id': 's1',
            'studentId': 's1',
            'startTime': now.toIso8601String(),
            'status': status.name,
          };
          final session = Session.fromJson(json);
          expect(session.status, status);
        }
      });

      test('deserializes tutorMetadata from JSON', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
          'tutorMetadata': {
            'topicTitle': 'Algebra',
            'confidenceRating': 4,
            'totalMessages': 10,
          },
        };
        final session = Session.fromJson(json);
        expect(session.tutorMetadata, isNotNull);
        expect(session.tutorMetadata?.topicTitle, 'Algebra');
        expect(session.tutorMetadata?.confidenceRating, 4);
        expect(session.tutorMetadata?.totalMessages, 10);
      });

      test('handles null tutorMetadata', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
          'tutorMetadata': null,
        };
        final session = Session.fromJson(json);
        expect(session.tutorMetadata, isNull);
      });

      test('handles missing tutorMetadata key', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
        };
        final session = Session.fromJson(json);
        expect(session.tutorMetadata, isNull);
      });
    });

    group('serialization roundtrip', () {
      test('toJson then fromJson preserves data', () {
        final original = Session(
          id: 'session-1',
          studentId: 'student-1',
          subjectId: 'subject-1',
          topicId: 'topic-1',
          type: SessionType.tutoring,
          startTime: now,
          endTime: now.add(const Duration(hours: 1)),
          plannedDurationMinutes: 60,
          actualDurationMs: 3600000,
          questionsAnswered: 10,
          correctAnswers: 8,
          completed: true,
          sourceId: 'source-1',
          tags: ['important'],
          createdAt: now,
        );
        final json = original.toJson();
        final restored = Session.fromJson(json);
        expect(restored.id, original.id);
        expect(restored.studentId, original.studentId);
        expect(restored.type, original.type);
        expect(restored.startTime, original.startTime);
        expect(restored.questionsAnswered, original.questionsAnswered);
        expect(restored.correctAnswers, original.correctAnswers);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          subjectId: 'sub', topicId: 'topic',
          type: SessionType.tutoring, endTime: now,
          plannedDurationMinutes: 45, actualDurationMs: 1000,
          questionsAnswered: 5, correctAnswers: 4, completed: true,
          sourceId: 'src', tags: ['tag'], createdAt: now,
        );
        final copy = session.copyWith();
        expect(copy.id, session.id);
        expect(copy.studentId, session.studentId);
        expect(copy.subjectId, session.subjectId);
        expect(copy.topicId, session.topicId);
        expect(copy.type, session.type);
        expect(copy.startTime, session.startTime);
        expect(copy.endTime, session.endTime);
        expect(copy.plannedDurationMinutes, session.plannedDurationMinutes);
        expect(copy.actualDurationMs, session.actualDurationMs);
        expect(copy.questionsAnswered, session.questionsAnswered);
        expect(copy.correctAnswers, session.correctAnswers);
        expect(copy.completed, session.completed);
        expect(copy.sourceId, session.sourceId);
        expect(copy.tags, session.tags);
        expect(copy.createdAt, session.createdAt);
      });

      test('updates specified fields', () {
        final session = Session(id: 's1', studentId: 's1', startTime: now);
        final copy = session.copyWith(
          completed: true,
          questionsAnswered: 10,
          correctAnswers: 8,
        );
        expect(copy.completed, isTrue);
        expect(copy.questionsAnswered, 10);
        expect(copy.correctAnswers, 8);
        expect(copy.id, 's1');
      });

      test('updates type and startTime', () {
        final session = Session(id: 's1', studentId: 's1', startTime: now);
        final later = now.add(const Duration(hours: 2));
        final copy = session.copyWith(
          type: SessionType.focus,
          startTime: later,
        );
        expect(copy.type, SessionType.focus);
        expect(copy.startTime, later);
      });

      test('updates endTime without clear flag', () {
        final session = Session(id: 's1', studentId: 's1', startTime: now);
        final end = now.add(const Duration(hours: 1));
        final copy = session.copyWith(endTime: end);
        expect(copy.endTime, end);
      });

      test('updates actualDurationMs and tags', () {
        final session = Session(id: 's1', studentId: 's1', startTime: now);
        final copy = session.copyWith(
          actualDurationMs: 5000,
          tags: ['a', 'b'],
        );
        expect(copy.actualDurationMs, 5000);
        expect(copy.tags, ['a', 'b']);
      });

      test('updates createdAt', () {
        final session = Session(id: 's1', studentId: 's1', startTime: now);
        final later = DateTime(2026, 6, 1);
        final copy = session.copyWith(createdAt: later);
        expect(copy.createdAt, later);
      });

      test('clearEndTime sets endTime to null', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          endTime: now,
        );
        final copy = session.copyWith(clearEndTime: true);
        expect(copy.endTime, isNull);
      });

      test('clearSubjectId sets subjectId to null', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          subjectId: 'sub',
        );
        final copy = session.copyWith(clearSubjectId: true);
        expect(copy.subjectId, isNull);
      });

      test('clearTopicId sets topicId to null', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          topicId: 'topic',
        );
        final copy = session.copyWith(clearTopicId: true);
        expect(copy.topicId, isNull);
      });

      test('clearSourceId sets sourceId to null', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          sourceId: 'src',
        );
        final copy = session.copyWith(clearSourceId: true);
        expect(copy.sourceId, isNull);
      });

      test('clearTutorSessionId sets tutorSessionId to null', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          tutorSessionId: 'tutor-1',
        );
        final copy = session.copyWith(clearTutorSessionId: true);
        expect(copy.tutorSessionId, isNull);
      });

      test('preserves tutorSessionId when null passed without clear flag', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          tutorSessionId: 'tutor-1',
        );
        final copy = session.copyWith(tutorSessionId: null);
        expect(copy.tutorSessionId, 'tutor-1');
      });

      test('clearPlannedDuration sets plannedDurationMinutes to null', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          plannedDurationMinutes: 45,
        );
        final copy = session.copyWith(clearPlannedDuration: true);
        expect(copy.plannedDurationMinutes, isNull);
      });

      test('preserves subjectId when null passed without clear flag', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          subjectId: 'sub',
        );
        final copy = session.copyWith(subjectId: null);
        expect(copy.subjectId, 'sub');
      });

      test('preserves topicId when null passed without clear flag', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          topicId: 'topic',
        );
        final copy = session.copyWith(topicId: null);
        expect(copy.topicId, 'topic');
      });

      test('preserves sourceId when null passed without clear flag', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          sourceId: 'src',
        );
        final copy = session.copyWith(sourceId: null);
        expect(copy.sourceId, 'src');
      });

      test('preserves plannedDurationMinutes when null passed without clear flag', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          plannedDurationMinutes: 45,
        );
        final copy = session.copyWith(plannedDurationMinutes: null);
        expect(copy.plannedDurationMinutes, 45);
      });

      test('preserves endTime when null passed without clear flag', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          endTime: now,
        );
        final copy = session.copyWith(endTime: null);
        expect(copy.endTime, now);
      });

      test('updates tutorMetadata', () {
        final meta = const TutorMetadata(topicTitle: 'Algebra');
        final session = Session(id: 's1', studentId: 's1', startTime: now);
        final copy = session.copyWith(tutorMetadata: meta);
        expect(copy.tutorMetadata?.topicTitle, 'Algebra');
      });

      test('clearTutorMetadata sets tutorMetadata to null', () {
        final meta = const TutorMetadata(topicTitle: 'Algebra');
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          tutorMetadata: meta,
        );
        final copy = session.copyWith(clearTutorMetadata: true);
        expect(copy.tutorMetadata, isNull);
      });

      test('preserves tutorMetadata when null passed without clear flag', () {
        final meta = const TutorMetadata(topicTitle: 'Algebra');
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          tutorMetadata: meta,
        );
        final copy = session.copyWith(tutorMetadata: null);
        expect(copy.tutorMetadata?.topicTitle, 'Algebra');
      });

      test('updates status', () {
        final session = Session(id: 's1', studentId: 's1', startTime: now);
        final copy = session.copyWith(status: SessionStatus.completed);
        expect(copy.status, SessionStatus.completed);
      });

      test('updates tutorSessionId', () {
        final session = Session(id: 's1', studentId: 's1', startTime: now);
        final copy = session.copyWith(tutorSessionId: 'tutor-new');
        expect(copy.tutorSessionId, 'tutor-new');
      });
    });

    group('equality', () {
      test('uses id-based equality', () {
        final a = Session(id: 's1', studentId: 's1', startTime: now);
        final b = Session(id: 's2', studentId: 's2', startTime: now);
        expect(a == b, isFalse);
        expect(a == a, isTrue);
      });

      test('equal when same id', () {
        final a = Session(id: 's1', studentId: 's1', startTime: now);
        final b = Session(id: 's1', studentId: 's2', startTime: now);
        expect(a == b, isTrue);
      });

      test('hashCode is id-based', () {
        final a = Session(id: 's1', studentId: 's1', startTime: now);
        final b = Session(id: 's1', studentId: 's2', startTime: now);
        expect(a.hashCode, b.hashCode);
      });

      test('hashCode is consistent', () {
        final obj = Session(id: 's1', studentId: 's1', startTime: now);
        final hash = obj.hashCode;
        expect(obj.hashCode, hash);
      });
    });

    group('toString', () {
      test('includes class name', () {
        final obj = Session(id: 's1', studentId: 's1', startTime: now);
        expect(obj.toString(), contains('Session'));
      });
    });
  });
}
