import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/widgets/practice_performance_card.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_model.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_type.dart';

Widget _buildTestApp(Widget widget) {
  return MaterialApp(
    home: Scaffold(body: widget),
    localizationsDelegates: const [],
  );
}

FocusSession _createSession({
  double accuracy = 0.85,
  int questionsAnswered = 20,
  int correctAnswers = 17,
  Map<String, TopicPerformance> topicBreakdown = const {},
}) {
  return FocusSession(
    id: 'session-1',
    studentId: 'student-1',
    startTime: DateTime(2025, 1, 15, 10, 0),
    durationMinutes: 30,
    questionsAnswered: questionsAnswered,
    correctAnswers: correctAnswers,
    accuracy: accuracy,
    sessionType: FocusSessionType.spacedRepetition,
    topicBreakdown: topicBreakdown,
  );
}

void main() {
  testWidgets('renders practice performance card with session data', (tester) async {
    await tester.pumpWidget(_buildTestApp(
      PracticePerformanceCard(session: _createSession()),
    ));

    expect(find.text('17/20'), findsOneWidget);
    expect(find.text('20'), findsWidgets);
  });

  testWidgets('renders in compact mode', (tester) async {
    await tester.pumpWidget(_buildTestApp(
      PracticePerformanceCard(session: _createSession(), compact: true),
    ));

    expect(find.text('20'), findsWidgets);
    expect(find.text('17/20'), findsOneWidget);
  });

  testWidgets('renders topic breakdown when present', (tester) async {
    final topicBreakdown = {
      'topic-1': TopicPerformance(
        topicId: 'topic-1', correct: 10, total: 10,
        accuracyPercent: 100.0, masteryDelta: 0.05,
      ),
      'topic-2': TopicPerformance(
        topicId: 'topic-2', correct: 7, total: 10,
        accuracyPercent: 70.0, masteryDelta: -0.02,
      ),
    };

    await tester.pumpWidget(_buildTestApp(
      PracticePerformanceCard(session: _createSession(topicBreakdown: topicBreakdown)),
    ));
  });

  testWidgets('compact mode hides mastery changes', (tester) async {
    final session = FocusSession(
      id: 'session-1',
      studentId: 'student-1',
      startTime: DateTime(2025, 1, 15, 10, 0),
      durationMinutes: 30,
      questionsAnswered: 20,
      correctAnswers: 17,
      accuracy: 0.85,
      masteryChanges: {'physics': 0.05},
      sessionType: FocusSessionType.spacedRepetition,
    );

    await tester.pumpWidget(_buildTestApp(
      PracticePerformanceCard(session: session, compact: true),
    ));
  });
}
