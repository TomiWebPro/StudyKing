import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

void main() {


  group('Widget Tests for Coverage Gaps', () {
    testWidgets('dashboard and mastery labels render correctly in English',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          final l = AppLocalizations.of(context)!;
          return SingleChildScrollView(
            child: Column(children: [
              Text(l.dashboard),
              Text(l.studyDashboard),
              Text(l.studyTime),
              Text(l.planAdherence),
              Text(l.topicPerformance),
              Text(l.achievements),
              Text(l.exportCsv),
              Text(l.overall),
              Text(l.thisWeek),
              Text(l.totalTopics),
              Text(l.mastered),
              Text(l.masteryLevelNovice),
              Text(l.masteryLevelBrowsing),
              Text(l.masteryLevelDeveloping),
              Text(l.masteryLevelProficient),
              Text(l.masteryLevelExpert),
            ]),
          );
        }),
      ));
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Study Dashboard'), findsOneWidget);
      expect(find.text('Study Time'), findsOneWidget);
      expect(find.text('Plan Adherence'), findsOneWidget);
      expect(find.text('Topic Performance'), findsOneWidget);
      expect(find.text('Achievements'), findsOneWidget);
      expect(find.text('Export CSV'), findsOneWidget);
      expect(find.text('Overall'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('Total Topics'), findsOneWidget);
      expect(find.text('Mastered'), findsOneWidget);
      expect(find.text('Novice'), findsWidgets);
      expect(find.text('Browsing'), findsOneWidget);
      expect(find.text('Developing'), findsOneWidget);
      expect(find.text('Proficient'), findsOneWidget);
    });

    testWidgets('error and accessibility labels render correctly in English',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          final l = AppLocalizations.of(context)!;
          return SingleChildScrollView(
            child: Column(children: [
              Text(l.accessibility),
              Text(l.highContrastMode),
              Text(l.errorNetworkConnection),
              Text(l.errorApiKeyMissing),
              Text(l.errorInvalidApiKey),
              Text(l.errorApiRateLimit),
              Text(l.errorApiNotFound),
              Text(l.errorApiInternalServer),
              Text(l.errorDatabase),
              Text(l.errorPdfParse),
              Text(l.errorContentGeneration),
              Text(l.errorLlmUnavailable),
              Text(l.errorApiAuth),
              Text(l.errorUnexpected),
              Text(l.retryConnection),
              Text(l.retryAfterWait),
            ]),
          );
        }),
      ));
      expect(find.text('Accessibility'), findsOneWidget);
      expect(find.text('High Contrast Mode'), findsOneWidget);
      expect(find.text('Retry Connection'), findsOneWidget);
      expect(find.text('Retry After Wait'), findsOneWidget);
    });

    testWidgets('analytics and metrics labels render correctly in English',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          final l = AppLocalizations.of(context)!;
          return SingleChildScrollView(
            child: Column(children: [
              Text(l.weeklyActivity),
              Text(l.readiness),
              Text(l.overallMastery),
              Text(l.avgTime),
              Text(l.badges),
              Text(l.sessionHistoryExport),
              Text(l.progressExportedCsv),
              Text(l.sessionHistoryExportedCsv),
              Text(l.exportPdf),
              Text(l.sessionHistoryExportedPdf),
              Text(l.labelJson),
              Text(l.failedToStartPractice),
            ]),
          );
        }),
      ));
      expect(find.text('Weekly Activity'), findsOneWidget);
      expect(find.text('Readiness'), findsOneWidget);
      expect(find.text('Overall Mastery'), findsOneWidget);
      expect(find.text('Avg Time'), findsOneWidget);
      expect(find.text('Badges'), findsOneWidget);
      expect(find.text('Session History'), findsWidgets);
      expect(find.text('Export PDF'), findsOneWidget);
    });

    testWidgets('parameterized recommendation labels render correctly',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          final l = AppLocalizations.of(context)!;
          return SingleChildScrollView(
            child: Column(children: [
              Text(l.recommendWeakTopics(3)),
            ]),
          );
        }),
      ));
      expect(
          find.text(
              'You have 3 topic(s) that need improvement. Focus on strengthening these areas.'),
          findsOneWidget);
    });
  });
}
