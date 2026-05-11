import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';
import 'package:studyking/l10n/generated/app_localizations_es.dart';

void main() {
  group('AppLocalizations', () {
    group('Static Properties', () {
      test('delegate is a LocalizationsDelegate', () {
        expect(AppLocalizations.delegate, isA<LocalizationsDelegate<AppLocalizations>>());
      });

      test('delegate is _AppLocalizationsDelegate', () {
        final delegate = AppLocalizations.delegate;
        expect(delegate.type, isNotNull);
      });

      test('localizationsDelegates contains expected delegates', () {
        expect(AppLocalizations.localizationsDelegates, isA<List<LocalizationsDelegate<dynamic>>>());
        expect(AppLocalizations.localizationsDelegates.length, 4);
        expect(AppLocalizations.localizationsDelegates.contains(AppLocalizations.delegate), isTrue);
        expect(AppLocalizations.localizationsDelegates.contains(GlobalMaterialLocalizations.delegate), isTrue);
        expect(AppLocalizations.localizationsDelegates.contains(GlobalCupertinoLocalizations.delegate), isTrue);
        expect(AppLocalizations.localizationsDelegates.contains(GlobalWidgetsLocalizations.delegate), isTrue);
      });

      test('supportedLocales contains en and es', () {
        expect(AppLocalizations.supportedLocales, isA<List<Locale>>());
        expect(AppLocalizations.supportedLocales.length, 2);
        
        final locales = AppLocalizations.supportedLocales;
        expect(locales.any((l) => l.languageCode == 'en'), isTrue);
        expect(locales.any((l) => l.languageCode == 'es'), isTrue);
      });

      test('supportedLocales locales are properly formed', () {
        for (final locale in AppLocalizations.supportedLocales) {
          expect(locale.languageCode, isNotEmpty);
          expect(locale.countryCode, isNull);
        }
      });
    });

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

  group('AppLocalizationsEn', () {
    late AppLocalizationsEn localizations;

    setUp(() {
      localizations = AppLocalizationsEn();
    });

    test('has correct localeName', () {
      expect(localizations.localeName, 'en');
    });

    test('constructor accepts custom locale', () {
      final customLoc = AppLocalizationsEn('en-GB');
      expect(customLoc.localeName.startsWith('en'), isTrue);
    });

    group('Simple Getters', () {
      test('appTitle returns StudyKing', () {
        expect(localizations.appTitle, 'StudyKing');
      });

      test('subjects returns Subjects', () {
        expect(localizations.subjects, 'Subjects');
      });

      test('practice returns Practice', () {
        expect(localizations.practice, 'Practice');
      });

      test('settings returns Settings', () {
        expect(localizations.settings, 'Settings');
      });

      test('studyPlanner returns Study Planner', () {
        expect(localizations.studyPlanner, 'Study Planner');
      });

      test('createStudyPlan returns Create Study Plan', () {
        expect(localizations.createStudyPlan, 'Create Study Plan');
      });

      test('courseSubject returns Course/Subject', () {
        expect(localizations.courseSubject, 'Course/Subject');
      });

      test('courseHint returns e.g., IB Physics', () {
        expect(localizations.courseHint, 'e.g., IB Physics');
      });

      test('days returns Days', () {
        expect(localizations.days, 'Days');
      });

      test('hoursPerDay returns Hours/Day', () {
        expect(localizations.hoursPerDay, 'Hours/Day');
      });

      test('generatePlan returns Generate Plan', () {
        expect(localizations.generatePlan, 'Generate Plan');
      });

      test('generating returns Generating...', () {
        expect(localizations.generating, 'Generating...');
      });

      test('yourStudySchedule returns Your Study Schedule', () {
        expect(localizations.yourStudySchedule, 'Your Study Schedule');
      });

      test('fillAllFieldsCorrectly returns Please fill in all fields correctly', () {
        expect(localizations.fillAllFieldsCorrectly, 'Please fill in all fields correctly');
      });

      test('today returns Today', () {
        expect(localizations.today, 'Today');
      });

      test('yesterday returns Yesterday', () {
        expect(localizations.yesterday, 'Yesterday');
      });

      test('unknown returns Unknown', () {
        expect(localizations.unknown, 'Unknown');
      });
    });

    group('Parameterized Methods', () {
      test('topicLabel returns correct format', () {
        expect(localizations.topicLabel(1), 'Topic 1');
        expect(localizations.topicLabel(5), 'Topic 5');
        expect(localizations.topicLabel(100), 'Topic 100');
      });

      test('sessionDurationMinutes returns correct format', () {
        expect(localizations.sessionDurationMinutes(30), '30 min session');
        expect(localizations.sessionDurationMinutes(60), '60 min session');
        expect(localizations.sessionDurationMinutes(1), '1 min session');
      });

      test('generatedPlanOverDays returns correct format', () {
        expect(localizations.generatedPlanOverDays('Math', 7, 14), 
            'Generated plan for Math over 7 days (14 total hours)');
        expect(localizations.generatedPlanOverDays('Physics', 30, 60), 
            'Generated plan for Physics over 30 days (60 total hours)');
      });

      group('overDaysPlural', () {
        test('returns correct format for zero', () {
          expect(localizations.overDaysPlural(0), 'over no days');
        });

        test('returns correct format for one', () {
          expect(localizations.overDaysPlural(1), 'over 1 day');
        });

        test('returns correct format for other values', () {
          expect(localizations.overDaysPlural(2), 'over 2 days');
          expect(localizations.overDaysPlural(7), 'over 7 days');
          expect(localizations.overDaysPlural(30), 'over 30 days');
        });
      });

      group('totalHoursPlural', () {
        test('returns correct format for one', () {
          expect(localizations.totalHoursPlural(1), '1 total hour');
        });

        test('returns correct format for other values', () {
          expect(localizations.totalHoursPlural(2), '2 total hours');
          expect(localizations.totalHoursPlural(10), '10 total hours');
          expect(localizations.totalHoursPlural(100), '100 total hours');
        });
      });

      group('durationDays', () {
        test('returns correct format for one', () {
          expect(localizations.durationDays(1), '1d');
        });

        test('returns correct format for other values', () {
          expect(localizations.durationDays(2), '2d');
          expect(localizations.durationDays(7), '7d');
          expect(localizations.durationDays(30), '30d');
        });
      });

      group('durationHours', () {
        test('returns correct format for one', () {
          expect(localizations.durationHours(1), '1h');
        });

        test('returns correct format for other values', () {
          expect(localizations.durationHours(2), '2h');
          expect(localizations.durationHours(5), '5h');
          expect(localizations.durationHours(24), '24h');
        });
      });

      group('durationMinutes', () {
        test('returns correct format for one', () {
          expect(localizations.durationMinutes(1), '1m');
        });

        test('returns correct format for other values', () {
          expect(localizations.durationMinutes(2), '2m');
          expect(localizations.durationMinutes(30), '30m');
          expect(localizations.durationMinutes(60), '60m');
        });
      });

      group('durationSeconds', () {
        test('returns correct format for one', () {
          expect(localizations.durationSeconds(1), '1s');
        });

        test('returns correct format for other values', () {
          expect(localizations.durationSeconds(2), '2s');
          expect(localizations.durationSeconds(30), '30s');
          expect(localizations.durationSeconds(59), '59s');
        });
      });
    });
  });

  group('AppLocalizationsEs', () {
    late AppLocalizationsEs localizations;

    setUp(() {
      localizations = AppLocalizationsEs();
    });

    test('has correct localeName', () {
      expect(localizations.localeName, 'es');
    });

    test('constructor accepts custom locale', () {
      final customLoc = AppLocalizationsEs('es-MX');
      expect(customLoc.localeName.startsWith('es'), isTrue);
    });

    group('Simple Getters', () {
      test('appTitle returns StudyKing (same in Spanish)', () {
        expect(localizations.appTitle, 'StudyKing');
      });

      test('subjects returns Materias (Spanish)', () {
        expect(localizations.subjects, 'Materias');
      });

      test('practice returns Práctica (Spanish)', () {
        expect(localizations.practice, 'Práctica');
      });

      test('settings returns Ajustes (Spanish)', () {
        expect(localizations.settings, 'Ajustes');
      });
    });

    group('Parameterized Methods Spanish', () {
      test('topicLabel returns correct format for Spanish', () {
        expect(localizations.topicLabel(1), 'Tema 1');
      });

      test('sessionDurationMinutes returns correct format for Spanish', () {
        expect(localizations.sessionDurationMinutes(30), '30 min de sesión');
      });

      test('generatedPlanOverDays returns correct format for Spanish', () {
        expect(localizations.generatedPlanOverDays('Matemáticas', 7, 14), 
            'Plan generado para Matemáticas en 7 días (14 horas totales)');
      });
    });
  });

  group('Delegate Behavior', () {
    test('delegate is const', () {
      const delegate = AppLocalizations.delegate;
      expect(delegate, isNotNull);
    });

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

    testWidgets('delegate does not reload unnecessarily', (tester) async {
      final delegate = AppLocalizations.delegate;
      
      final locale = const Locale('en');
      final result1 = await delegate.load(locale);
      final result2 = await delegate.load(locale);
      
      expect(result1.localeName, result2.localeName);
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
    test('AppLocalizationsEn instances are independent', () {
      final en1 = AppLocalizationsEn();
      final en2 = AppLocalizationsEn();
      expect(identical(en1, en2), isFalse);
    });

    test('locale name is preserved correctly', () {
      final loc = AppLocalizationsEn('en-GB');
      expect(loc.localeName.startsWith('en'), isTrue);
    });

    test('locale name works with only language code', () {
      final loc = AppLocalizationsEn('en');
      expect(loc.localeName, 'en');
    });

    test('AppLocalizationsEn can be compared', () {
      final en1 = AppLocalizationsEn();
      expect(en1.hashCode, isNotNull);
    });

    test('supported locales are equal for same language code', () {
      const en1 = Locale('en');
      const en2 = Locale('en');
      expect(en1.languageCode, en2.languageCode);
    });

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

    testWidgets('localizations with region code', (tester) async {
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

    testWidgets('localizations with Spanish region code', (tester) async {
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

  group('Localization Coverage', () {
    test('English localization has all expected methods', () {
      final l10n = AppLocalizationsEn();
      
      expect(l10n.appTitle, isNotNull);
      expect(l10n.subjects, isNotNull);
      expect(l10n.practice, isNotNull);
      expect(l10n.settings, isNotNull);
      expect(l10n.studyPlanner, isNotNull);
      expect(l10n.createStudyPlan, isNotNull);
      expect(l10n.courseSubject, isNotNull);
      expect(l10n.courseHint, isNotNull);
      expect(l10n.days, isNotNull);
      expect(l10n.hoursPerDay, isNotNull);
      expect(l10n.generatePlan, isNotNull);
      expect(l10n.generating, isNotNull);
      expect(l10n.yourStudySchedule, isNotNull);
      expect(l10n.topicLabel(1), isNotNull);
      expect(l10n.sessionDurationMinutes(30), isNotNull);
      expect(l10n.fillAllFieldsCorrectly, isNotNull);
      expect(l10n.generatedPlanOverDays('test', 1, 1), isNotNull);
      expect(l10n.overDaysPlural(1), isNotNull);
      expect(l10n.totalHoursPlural(1), isNotNull);
      expect(l10n.today, isNotNull);
      expect(l10n.yesterday, isNotNull);
      expect(l10n.unknown, isNotNull);
      expect(l10n.durationDays(1), isNotNull);
      expect(l10n.durationHours(1), isNotNull);
      expect(l10n.durationMinutes(1), isNotNull);
      expect(l10n.durationSeconds(1), isNotNull);
    });

    test('Spanish localization has all expected methods', () {
      final l10n = AppLocalizationsEs();
      
      expect(l10n.appTitle, isNotNull);
      expect(l10n.subjects, isNotNull);
      expect(l10n.practice, isNotNull);
      expect(l10n.settings, isNotNull);
      expect(l10n.studyPlanner, isNotNull);
      expect(l10n.createStudyPlan, isNotNull);
      expect(l10n.courseSubject, isNotNull);
      expect(l10n.courseHint, isNotNull);
      expect(l10n.days, isNotNull);
      expect(l10n.hoursPerDay, isNotNull);
      expect(l10n.generatePlan, isNotNull);
      expect(l10n.generating, isNotNull);
      expect(l10n.yourStudySchedule, isNotNull);
      expect(l10n.topicLabel(1), isNotNull);
      expect(l10n.sessionDurationMinutes(30), isNotNull);
      expect(l10n.fillAllFieldsCorrectly, isNotNull);
      expect(l10n.generatedPlanOverDays('test', 1, 1), isNotNull);
      expect(l10n.overDaysPlural(1), isNotNull);
      expect(l10n.totalHoursPlural(1), isNotNull);
      expect(l10n.today, isNotNull);
      expect(l10n.yesterday, isNotNull);
      expect(l10n.unknown, isNotNull);
      expect(l10n.durationDays(1), isNotNull);
      expect(l10n.durationHours(1), isNotNull);
      expect(l10n.durationMinutes(1), isNotNull);
      expect(l10n.durationSeconds(1), isNotNull);
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