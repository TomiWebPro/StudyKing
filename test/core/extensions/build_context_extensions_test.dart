import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/extensions/build_context_extensions.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(
      body: Builder(
        builder: (context) => child,
      ),
    ),
  );
}

void main() {
  group('BuildContextX.theme', () {
    testWidgets('returns ThemeData from context', (tester) async {
      ThemeData? captured;
      await tester.pumpWidget(wrapApp(
        Builder(
          builder: (context) {
            captured = context.theme;
            return const SizedBox();
          },
        ),
      ));
      expect(captured, isA<ThemeData>());
    });
  });

  group('BuildContextX.colorScheme', () {
    testWidgets('returns ColorScheme from context', (tester) async {
      ColorScheme? captured;
      await tester.pumpWidget(wrapApp(
        Builder(
          builder: (context) {
            captured = context.colorScheme;
            return const SizedBox();
          },
        ),
      ));
      expect(captured, isA<ColorScheme>());
    });

    testWidgets('colorScheme.primary matches theme', (tester) async {
      Color? viaExtension;
      Color? viaTheme;
      await tester.pumpWidget(wrapApp(
        Builder(
          builder: (context) {
            viaExtension = context.colorScheme.primary;
            viaTheme = Theme.of(context).colorScheme.primary;
            return const SizedBox();
          },
        ),
      ));
      expect(viaExtension, equals(viaTheme));
    });
  });

  group('BuildContextX.textTheme', () {
    testWidgets('returns TextTheme from context', (tester) async {
      TextTheme? captured;
      await tester.pumpWidget(wrapApp(
        Builder(
          builder: (context) {
            captured = context.textTheme;
            return const SizedBox();
          },
        ),
      ));
      expect(captured, isA<TextTheme>());
    });
  });

  group('BuildContextX.mediaQuery', () {
    testWidgets('returns MediaQueryData from context', (tester) async {
      MediaQueryData? captured;
      await tester.pumpWidget(wrapApp(
        Builder(
          builder: (context) {
            captured = context.mediaQuery;
            return const SizedBox();
          },
        ),
      ));
      expect(captured, isA<MediaQueryData>());
    });
  });

  group('BuildContextX.screenSize', () {
    testWidgets('returns screen size from MediaQuery', (tester) async {
      Size? captured;
      await tester.pumpWidget(wrapApp(
        Builder(
          builder: (context) {
            captured = context.screenSize;
            return const SizedBox();
          },
        ),
      ));
      expect(captured, isA<Size>());
      expect(captured!.width, greaterThan(0));
      expect(captured!.height, greaterThan(0));
    });
  });

  group('BuildContextX.screenWidth', () {
    testWidgets('returns screen width from MediaQuery', (tester) async {
      double? captured;
      await tester.pumpWidget(wrapApp(
        Builder(
          builder: (context) {
            captured = context.screenWidth;
            return const SizedBox();
          },
        ),
      ));
      expect(captured, greaterThan(0));
    });
  });

  group('BuildContextX.screenHeight', () {
    testWidgets('returns screen height from MediaQuery', (tester) async {
      double? captured;
      await tester.pumpWidget(wrapApp(
        Builder(
          builder: (context) {
            captured = context.screenHeight;
            return const SizedBox();
          },
        ),
      ));
      expect(captured, greaterThan(0));
    });
  });

  group('BuildContextX.brightness', () {
    testWidgets('returns brightness from theme', (tester) async {
      Brightness? captured;
      await tester.pumpWidget(wrapApp(
        Builder(
          builder: (context) {
            captured = context.brightness;
            return const SizedBox();
          },
        ),
      ));
      expect(captured, isA<Brightness>());
    });
  });

  group('BuildContextX.isDarkMode', () {
    testWidgets('returns false for default light theme', (tester) async {
      bool? captured;
      await tester.pumpWidget(wrapApp(
        Builder(
          builder: (context) {
            captured = context.isDarkMode;
            return const SizedBox();
          },
        ),
      ));
      expect(captured, isFalse);
    });

    testWidgets('returns true for dark theme', (tester) async {
      bool? captured;
      await tester.pumpWidget(
        MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                captured = context.isDarkMode;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(captured, isTrue);
    });
  });

  group('BuildContextX.l10n', () {
    testWidgets('returns AppLocalizations from context', (tester) async {
      AppLocalizations? captured;
      await tester.pumpWidget(wrapApp(
        Builder(
          builder: (context) {
            captured = context.l10n;
            return const SizedBox();
          },
        ),
      ));
      expect(captured, isA<AppLocalizations>());
    });
  });
}
