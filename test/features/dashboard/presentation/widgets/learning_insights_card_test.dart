import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/presentation/widgets/learning_insights_card.dart';

Widget _wrap(Map<String, dynamic>? insights) => MaterialApp(
      home: Scaffold(body: LearningInsightsCard(insights: insights)),
    );

void main() {
  group('LearningInsightsCard', () {
    testWidgets('renders nothing when insights are null', (tester) async {
      await tester.pumpWidget(_wrap(null));
      expect(find.text('Learning Style Insights'), findsNothing);
    });

    testWidgets('renders nothing when hasData is false', (tester) async {
      await tester.pumpWidget(_wrap({'hasData': false}));
      expect(find.text('Learning Style Insights'), findsNothing);
    });

    testWidgets('renders insights when hasData is true', (tester) async {
      await tester.pumpWidget(_wrap({
        'hasData': true,
        'preferredBlockType': 'quiz',
        'optimalSessionMinutes': 40,
        'prefersVisual': true,
        'srEffectiveness': 0.3,
      }));
      await tester.pumpAndSettle();
      expect(find.text('Learning Style Insights'), findsOneWidget);
      expect(find.text('Preferred Content'), findsOneWidget);
      expect(find.text('QUIZ'), findsOneWidget);
      expect(find.text('Optimal Session'), findsOneWidget);
      expect(find.text('40 minutes'), findsOneWidget);
      expect(find.text('Visual Learner'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
    });

    testWidgets('shows spaced repetition row when effectiveness > 0.5', (tester) async {
      await tester.pumpWidget(_wrap({
        'hasData': true,
        'preferredBlockType': 'exercise',
        'optimalSessionMinutes': 25,
        'prefersVisual': false,
        'srEffectiveness': 0.9,
      }));
      await tester.pumpAndSettle();
      expect(find.text('Spaced Repetition'), findsOneWidget);
      expect(find.text('Highly effective'), findsOneWidget);
    });
  });
}
