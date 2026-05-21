import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

void main() {
  group('AppLocalizations', () {

    group('AppLocalizations.of(context)', () {
      testWidgets('returns null when no localization is available', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Test'),
              ),
            ),
          ),
        );
        final context = tester.element(find.text('Test'));
        final localizations = AppLocalizations.of(context);
        expect(localizations, isNull);
      });

      testWidgets('returns AppLocalizations when delegate is provided', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                final localizations = AppLocalizations.of(context);
                expect(localizations, isA<AppLocalizations>());
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('returns correct English localization for en locale', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                final localizations = AppLocalizations.of(context);
                expect(localizations, isNotNull);
                expect(localizations!.appTitle, 'StudyKing');
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('returns correct Spanish localization for es locale', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                final localizations = AppLocalizations.of(context);
                expect(localizations, isNotNull);
                expect(localizations!.appTitle, 'StudyKing');
                return const SizedBox();
              },
            ),
          ),
        );
      });
    });
  });



  group('Delegate Behavior', () {
    testWidgets('delegate loads English localization', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [AppLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final localizations = AppLocalizations.of(context);
              expect(localizations, isNotNull);
              expect(localizations!.localeName, 'en');
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('delegate loads Spanish localization', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Builder(
            builder: (context) {
              final localizations = AppLocalizations.of(context);
              expect(localizations, isNotNull);
              expect(localizations!.localeName, 'es');
              return const SizedBox();
            },
          ),
        ),
      );
    });










  });


  group('Widget Integration Tests', () {
    testWidgets('localizations work in MaterialApp context', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TestWidget(),
        ),
      );
    });

    testWidgets('localizations update when locale changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const TestWidget(),
        ),
      );

      final localizations1 = AppLocalizations.of(tester.element(find.byType(TestWidget)));
      expect(localizations1?.appTitle, 'StudyKing');

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: const TestWidget(),
        ),
      );

      final localizations2 = AppLocalizations.of(tester.element(find.byType(TestWidget)));
      expect(localizations2?.appTitle, 'StudyKing');
    });

    testWidgets('localizations are accessible in nested widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final localizations = AppLocalizations.of(context);
                expect(localizations, isNotNull);
                return Column(
                  children: [
                    Text(localizations!.appTitle),
                    Text(localizations.settings),
                    Builder(
                      builder: (innerContext) {
                        final innerLoc = AppLocalizations.of(innerContext);
                        expect(innerLoc, isNotNull);
                        return Text(innerLoc!.practice);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('StudyKing'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);
    });

    testWidgets('all bottom nav labels are accessible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            bottomNavigationBar: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return BottomNavigationBar(
                  currentIndex: 0,
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.school),
                      label: l10n.subjects,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.edit),
                      label: l10n.practice,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.settings),
                      label: l10n.settings,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Subjects'), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });

  group('Edge Cases', () {




    testWidgets('localizations work without specifying locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              expect(l10n, isNotNull);
              return Text(l10n!.appTitle);
            },
          ),
        ),
      );
      expect(find.text('StudyKing'), findsOneWidget);
    });

    testWidgets('localizations with region code en_US', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en', 'US'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              expect(l10n, isNotNull);
              return Text(l10n!.localeName);
            },
          ),
        ),
      );
      expect(find.text('en'), findsOneWidget);
    });

    testWidgets('localizations with Spanish region code es_MX', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es', 'MX'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              expect(l10n, isNotNull);
              return Text(l10n!.localeName);
            },
          ),
        ),
      );
      expect(find.text('es'), findsOneWidget);
    });

  });

}

class TestWidget extends StatelessWidget {
  const TestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Text(localizations?.appTitle ?? '');
  }
}
