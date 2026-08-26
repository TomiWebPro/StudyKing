import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/providers/dashboard_data_providers.dart';
import 'package:studyking/features/dashboard/presentation/widgets/syllabus_switcher.dart';
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

SyllabusBreakdown _breakdown(String subjectId, String subjectTitle) {
  return SyllabusBreakdown(
    subjectId: subjectId,
    subjectTitle: subjectTitle,
  );
}

void main() {
  group('SyllabusSwitcher', () {
    testWidgets('renders "All" chip plus one chip per syllabus',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: _buildTestApp(
          SyllabusSwitcher(
            breakdowns: [
              _breakdown('s1', 'Mathematics'),
              _breakdown('s2', 'Physics'),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ChoiceChip, 'All syllabi'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Mathematics'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Physics'), findsOneWidget);
    });

    testWidgets('"All" chip is selected by default', (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: _buildTestApp(
          SyllabusSwitcher(
            breakdowns: [
              _breakdown('s1', 'Mathematics'),
              _breakdown('s2', 'Physics'),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final allChip = tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'All syllabi'));
      expect(allChip.selected, isTrue);

      final mathChip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, 'Mathematics'));
      expect(mathChip.selected, isFalse);
    });

    testWidgets('tapping a syllabus chip selects it and deselects "All"',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: _buildTestApp(
          SyllabusSwitcher(
            breakdowns: [
              _breakdown('s1', 'Mathematics'),
              _breakdown('s2', 'Physics'),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Mathematics'));
      await tester.pumpAndSettle();

      final allChip = tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'All syllabi'));
      expect(allChip.selected, isFalse);

      final mathChip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, 'Mathematics'));
      expect(mathChip.selected, isTrue);
    });

    testWidgets('tapping "All" after a selection clears the selection',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: _buildTestApp(
          SyllabusSwitcher(
            breakdowns: [
              _breakdown('s1', 'Mathematics'),
              _breakdown('s2', 'Physics'),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Physics'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'All syllabi'));
      await tester.pumpAndSettle();

      final allChip = tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'All syllabi'));
      expect(allChip.selected, isTrue);
    });

    testWidgets('selection persists across rebuilds', (tester) async {
      final container = ProviderContainer();
      const breakdowns = [
        SyllabusBreakdown(subjectId: 's1', subjectTitle: 'Mathematics'),
        SyllabusBreakdown(subjectId: 's2', subjectTitle: 'Physics'),
      ];

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _buildTestApp(const SyllabusSwitcher(breakdowns: breakdowns)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Mathematics'));
      await tester.pumpAndSettle();

      final selected = container.read(dashboardSelectedSyllabusProvider);
      expect(selected, 's1');
    });
  });
}
