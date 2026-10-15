import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/prep_budget.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'settings_screen_test_helpers.dart';

void main() {
  group('SettingsScreen - Preparation Budget', () {
    setUp(() {
      fakeRepo.settings = SettingsBox();
    });

    testWidgets('renders preparation budget section title', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('Preparation budget'));
      expect(find.text('Preparation budget'), findsOneWidget);
    });

    testWidgets('renders section description', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('Control where off-period preparation tokens are spent'));
      expect(find.text('Control where off-period preparation tokens are spent'),
          findsOneWidget);
    });

    testWidgets('shows master toggle with correct label', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text("Prepare while I'm away"));
      expect(find.text("Prepare while I'm away"), findsOneWidget);
      expect(find.text(
          "Generate lessons, question variants, and a knowledge base while you're away"),
          findsOneWidget);
    });

    testWidgets('master toggle is on by default', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text("Prepare while I'm away"));
      expect(find.text("Prepare while I'm away"), findsOneWidget);
      final tile = find.ancestor(
        of: find.text("Prepare while I'm away"),
        matching: find.byType(SwitchListTile),
      );
      expect(tile, findsOneWidget);
      final switchTile = tester.widget<SwitchListTile>(tile);
      expect(switchTile.value, isTrue);
    });

    testWidgets('disables master toggle and shows disabled caption',
        (tester) async {
      final fakePrepRepo = FakePrepBudgetRepository();
      await pumpWithSettings(
        tester,
        prepBudgetRepository: fakePrepRepo,
      );

      // Scroll to the section first, then find the toggle
      await scrollToWidget(tester, find.text("Prepare while I'm away"));
      // Toggle off by tapping the SwitchListTile
      final toggle = find.ancestor(
        of: find.text("Prepare while I'm away"),
        matching: find.byType(SwitchListTile),
      );
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(fakePrepRepo.current.enabled, isFalse);
      expect(
          find.text('Preparation budget is off — prep tasks are paused'),
          findsWidgets);
    });

    testWidgets('enables master toggle when starting from disabled state',
        (tester) async {
      final fakePrepRepo = FakePrepBudgetRepository();
      fakePrepRepo.current = PrepBudget.defaults.copyWith(enabled: false);
      await pumpWithSettings(
        tester,
        prepBudgetRepository: fakePrepRepo,
      );

      expect(fakePrepRepo.current.enabled, isFalse);

      // Scroll to the section first, then find the toggle
      await scrollToWidget(tester, find.text("Prepare while I'm away"));
      // Toggle on
      final toggle = find.ancestor(
        of: find.text("Prepare while I'm away"),
        matching: find.byType(SwitchListTile),
      );
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(fakePrepRepo.current.enabled, isTrue);
      expect(
          find.text('Preparation budget is off — prep tasks are paused'),
          findsNothing);
    });

    testWidgets('shows category rows with labels and percentages',
        (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('PDF → Knowledge base'));
      expect(find.text('PDF → Knowledge base'), findsOneWidget);
      expect(find.text('Question bank expansion'), findsOneWidget);
      expect(find.text('Lesson preparation'), findsOneWidget);
      expect(find.text('Embeddings'), findsOneWidget);
      expect(find.text('Background tasks'), findsOneWidget);
    });

    testWidgets('shows default 40% for PDF ingestion category', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('PDF → Knowledge base'));
      expect(find.text('40%'), findsWidgets);
    });

    testWidgets('shows default 30% for question variants', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('Question bank expansion'));
      expect(find.text('30%'), findsWidgets);
    });

    testWidgets('shows default 20% for lesson prep', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('Lesson preparation'));
      expect(find.text('20%'), findsWidgets);
    });

    testWidgets('shows default 10% for embeddings and background',
        (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('Embeddings'));
      expect(find.text('10%'), findsWidgets);
    });

    testWidgets('shows sliders for each category', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('Background tasks'));
      expect(find.byType(Slider), findsNWidgets(5));
    });

    testWidgets('slider interaction updates category percent', (tester) async {
      final fakePrepRepo = FakePrepBudgetRepository();
      await pumpWithSettings(
        tester,
        prepBudgetRepository: fakePrepRepo,
        initialPrepBudget: PrepBudget.defaults,
      );

      // Find the embeddings slider by looking for it near the "Embeddings" text
      await scrollToWidget(tester, find.text('Embeddings'));
      final embeddingsRow = find.ancestor(
        of: find.text('Embeddings'),
        matching: find.byType(Padding),
      );
      final slider = find.descendant(
        of: embeddingsRow,
        matching: find.byType(Slider),
      );

      await tester.ensureVisible(slider);
      await tester.drag(slider.first, const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(fakePrepRepo.saveCallCount, greaterThanOrEqualTo(1));
    });

    testWidgets('shows token counts for each category', (tester) async {
      final fakePrepRepo = FakePrepBudgetRepository();
      await pumpWithSettings(
        tester,
        prepBudgetRepository: fakePrepRepo,
      );

      // The default caps should show token counts
      // PDF: 200K cap
      await scrollToWidget(tester, find.text('PDF → Knowledge base'));
      expect(find.textContaining('200K'), findsWidgets);
      // Question: 150K cap
      expect(find.textContaining('150K'), findsWidgets);
    });

    testWidgets('shows live counters from usage meter', (tester) async {
      final fakeMeter = FakeLlmUsageMeter(
        perTaskTypeTokens: {
          'pdf_ingestion': 50000,
          'question_variants': 30000,
          'lesson_prep': 20000,
          'embeddings': 5000,
          'background': 10000,
        },
      );
      await pumpWithSettings(
        tester,
        usageMeter: fakeMeter,
      );

      // The spendingByCategory from the service should display these values
      await scrollToWidget(tester, find.text('PDF → Knowledge base'));
      expect(find.textContaining('50K'), findsWidgets);
    });

    testWidgets('hides disabled caption when budget is enabled', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('PDF → Knowledge base'));
      expect(
          find.text('Preparation budget is off — prep tasks are paused'),
          findsNothing);
    });
  });
}
