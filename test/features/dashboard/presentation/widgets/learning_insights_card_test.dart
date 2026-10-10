import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/presentation/widgets/learning_insights_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';
import 'package:studyking/l10n/generated/app_localizations_es.dart';

final _l10n = AppLocalizationsEn();
final _l10nEs = AppLocalizationsEs();

Widget _wrap(Map<String, dynamic>? insights, {Locale locale = const Locale('en')}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(body: LearningInsightsCard(insights: insights)),
    );

void main() {
  group('LearningInsightsCard', () {
    testWidgets('renders nothing when insights are null', (tester) async {
      await tester.pumpWidget(_wrap(null));
      expect(find.text(_l10n.learningStyleInsightsTitle), findsNothing);
    });

    testWidgets('renders nothing when hasData is false', (tester) async {
      await tester.pumpWidget(_wrap({'hasData': false}));
      expect(find.text(_l10n.learningStyleInsightsTitle), findsNothing);
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
      expect(find.text(_l10n.learningStyleInsightsTitle), findsOneWidget);
      expect(find.text(_l10n.preferredContentLabel), findsOneWidget);
      expect(find.text('QUIZ'), findsOneWidget);
      expect(find.text(_l10n.optimalSessionLabel), findsOneWidget);
      expect(find.text(_l10n.minutesValue(40)), findsOneWidget);
      expect(find.text(_l10n.visualLearnerLabel), findsOneWidget);
      expect(find.text(_l10n.yesLabel), findsOneWidget);
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
      expect(find.text(_l10n.spacedRepetition), findsOneWidget);
      expect(find.text(_l10n.highlyEffectiveLabel), findsOneWidget);
    });

    testWidgets('renders localized strings in Spanish locale', (tester) async {
      await tester.pumpWidget(
        _wrap({
          'hasData': true,
          'preferredBlockType': 'quiz',
          'optimalSessionMinutes': 40,
          'prefersVisual': true,
          'srEffectiveness': 0.9,
        }, locale: const Locale('es')),
      );
      await tester.pumpAndSettle();
      expect(find.text(_l10nEs.learningStyleInsightsTitle), findsOneWidget);
      expect(find.text(_l10nEs.preferredContentLabel), findsOneWidget);
      expect(find.text(_l10nEs.optimalSessionLabel), findsOneWidget);
      expect(find.text(_l10nEs.minutesValue(40)), findsOneWidget);
      expect(find.text(_l10nEs.visualLearnerLabel), findsOneWidget);
      expect(find.text(_l10nEs.yesLabel), findsOneWidget);
      expect(find.text(_l10nEs.spacedRepetition), findsOneWidget);
      expect(find.text(_l10nEs.highlyEffectiveLabel), findsOneWidget);
      // The old hardcoded English strings must no longer appear.
      expect(find.text('Learning Style Insights'), findsNothing);
      expect(find.text('Optimal Session'), findsNothing);
      expect(find.text('40 minutes'), findsNothing);
    });

    testWidgets('minutes value uses singular plural form for one minute', (tester) async {
      await tester.pumpWidget(_wrap({
        'hasData': true,
        'preferredBlockType': 'exercise',
        'optimalSessionMinutes': 1,
        'prefersVisual': false,
        'srEffectiveness': 0.0,
      }));
      await tester.pumpAndSettle();
      expect(find.text(_l10n.minutesValue(1)), findsOneWidget);
      expect(find.text('1 minute'), findsOneWidget);
    });
  });
}
