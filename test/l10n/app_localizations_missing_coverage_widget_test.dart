import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

// ignore_for_file: type=lint

void main() {
  group('Widget Tests for Missing Coverage', () {
    testWidgets('renders batch_1 keys correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          final l = AppLocalizations.of(context)!;
          return SingleChildScrollView(
            child: Column(children: [
              Text(l.backupAndRestore),
              Text(l.noThanks),
              Text(l.onboardingDescription),
              Text(l.pageNotFound),
              Text(l.prerequisites),
              Text(l.progressOverview),
              Text(l.recordAudio),
              Text(l.sourcePractice),
              Text(l.startExam),
              Text(l.summary),
            ]),
          );
        }),
      ));
      expect(find.text('Backup & Restore'), findsOneWidget);
      expect(find.text('No thanks'), findsOneWidget);
      expect(find.text('Your AI-native learning companion. StudyKing helps you master any subject with intelligent planning, adaptive practice, and AI tutoring.'), findsOneWidget);
      expect(find.text('Page not found'), findsOneWidget);
      expect(find.text('Prerequisites'), findsOneWidget);
      expect(find.text('Progress Overview'), findsOneWidget);
      expect(find.text('Record audio'), findsOneWidget);
      expect(find.text('Source Practice'), findsOneWidget);
      expect(find.text('Start Exam'), findsOneWidget);
      expect(find.text('Summary'), findsOneWidget);
    });

    testWidgets('renders batch_2 keys correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          final l = AppLocalizations.of(context)!;
          return SingleChildScrollView(
            child: Column(children: [
              Text(l.unsavedChanges),
              Text(l.uploadMaterial),
              Text(l.welcomeBackDays(3)),
            ]),
          );
        }),
      ));
      expect(find.text('Unsaved Changes'), findsOneWidget);
      expect(find.text('Upload Study Material'), findsOneWidget);
      expect(find.text('Welcome back! You\'ve been away for 3 days.'), findsOneWidget);
    });

  });
}