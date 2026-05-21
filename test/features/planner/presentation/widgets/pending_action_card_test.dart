import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/planner/presentation/widgets/pending_action_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

void main() {
  Widget buildApp(Widget widget) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: widget),
    );
  }

  group('PendingActionCard', () {
    testWidgets('renders schedule action type with event icon', (tester) async {
      await tester.pumpWidget(buildApp(
        PendingActionCard(
          action: PendingActionModel(
            id: 'a1',
            studentId: 's1',
            actionType: 'schedule',
          ),
          onAccept: () {},
          onDismiss: () {},
        ),
      ));

      expect(find.text('Schedule a lesson'), findsOneWidget);
      expect(find.byIcon(Icons.event), findsOneWidget);
    });

    testWidgets('renders reschedule action type with event_busy icon', (tester) async {
      await tester.pumpWidget(buildApp(
        PendingActionCard(
          action: PendingActionModel(
            id: 'a2',
            studentId: 's1',
            actionType: 'reschedule',
          ),
          onAccept: () {},
          onDismiss: () {},
        ),
      ));

      expect(find.text('Reschedule lesson'), findsOneWidget);
      expect(find.byIcon(Icons.event_busy), findsOneWidget);
    });

    testWidgets('renders planAdjustment action type with tune icon', (tester) async {
      await tester.pumpWidget(buildApp(
        PendingActionCard(
          action: PendingActionModel(
            id: 'a3',
            studentId: 's1',
            actionType: 'planAdjustment',
          ),
          onAccept: () {},
          onDismiss: () {},
        ),
      ));

      expect(find.text('Plan adjustment suggested'), findsOneWidget);
      expect(find.byIcon(Icons.tune), findsOneWidget);
    });

    testWidgets('renders unknown action type with fallback', (tester) async {
      await tester.pumpWidget(buildApp(
        PendingActionCard(
          action: PendingActionModel(
            id: 'a4',
            studentId: 's1',
            actionType: 'unknown_type',
          ),
          onAccept: () {},
          onDismiss: () {},
        ),
      ));

      expect(find.text('Action needed'), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });

    testWidgets('shows topic title when provided', (tester) async {
      await tester.pumpWidget(buildApp(
        PendingActionCard(
          action: PendingActionModel(
            id: 'a5',
            studentId: 's1',
            actionType: 'schedule',
            topicTitle: 'Algebra Basics',
          ),
          onAccept: () {},
          onDismiss: () {},
        ),
      ));

      expect(find.text('Algebra Basics'), findsOneWidget);
    });

    testWidgets('hides topic title when empty', (tester) async {
      await tester.pumpWidget(buildApp(
        PendingActionCard(
          action: PendingActionModel(
            id: 'a6',
            studentId: 's1',
            actionType: 'schedule',
            topicTitle: '',
          ),
          onAccept: () {},
          onDismiss: () {},
        ),
      ));

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('calls onAccept when accept button tapped', (tester) async {
      bool accepted = false;
      await tester.pumpWidget(buildApp(
        PendingActionCard(
          action: PendingActionModel(
            id: 'a7',
            studentId: 's1',
            actionType: 'schedule',
          ),
          onAccept: () => accepted = true,
          onDismiss: () {},
        ),
      ));

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      expect(accepted, isTrue);
    });

    testWidgets('calls onDismiss when dismiss button tapped', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(buildApp(
        PendingActionCard(
          action: PendingActionModel(
            id: 'a8',
            studentId: 's1',
            actionType: 'schedule',
          ),
          onAccept: () {},
          onDismiss: () => dismissed = true,
        ),
      ));

      await tester.tap(find.byIcon(Icons.cancel_outlined));
      expect(dismissed, isTrue);
    });

    testWidgets('renders dismiss and accept tooltips', (tester) async {
      await tester.pumpWidget(buildApp(
        PendingActionCard(
          action: PendingActionModel(
            id: 'a9',
            studentId: 's1',
            actionType: 'schedule',
          ),
          onAccept: () {},
          onDismiss: () {},
        ),
      ));

      expect(find.byTooltip('Accept'), findsOneWidget);
      expect(find.byTooltip('Dismiss'), findsOneWidget);
    });
  });
}
