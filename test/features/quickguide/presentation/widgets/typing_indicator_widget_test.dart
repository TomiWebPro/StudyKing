import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/quickguide/presentation/widgets/typing_indicator_widget.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp({
  required bool isStreaming,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: TypingIndicatorWidget(isStreaming: isStreaming),
    ),
  );
}

void main() {
  group('TypingIndicatorWidget', () {
    testWidgets('renders "Quick Guide is thinking..." when streaming',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(isStreaming: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Quick Guide is thinking...'), findsOneWidget);
    });

    testWidgets('keeps text in tree when not streaming (hidden by opacity)',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(isStreaming: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Quick Guide is thinking...'), findsOneWidget);
    });

    testWidgets('AnimatedOpacity has opacity 1.0 when streaming',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(isStreaming: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final animatedOpacity = find.byWidgetPredicate(
        (w) => w is AnimatedOpacity && w.opacity == 1.0,
      );
      expect(animatedOpacity, findsAtLeastNWidgets(1));
    });

    testWidgets('AnimatedOpacity has opacity 0.0 when not streaming',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(isStreaming: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final animatedOpacity = find.byWidgetPredicate(
        (w) => w is AnimatedOpacity && w.opacity == 0.0,
      );
      expect(animatedOpacity, findsAtLeastNWidgets(1));
    });

    testWidgets('renders CircularProgressIndicator when streaming',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(isStreaming: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('keeps CircularProgressIndicator in tree when not streaming',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(isStreaming: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('uses Semantics widget', (tester) async {
      await tester.pumpWidget(_buildTestApp(isStreaming: true));
      await tester.pump();

      expect(find.byType(Semantics), findsAtLeastNWidgets(1));
    });

    testWidgets('switches AnimatedOpacity when isStreaming changes',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(isStreaming: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      var zeroOpacity = find.byWidgetPredicate(
        (w) => w is AnimatedOpacity && w.opacity == 0.0,
      );
      expect(zeroOpacity, findsAtLeastNWidgets(1));

      await tester.pumpWidget(_buildTestApp(isStreaming: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      var fullOpacity = find.byWidgetPredicate(
        (w) => w is AnimatedOpacity && w.opacity == 1.0,
      );
      expect(fullOpacity, findsAtLeastNWidgets(1));
    });
  });
}
