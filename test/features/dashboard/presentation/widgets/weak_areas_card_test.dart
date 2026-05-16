import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/dashboard/presentation/widgets/weak_areas_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
    home: Scaffold(body: child),
  );
}

MasteryState _state({
  required String topicId,
  double accuracy = 0.0,
}) {
  return MasteryState(
    studentId: 's1',
    topicId: topicId,
    accuracy: accuracy,
    totalAttempts: 5,
    correctAttempts: 2,
    masteryLevel: MasteryLevel.novice,
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
  group('WeakAreasCard', () {
    testWidgets('renders nothing when no weak areas', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        WeakAreasCard(
          allMastery: [
            _state(topicId: 't1', accuracy: 0.9),
          ],
          resolveTopicName: _resolveName,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('renders weak areas with accuracy < 0.6', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        WeakAreasCard(
          allMastery: [
            _state(topicId: 't1', accuracy: 0.4),
            _state(topicId: 't2', accuracy: 0.5),
            _state(topicId: 't3', accuracy: 0.9),
          ],
          resolveTopicName: _resolveName,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Algebra'), findsOneWidget);
      expect(find.text('Geometry'), findsOneWidget);
      expect(find.text('Calculus'), findsNothing);
    });

    testWidgets('limits to 5 weak areas', (tester) async {
      final states = List.generate(
        7,
        (i) => _state(topicId: 't$i', accuracy: 0.3),
      );
      await tester.pumpWidget(_buildTestApp(
        WeakAreasCard(
          allMastery: states,
          resolveTopicName: _resolveName,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsNWidgets(6));
    });

    testWidgets('shows practice all weak areas button', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        WeakAreasCard(
          allMastery: [
            _state(topicId: 't1', accuracy: 0.4),
          ],
          resolveTopicName: _resolveName,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('shows warning icon', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        WeakAreasCard(
          allMastery: [
            _state(topicId: 't1', accuracy: 0.3),
          ],
          resolveTopicName: _resolveName,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });
  });
}
