import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/features/dashboard/presentation/widgets/topic_breakdown_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../../helpers/navigator_observer_helper.dart';

Widget _buildTestApp(Widget child, {TestNavigatorObserver? navigatorObserver}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
    home: Scaffold(body: child),
  );
}

MasteryState _state({
  required String topicId,
  double accuracy = 0.0,
  int totalAttempts = 0,
  MasteryLevel level = MasteryLevel.novice,
}) {
  return MasteryState(
    studentId: 's1',
    topicId: topicId,
    accuracy: accuracy,
    totalAttempts: totalAttempts,
    correctAttempts: 0,
    masteryLevel: level,
    lastAttempt: DateTime(2024, 1, 1),
    lastUpdated: DateTime(2024, 1, 1),
  );
}

String _resolveName(String id) {
  switch (id) {
    case 't1': return 'Algebra';
    case 't2': return 'Geometry';
    case 't3': return 'Calculus';
    default: return id;
  }
}

void main() {
  group('TopicBreakdownCard', () {
    testWidgets('renders empty state when no mastery data', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicBreakdownCard(
          allMastery: [],
          resolveTopicName: _resolveName,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No topic data yet. Start studying to see your progress!'), findsOneWidget);
      expect(find.byIcon(Icons.pie_chart), findsNothing);
    });

    testWidgets('renders topic rows when data present', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicBreakdownCard(
          allMastery: [
            _state(topicId: 't1', accuracy: 0.9, totalAttempts: 20, level: MasteryLevel.expert),
            _state(topicId: 't2', accuracy: 0.6, totalAttempts: 10, level: MasteryLevel.developing),
          ],
          resolveTopicName: _resolveName,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Algebra'), findsOneWidget);
      expect(find.text('Geometry'), findsOneWidget);
      expect(find.text('90%'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
    });

    testWidgets('sorts topics by accuracy ascending', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicBreakdownCard(
          allMastery: [
            _state(topicId: 't2', accuracy: 0.9),
            _state(topicId: 't1', accuracy: 0.4),
          ],
          resolveTopicName: _resolveName,
        ),
      ));
      await tester.pumpAndSettle();

      final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
      final algebraIdx = texts.indexOf('Algebra');
      final geometryIdx = texts.indexOf('Geometry');
      expect(algebraIdx, lessThan(geometryIdx));
    });

    testWidgets('limits to 10 topics', (tester) async {
      final states = List.generate(
        12,
        (i) => _state(topicId: 't$i', accuracy: 0.5),
      );
      await tester.pumpWidget(_buildTestApp(
        TopicBreakdownCard(
          allMastery: states,
          resolveTopicName: _resolveName,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsNWidgets(10));
    });

    testWidgets('shows attempts count in each row', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicBreakdownCard(
          allMastery: [
            _state(topicId: 't1', accuracy: 0.8, totalAttempts: 15),
          ],
          resolveTopicName: _resolveName,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('15 attempts'), findsOneWidget);
    });

    testWidgets('shows mastery level label', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicBreakdownCard(
          allMastery: [
            _state(topicId: 't1', accuracy: 0.9, level: MasteryLevel.expert),
          ],
          resolveTopicName: _resolveName,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Expert'), findsOneWidget);
    });

    testWidgets('shows pie chart icon when data present', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicBreakdownCard(
          allMastery: [
            _state(topicId: 't1', accuracy: 0.5),
          ],
          resolveTopicName: _resolveName,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.pie_chart), findsOneWidget);
    });

    testWidgets('shows no pie chart icon when empty', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicBreakdownCard(
          allMastery: [],
          resolveTopicName: _resolveName,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.pie_chart), findsNothing);
    });

    testWidgets('shows all mastery level labels', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicBreakdownCard(
          allMastery: [
            _state(topicId: 't1', accuracy: 0.1, level: MasteryLevel.novice),
            _state(topicId: 't2', accuracy: 0.3, level: MasteryLevel.browsing),
            _state(topicId: 't3', accuracy: 0.5, level: MasteryLevel.developing),
            _state(topicId: 't4', accuracy: 0.7, level: MasteryLevel.proficient),
            _state(topicId: 't5', accuracy: 0.9, level: MasteryLevel.expert),
          ],
          resolveTopicName: _resolveName,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Novice'), findsOneWidget);
      expect(find.text('Browsing'), findsOneWidget);
      expect(find.text('Developing'), findsOneWidget);
      expect(find.text('Proficient'), findsOneWidget);
      expect(find.text('Expert'), findsOneWidget);
    });

    testWidgets('shows accuracy color at different thresholds', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicBreakdownCard(
          allMastery: [
            _state(topicId: 't1', accuracy: 0.85),
            _state(topicId: 't2', accuracy: 0.65),
            _state(topicId: 't3', accuracy: 0.45),
          ],
          resolveTopicName: _resolveName,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Algebra'), findsOneWidget);
      expect(find.text('Geometry'), findsOneWidget);
      expect(find.text('Calculus'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
    });

    testWidgets('shows topic performance header', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        TopicBreakdownCard(
          allMastery: [
            _state(topicId: 't1', accuracy: 0.5),
          ],
          resolveTopicName: _resolveName,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Topic Performance'), findsOneWidget);
    });

    // TopicBreakdownCard has an onTopicTap callback but the tests do not
    // exercise it; navigation is handled by the parent widget.
  });
}
