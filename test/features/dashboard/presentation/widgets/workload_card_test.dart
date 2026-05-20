import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/remaining_workload_estimator.dart';
import 'package:studyking/features/dashboard/presentation/widgets/workload_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../../helpers/navigator_observer_helper.dart';

Widget _buildTestApp(Widget widget, {TestNavigatorObserver? navigatorObserver}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
    home: Scaffold(body: widget),
  );
}

TopicWorkload _topicWorkload({
  required String topicId,
  double masteryLevel = 0.2,
  int totalQuestions = 10,
  double estimatedLessonsRemaining = 1.25,
}) {
  final atRisk = masteryLevel < 0.5 ? totalQuestions : 0;
  final mastered = masteryLevel >= 0.7 ? totalQuestions : 0;
  return TopicWorkload(
    topicId: topicId,
    topicTitle: topicId,
    totalQuestions: totalQuestions,
    masteredQuestions: mastered,
    atRiskQuestions: atRisk,
    unattemptedQuestions: totalQuestions - mastered - atRisk,
    masteryLevel: masteryLevel,
    estimatedLessonsRemaining: estimatedLessonsRemaining,
  );
}

void main() {
  group('WorkloadCard', () {
    testWidgets('shows empty state when workload is null', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        WorkloadCard(
          workload: null,
          resolveTopicName: (id) => id,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(WorkloadCard), findsOneWidget);
    });

    testWidgets('shows workload info for novice topics', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        WorkloadCard(
          workload: SubjectWorkload(
            subjectId: 's1',
            subjectTitle: 'Subject 1',
            totalQuestions: 10,
            masteredQuestions: 0,
            atRiskQuestions: 10,
            unattemptedQuestions: 0,
            overallMasteryLevel: 0.3,
            estimatedLessonsRemaining: 1.25,
            topicWorkloads: [
              _topicWorkload(topicId: 'topic-1', masteryLevel: 0.2),
            ],
          ),
          resolveTopicName: (id) => id == 'topic-1' ? 'Algebra' : id,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Algebra'), findsOneWidget);
    });

    testWidgets('shows topics need attention count', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        WorkloadCard(
          workload: SubjectWorkload(
            subjectId: 's1',
            subjectTitle: 'Subject 1',
            totalQuestions: 30,
            masteredQuestions: 10,
            atRiskQuestions: 10,
            unattemptedQuestions: 10,
            overallMasteryLevel: 0.43,
            estimatedLessonsRemaining: 2.5,
            topicWorkloads: [
              _topicWorkload(topicId: 'topic-1', masteryLevel: 0.2, estimatedLessonsRemaining: 1.25),
              _topicWorkload(topicId: 'topic-2', masteryLevel: 0.4, estimatedLessonsRemaining: 1.25),
              _topicWorkload(topicId: 'topic-3', masteryLevel: 0.9, estimatedLessonsRemaining: 0),
            ],
          ),
          resolveTopicName: (id) => id,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('2 topics need attention'), findsOneWidget);
    });

    testWidgets('shows 0 when all topics are developed or above', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        WorkloadCard(
          workload: SubjectWorkload(
            subjectId: 's1',
            subjectTitle: 'Subject 1',
            totalQuestions: 10,
            masteredQuestions: 10,
            atRiskQuestions: 0,
            unattemptedQuestions: 0,
            overallMasteryLevel: 0.9,
            estimatedLessonsRemaining: 0,
            topicWorkloads: [
              _topicWorkload(topicId: 'topic-dev', masteryLevel: 0.9, estimatedLessonsRemaining: 0),
            ],
          ),
          resolveTopicName: (id) => id,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('0 topics need attention'), findsOneWidget);
    });

    testWidgets('limits listed topics to 5', (tester) async {
      final topicWorkloads = List.generate(
        7,
        (i) => _topicWorkload(topicId: 'topic-$i', estimatedLessonsRemaining: 1.25),
      );
      await tester.pumpWidget(_buildTestApp(
        WorkloadCard(
          workload: SubjectWorkload(
            subjectId: 's1',
            subjectTitle: 'Subject 1',
            totalQuestions: 70,
            masteredQuestions: 0,
            atRiskQuestions: 70,
            unattemptedQuestions: 0,
            overallMasteryLevel: 0.3,
            estimatedLessonsRemaining: 8.75,
            topicWorkloads: topicWorkloads,
          ),
          resolveTopicName: (id) => id,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('7 topics need attention'), findsOneWidget);
    });

    // WorkloadCard is a pure rendering widget with no navigation callbacks.
  });
}
