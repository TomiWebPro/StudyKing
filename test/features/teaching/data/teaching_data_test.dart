import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/teaching/data/teaching_data.dart';

void main() {
  group('teaching_data barrel', () {
    test('ConversationMessage can be constructed with required fields', () {
      final msg = ConversationMessage(
        id: 'm1',
        sessionId: 's1',
        role: MessageRole.tutor,
        type: MessageType.text,
        content: 'Hello student',
        timestamp: DateTime(2026, 5, 19),
      );
      expect(msg.id, 'm1');
      expect(msg.role, MessageRole.tutor);
      expect(msg.type, MessageType.text);
      expect(msg.content, 'Hello student');
      expect(msg.tokenCount, 0);
    });

    test('ConversationMessage supports copyWith', () {
      final msg = ConversationMessage(
        id: 'm1',
        sessionId: 's1',
        role: MessageRole.student,
        type: MessageType.text,
        content: 'Original',
        timestamp: DateTime(2026, 5, 19),
      );
      final copied = msg.copyWith(content: 'Updated', role: MessageRole.tutor);
      expect(copied.content, 'Updated');
      expect(copied.role, MessageRole.tutor);
      expect(copied.id, 'm1');
    });

    test('TutorSession can be constructed with required fields', () {
      final session = TutorSession(
        id: 'ts1',
        studentId: 's1',
        subjectId: 'sub1',
        topicId: 't1',
        topicTitle: 'Algebra',
        startTime: DateTime(2026, 5, 19),
      );
      expect(session.id, 'ts1');
      expect(session.studentId, 's1');
      expect(session.topicTitle, 'Algebra');
      expect(session.status, SessionStatus.planned);
      expect(session.plannedDurationMinutes, 45);
    });

    test('TutorSession.accuracy returns correct ratio', () {
      final session = TutorSession(
        id: 'ts1',
        studentId: 's1',
        subjectId: 'sub1',
        topicId: 't1',
        topicTitle: 'Algebra',
        startTime: DateTime(2026, 5, 19),
        questionsAsked: 10,
        questionsCorrect: 8,
      );
      expect(session.accuracy, 0.8);
    });

    test('TutorSession.accuracy returns 0 when no questions asked', () {
      final session = TutorSession(
        id: 'ts2',
        studentId: 's1',
        subjectId: 'sub1',
        topicId: 't1',
        topicTitle: 'Physics',
        startTime: DateTime(2026, 5, 19),
      );
      expect(session.accuracy, 0.0);
    });

    test('registerTeachingAdapters can be called without throwing', () {
      expect(() => registerTeachingAdapters(), returnsNormally);
    });
  });
}
