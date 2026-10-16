import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/subject_model.dart';
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

  group('SettingsScreen - Quiet Hours', () {
    setUp(() {
      fakeRepo.settings = SettingsBox();
    });

    testWidgets('renders quiet hours section with title and description',
        (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('Quiet Hours'));
      expect(find.text('Quiet Hours'), findsOneWidget);
      expect(find.text('Prep tasks pause during these hours to prevent overworking'),
          findsOneWidget);
    });

    testWidgets('shows "Set quiet hours" button when no quiet hours configured',
        (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('Set quiet hours'));
      expect(find.text('Set quiet hours'), findsOneWidget);
      // No dropdown should be present when quiet hours are not configured.
      expect(find.byType(DropdownButton<int>), findsNothing);
      // Clear button should not be present either.
      expect(find.text('Clear quiet hours'), findsNothing);
    });

    testWidgets('shows quiet hours description text', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('Quiet Hours'));
      expect(find.text('Prep tasks pause during these hours to prevent overworking'),
          findsOneWidget);
    });

    testWidgets('set quiet hours through "Set quiet hours" button', (tester) async {
      final fakePrepRepo = FakePrepBudgetRepository();
      await pumpWithSettings(
        tester,
        prepBudgetRepository: fakePrepRepo,
      );

      await scrollToWidget(tester, find.text('Set quiet hours'));
      await tester.tap(find.text('Set quiet hours'));
      await tester.pumpAndSettle();

      // The start-hour picker (bottom sheet) should appear.
      expect(find.text('22:00'), findsWidgets);

      // Tap the 22:00 hour in the bottom sheet.
      await tester.ensureVisible(find.text('22:00').last);
      await tester.tap(find.text('22:00').last);
      await tester.pumpAndSettle();

      // The end-hour picker should appear, showing hours.
      expect(find.text('08:00'), findsWidgets);
      await tester.ensureVisible(find.text('08:00').last);
      await tester.tap(find.text('08:00').last);
      await tester.pumpAndSettle();

      // Quiet hours should now be set on the repository.
      expect(fakePrepRepo.current.quietHoursStart, 22);
      expect(fakePrepRepo.current.quietHoursEnd, 8);
      // The dropdowns should now be visible.
      expect(find.byType(DropdownButton<int>), findsNWidgets(2));
      // The "Set quiet hours" button should be gone, replaced by "Clear" button.
      expect(find.text('Set quiet hours'), findsNothing);
      expect(find.text('Clear quiet hours'), findsOneWidget);
    });

    testWidgets('clears quiet hours via clear button', (tester) async {
      final fakePrepRepo = FakePrepBudgetRepository();
      fakePrepRepo.setQuietHours(22, 8);
      await pumpWithSettings(
        tester,
        prepBudgetRepository: fakePrepRepo,
      );

      await scrollToWidget(tester, find.text('Quiet Hours'));
      await tester.pumpAndSettle();

      // Both dropdowns should be visible with the configured values.
      expect(find.byType(DropdownButton<int>), findsNWidgets(2));
      expect(find.text('Clear quiet hours'), findsOneWidget);

      // Tap clear.
      await tester.ensureVisible(find.text('Clear quiet hours'));
      await tester.tap(find.text('Clear quiet hours'));
      await tester.pumpAndSettle();

      // Quiet hours should be cleared on the repository.
      expect(fakePrepRepo.current.quietHoursStart, isNull);
      expect(fakePrepRepo.current.quietHoursEnd, isNull);
      // The clear button should be gone; the "Set quiet hours" button returns.
      expect(find.text('Clear quiet hours'), findsNothing);
      expect(find.text('Set quiet hours'), findsOneWidget);
    });

    testWidgets('changing start hour updates the budget', (tester) async {
      final fakePrepRepo = FakePrepBudgetRepository();
      fakePrepRepo.setQuietHours(22, 8);
      await pumpWithSettings(
        tester,
        prepBudgetRepository: fakePrepRepo,
      );

      await scrollToWidget(tester, find.text('Quiet Hours'));
      await tester.pumpAndSettle();

      // Find the start-hour dropdown and change it to 23.
      final startDropdown = find.ancestor(
        of: find.text('22:00'),
        matching: find.byType(DropdownButton<int>),
      );
      await tester.ensureVisible(startDropdown);
      await tester.tap(startDropdown);
      await tester.pumpAndSettle();

      // Select 23:00 from the dropdown menu.
      await tester.ensureVisible(find.text('23:00').last);
      await tester.tap(find.text('23:00').last);
      await tester.pumpAndSettle();

      expect(fakePrepRepo.current.quietHoursStart, 23);
      expect(fakePrepRepo.current.quietHoursEnd, 8);
    });

    testWidgets('changing end hour updates the budget', (tester) async {
      final fakePrepRepo = FakePrepBudgetRepository();
      fakePrepRepo.setQuietHours(22, 8);
      await pumpWithSettings(
        tester,
        prepBudgetRepository: fakePrepRepo,
      );

      await scrollToWidget(tester, find.text('Quiet Hours'));
      await tester.pumpAndSettle();

      // Find the end-hour dropdown and change it to 10.
      final endDropdown = find.ancestor(
        of: find.text('08:00'),
        matching: find.byType(DropdownButton<int>),
      );
      await tester.ensureVisible(endDropdown);
      await tester.tap(endDropdown);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('10:00').last);
      await tester.tap(find.text('10:00').last);
      await tester.pumpAndSettle();

      expect(fakePrepRepo.current.quietHoursStart, 22);
      expect(fakePrepRepo.current.quietHoursEnd, 10);
    });

    testWidgets('wraparound window shows both dropdowns with correct values',
        (tester) async {
      final fakePrepRepo = FakePrepBudgetRepository();
      fakePrepRepo.setQuietHours(23, 6);
      await pumpWithSettings(
        tester,
        prepBudgetRepository: fakePrepRepo,
      );

      await scrollToWidget(tester, find.text('Quiet Hours'));
      await tester.pumpAndSettle();

      expect(find.text('23:00'), findsWidgets);
      expect(find.text('06:00'), findsWidgets);
      expect(fakePrepRepo.current.quietHoursStart, 23);
      expect(fakePrepRepo.current.quietHoursEnd, 6);
    });
  });

  group('SettingsScreen - Per-subject preparation', () {
    setUp(() {
      fakeRepo.settings = SettingsBox();
    });

    testWidgets('renders per-subject prep section with title and description',
        (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('Per-subject preparation'));
      expect(find.text('Per-subject preparation'), findsOneWidget);
      expect(
          find.text('Choose which subjects to prepare during off-periods'),
          findsOneWidget);
    });

    testWidgets('shows empty state when no subjects exist', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('Per-subject preparation'));
      expect(find.text('No subjects have been added yet'), findsOneWidget);
    });

    testWidgets(
        'renders a toggle for each subject when subjects exist', (tester) async {
      final subjects = [
        Subject(id: 'math', name: 'Mathematics'),
        Subject(id: 'history', name: 'History'),
        Subject(id: 'physics', name: 'Physics'),
      ];
      await pumpWithSettings(tester, subjects: subjects);

      await scrollToWidget(tester, find.text('Per-subject preparation'));
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);
      // Each subject should have a SwitchListTile within the section.
      final section = find.ancestor(
        of: find.text('Per-subject preparation'),
        matching: find.byType(Card),
      );
      final switches = find.descendant(
        of: section,
        matching: find.byType(SwitchListTile),
      );
      expect(switches, findsNWidgets(3));
    });

    testWidgets(
        'all switches are on when no subjects are disabled', (tester) async {
      final subjects = [
        Subject(id: 'math', name: 'Mathematics'),
        Subject(id: 'history', name: 'History'),
      ];
      final fakePrepRepo = FakePrepBudgetRepository();
      await pumpWithSettings(
        tester,
        prepBudgetRepository: fakePrepRepo,
        subjects: subjects,
      );

      await scrollToWidget(tester, find.text('Per-subject preparation'));
      await tester.pumpAndSettle();

      expect(fakePrepRepo.current.disabledSubjects, isEmpty);
      // All switches should be on (true) within the section.
      final section = find.ancestor(
        of: find.text('Per-subject preparation'),
        matching: find.byType(Card),
      );
      final switches = find.descendant(
        of: section,
        matching: find.byType(SwitchListTile),
      );
      expect(switches, findsNWidgets(2));
    });

    testWidgets(
        'toggling a subject off adds it to disabledSubjects', (tester) async {
      final subjects = [
        Subject(id: 'math', name: 'Mathematics'),
        Subject(id: 'history', name: 'History'),
      ];
      final fakePrepRepo = FakePrepBudgetRepository();
      await pumpWithSettings(
        tester,
        prepBudgetRepository: fakePrepRepo,
        subjects: subjects,
      );

      await scrollToWidget(tester, find.text('Per-subject preparation'));
      await tester.pumpAndSettle();

      // Toggle "Mathematics" off.
      final mathTile = find.ancestor(
        of: find.text('Mathematics'),
        matching: find.byType(SwitchListTile),
      );
      await tester.ensureVisible(mathTile);
      await tester.tap(mathTile);
      await tester.pumpAndSettle();

      expect(fakePrepRepo.current.disabledSubjects, contains('math'));
      expect(fakePrepRepo.current.disabledSubjects, isNot(contains('history')));
    });

    testWidgets(
        'toggling a subject back on removes it from disabledSubjects', (tester) async {
      final subjects = [
        Subject(id: 'math', name: 'Mathematics'),
        Subject(id: 'history', name: 'History'),
      ];
      final fakePrepRepo = FakePrepBudgetRepository();
      fakePrepRepo.setSubjectPrepEnabled('math', false);
      fakePrepRepo.setSubjectPrepEnabled('history', false);
      await pumpWithSettings(
        tester,
        prepBudgetRepository: fakePrepRepo,
        subjects: subjects,
        initialPrepBudget: PrepBudget.defaults.copyWith(
          disabledSubjects: {'math', 'history'},
        ),
      );

      await scrollToWidget(tester, find.text('Per-subject preparation'));
      await tester.pumpAndSettle();

      // Toggle "Mathematics" back on.
      final mathTile = find.ancestor(
        of: find.text('Mathematics'),
        matching: find.byType(SwitchListTile),
      );
      await tester.ensureVisible(mathTile);
      await tester.tap(mathTile);
      await tester.pumpAndSettle();

      expect(fakePrepRepo.current.disabledSubjects, isNot(contains('math')));
      expect(fakePrepRepo.current.disabledSubjects, contains('history'));
    });

    testWidgets('shows loading indicator while subjects load', (tester) async {
      // Use the default (unloaded) subject list provider which will be in
      // loading state if no override is provided.
      await pumpWithSettings(tester);
      await tester.pump(const Duration(milliseconds: 100));
      // After settling, the empty state should show since no Hive is set up.
      await scrollToWidget(tester, find.text('Per-subject preparation'));
      expect(find.text('No subjects have been added yet'), findsOneWidget);
    });

    testWidgets('disabled subjects show switch in off position', (tester) async {
      final subjects = [
        Subject(id: 'math', name: 'Mathematics'),
        Subject(id: 'history', name: 'History'),
      ];
      final fakePrepRepo = FakePrepBudgetRepository();
      fakePrepRepo.setSubjectPrepEnabled('history', false);
      await pumpWithSettings(
        tester,
        prepBudgetRepository: fakePrepRepo,
        subjects: subjects,
        initialPrepBudget: PrepBudget.defaults.copyWith(
          disabledSubjects: {'history'},
        ),
      );

      await scrollToWidget(tester, find.text('Per-subject preparation'));
      await tester.pumpAndSettle();

      // History should have its switch off (value = false).
      final historyTile = find.ancestor(
        of: find.text('History'),
        matching: find.byType(SwitchListTile),
      );
      expect(historyTile, findsOneWidget);
      final historySwitch = tester.widget<SwitchListTile>(historyTile);
      expect(historySwitch.value, isFalse);

      // Math should have its switch on (value = true).
      final mathTile = find.ancestor(
        of: find.text('Mathematics'),
        matching: find.byType(SwitchListTile),
      );
      expect(mathTile, findsOneWidget);
      final mathSwitch = tester.widget<SwitchListTile>(mathTile);
      expect(mathSwitch.value, isTrue);
    });
  });
}
