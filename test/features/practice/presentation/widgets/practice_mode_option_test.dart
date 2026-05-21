import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_mode_option.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('PracticeModeOption', () {
    testWidgets('renders icon and title', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeOption(
          icon: Icons.school,
          title: 'Mathematics',
          onTap: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.school), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeOption(
          icon: Icons.school,
          title: 'Mathematics',
          subtitle: '5 questions due',
          onTap: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('5 questions due'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_buildTestApp(
        PracticeModeOption(
          icon: Icons.school,
          title: 'Mathematics',
          onTap: () => tapped = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mathematics'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('shows forward chevron icon', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeOption(
          icon: Icons.school,
          title: 'Test',
          onTap: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('does not render subtitle container when subtitle is null', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeOption(
          icon: Icons.school,
          title: 'Test',
          onTap: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.school), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('renders primary colored icon container', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeOption(
          icon: Icons.school,
          title: 'Test',
          onTap: () {},
        ),
      ));
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.school));
      expect(icon, isNotNull);
    });
  });
}
