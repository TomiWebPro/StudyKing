import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/presentation/widgets/syllabus_switcher.dart';
import 'package:studyking/features/dashboard/providers/dashboard_data_providers.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

SyllabusBreakdown _breakdown(String id, String title) => SyllabusBreakdown(
      subjectId: id,
      subjectTitle: title,
    );

Widget _buildTestApp(Widget child, ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('SyllabusSwitcher', () {
    testWidgets('renders All chip and a chip per syllabus', (tester) async {
      final container = ProviderContainer();
      final breakdowns = [
        _breakdown('s1', 'Mathematics'),
        _breakdown('s2', 'Physics'),
      ];

      await tester.pumpWidget(
        _buildTestApp(SyllabusSwitcher(breakdowns: breakdowns), container),
      );
      await tester.pumpAndSettle();

      expect(find.text('All syllabi'), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);

      addTearDown(container.dispose);
    });

    testWidgets('marks All chip selected by default', (tester) async {
      final container = ProviderContainer();
      final breakdowns = [_breakdown('s1', 'Mathematics')];

      await tester.pumpWidget(
        _buildTestApp(SyllabusSwitcher(breakdowns: breakdowns), container),
      );
      await tester.pumpAndSettle();

      final allChip = tester.widget<ChoiceChip>(
        find.byWidgetPredicate(
          (w) => w is ChoiceChip && _chipLabel(w) == 'All syllabi',
        ),
      );
      expect(allChip.selected, isTrue);

      addTearDown(container.dispose);
    });

    testWidgets('tap selects syllabus and updates provider state',
        (tester) async {
      final container = ProviderContainer();
      final breakdowns = [
        _breakdown('s1', 'Mathematics'),
        _breakdown('s2', 'Physics'),
      ];

      await tester.pumpWidget(
        _buildTestApp(SyllabusSwitcher(breakdowns: breakdowns), container),
      );
      await tester.pumpAndSettle();

      expect(container.read(dashboardSelectedSyllabusProvider), isNull);

      await tester.tap(find.text('Physics'));
      await tester.pumpAndSettle();

      expect(container.read(dashboardSelectedSyllabusProvider), 's2');

      final physicsChip = tester.widget<ChoiceChip>(
        find.byWidgetPredicate(
          (w) => w is ChoiceChip && _chipLabel(w) == 'Physics',
        ),
      );
      expect(physicsChip.selected, isTrue);

      final allChip = tester.widget<ChoiceChip>(
        find.byWidgetPredicate(
          (w) => w is ChoiceChip && _chipLabel(w) == 'All syllabi',
        ),
      );
      expect(allChip.selected, isFalse);

      addTearDown(container.dispose);
    });

    testWidgets('tap on All resets selection to null', (tester) async {
      final container = ProviderContainer();
      final breakdowns = [_breakdown('s1', 'Mathematics')];

      await tester.pumpWidget(
        _buildTestApp(SyllabusSwitcher(breakdowns: breakdowns), container),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mathematics'));
      await tester.pumpAndSettle();
      expect(container.read(dashboardSelectedSyllabusProvider), 's1');

      await tester.tap(find.text('All syllabi'));
      await tester.pumpAndSettle();
      expect(container.read(dashboardSelectedSyllabusProvider), isNull);

      addTearDown(container.dispose);
    });
  });
}

String _chipLabel(ChoiceChip chip) {
  final label = chip.label;
  if (label is Text) return (label.data ?? '').trim();
  return '';
}
