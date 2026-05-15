import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';
import 'package:studyking/l10n/generated/app_localizations_es.dart';

void main() {
  group('AppLocalizationsEn - Coverage Gaps', () {
    late AppLocalizationsEn l10n;

    setUp(() {
      l10n = AppLocalizationsEn();
    });

    group('Simple Getters', () {
      test('retry', () {
        expect(l10n.retry, 'Retry');
      });

      test('imageCaptured', () {
        expect(l10n.imageCaptured,
            'Image captured. You can add notes in the content field above.');
      });

      test('difficultyMedium', () {
        expect(l10n.difficultyMedium, 'Medium');
      });

      test('dashboard section', () {
        expect(l10n.dashboard, 'Dashboard');
        expect(l10n.studyDashboard, 'Study Dashboard');
        expect(l10n.studyTime, 'Study Time');
        expect(l10n.planAdherence, 'Plan Adherence');
        expect(l10n.topicPerformance, 'Topic Performance');
        expect(l10n.achievements, 'Achievements');
        expect(l10n.exportCsv, 'Export CSV');
        expect(l10n.instrumentation, 'Instrumentation');
        expect(l10n.overall, 'Overall');
        expect(l10n.thisWeek, 'This Week');
        expect(l10n.totalTopics, 'Total Topics');
        expect(l10n.mastered, 'Mastered');
        expect(l10n.topics, 'Topics');
        expect(l10n.practiceAllWeakAreas, 'Practice All Weak Areas');
        expect(l10n.practiceThisTopic, 'Practice this topic');
        expect(l10n.noTopicDataYet,
            'No topic data yet. Start studying to see your progress!');
      });

      test('mastery levels', () {
        expect(l10n.masteryLevelNovice, 'Novice');
        expect(l10n.masteryLevelBrowsing, 'Browsing');
        expect(l10n.masteryLevelDeveloping, 'Developing');
        expect(l10n.masteryLevelProficient, 'Proficient');
        expect(l10n.masteryLevelExpert, 'Expert');
      });

      test('accessibility section', () {
        expect(l10n.accessibility, 'Accessibility');
        expect(l10n.highContrastMode, 'High Contrast Mode');
        expect(l10n.highContrastDescription,
            'Increase contrast for better visibility');
        expect(l10n.largeTouchTargets, 'Large Touch Targets');
        expect(l10n.largeTouchTargetsDescription,
            'Increase tap target sizes');
        expect(l10n.reduceMotion, 'Reduce Motion');
        expect(l10n.reduceMotionDescription,
            'Reduce or disable motion animations');
      });

      test('error messages section', () {
        expect(l10n.errorNetworkConnection,
            'Unable to connect to the server. Please check your internet connection and try again.');
        expect(l10n.errorApiKeyMissing,
            'API key is required. Please configure it in Settings.');
        expect(l10n.errorInvalidApiKey,
            'Invalid API key. Please check your credentials in Settings.');
        expect(l10n.errorApiRateLimit,
            'Too many requests. Please wait a moment and try again.');
        expect(l10n.errorApiNotFound, 'The requested resource was not found.');
        expect(l10n.errorApiInternalServer,
            'The server encountered an error. Please try again later.');
        expect(l10n.errorDatabase,
            'A database error occurred. Please try again.');
        expect(l10n.errorPdfParse,
            'Unable to parse the PDF file. Please ensure it is a valid PDF.');
        expect(l10n.errorContentGeneration,
            'Failed to generate content. Please try again.');
        expect(l10n.errorLlmUnavailable,
            'The AI service is temporarily unavailable. Please try again.');
        expect(l10n.errorApiAuth,
            'Authentication failed. Please check your API credentials.');
        expect(l10n.errorUnexpected,
            'An unexpected error occurred. Please try again.');
        expect(l10n.retryConnection, 'Retry Connection');
        expect(l10n.retryAfterWait, 'Retry After Wait');
      });

      test('analytics metrics section', () {
        expect(l10n.weeklyActivity, 'Weekly Activity');
        expect(l10n.topicsLabel, 'Topics');
        expect(l10n.readiness, 'Readiness');
        expect(l10n.overallMastery, 'Overall Mastery');
        expect(l10n.avgTime, 'Avg Time');
        expect(l10n.badges, 'Badges');
        expect(l10n.sessionHistoryExport, 'Session History');
        expect(l10n.progressExportedCsv, 'Progress exported to CSV');
        expect(l10n.sessionHistoryExportedCsv,
            'Session history exported to CSV');
        expect(l10n.exportPdf, 'Export PDF');
        expect(l10n.sessionHistoryExportedPdf,
            'Session history exported to PDF');
        expect(l10n.labelJson, 'JSON');
        expect(l10n.failedToStartPractice,
            'Failed to start practice session');
      });
    });

    group('Parameterized Methods', () {
      test('recommendationWeakTopics', () {
        expect(l10n.recommendationWeakTopics(1),
            'You have 1 topic(s) that need improvement. Focus on strengthening these areas.');
        expect(l10n.recommendationWeakTopics(3),
            'You have 3 topic(s) that need improvement. Focus on strengthening these areas.');
        expect(l10n.recommendationWeakTopics(0),
            'You have 0 topic(s) that need improvement. Focus on strengthening these areas.');
      });
    });
  });

  group('AppLocalizationsEs - Coverage Gaps', () {
    late AppLocalizationsEs l10n;

    setUp(() {
      l10n = AppLocalizationsEs();
    });

    group('Simple Getters', () {
      test('retry', () {
        expect(l10n.retry, 'Reintentar');
      });

      test('imageCaptured', () {
        expect(l10n.imageCaptured,
            'Imagen capturada. Puede agregar notas en el campo de contenido arriba.');
      });

      test('difficultyMedium', () {
        expect(l10n.difficultyMedium, 'Medio');
      });

      test('dashboard section', () {
        expect(l10n.dashboard, 'Panel');
        expect(l10n.studyDashboard, 'Panel de Estudio');
        expect(l10n.studyTime, 'Tiempo de Estudio');
        expect(l10n.planAdherence, 'Cumplimiento del Plan');
        expect(l10n.topicPerformance, 'Rendimiento por Tema');
        expect(l10n.achievements, 'Logros');
        expect(l10n.exportCsv, 'Exportar CSV');
        expect(l10n.instrumentation, 'Instrumentación');
        expect(l10n.overall, 'General');
        expect(l10n.thisWeek, 'Esta Semana');
        expect(l10n.totalTopics, 'Temas Totales');
        expect(l10n.mastered, 'Dominados');
        expect(l10n.topics, 'Temas');
        expect(l10n.practiceAllWeakAreas,
            'Practicar Todas las Áreas Débiles');
        expect(l10n.practiceThisTopic, 'Practicar este tema');
        expect(l10n.noTopicDataYet,
            'Aún no hay datos de temas. ¡Empiece a estudiar para ver su progreso!');
      });

      test('mastery levels', () {
        expect(l10n.masteryLevelNovice, 'Novato');
        expect(l10n.masteryLevelBrowsing, 'Explorando');
        expect(l10n.masteryLevelDeveloping, 'En Desarrollo');
        expect(l10n.masteryLevelProficient, 'Competente');
        expect(l10n.masteryLevelExpert, 'Experto');
      });

      test('accessibility section', () {
        expect(l10n.accessibility, 'Accesibilidad');
        expect(l10n.highContrastMode, 'Modo de Alto Contraste');
        expect(l10n.highContrastDescription,
            'Aumente el contraste para mejor visibilidad');
        expect(l10n.largeTouchTargets, 'Objetivos Táctiles Grandes');
        expect(l10n.largeTouchTargetsDescription,
            'Aumente el tamaño de los objetivos táctiles');
        expect(l10n.reduceMotion, 'Reducir movimiento');
        expect(l10n.reduceMotionDescription,
            'Reducir o desactivar animaciones de movimiento');
      });

      test('error messages section', () {
        expect(l10n.errorNetworkConnection,
            'No se puede conectar al servidor. Verifique su conexión a internet e intente de nuevo.');
        expect(l10n.errorApiKeyMissing,
            'Se requiere una clave API. Configúrela en Ajustes.');
        expect(l10n.errorInvalidApiKey,
            'Clave API no válida. Verifique sus credenciales en Ajustes.');
        expect(l10n.errorApiRateLimit,
            'Demasiadas solicitudes. Espere un momento e intente de nuevo.');
        expect(l10n.errorApiNotFound,
            'El recurso solicitado no fue encontrado.');
        expect(l10n.errorApiInternalServer,
            'El servidor encontró un error. Intente de nuevo más tarde.');
        expect(l10n.errorDatabase,
            'Ocurrió un error de base de datos. Intente de nuevo.');
        expect(l10n.errorPdfParse,
            'No se puede analizar el archivo PDF. Asegúrese de que sea un PDF válido.');
        expect(l10n.errorContentGeneration,
            'Error al generar contenido. Intente de nuevo.');
        expect(l10n.errorLlmUnavailable,
            'El servicio de IA no está disponible temporalmente. Intente de nuevo.');
        expect(l10n.errorApiAuth,
            'Error de autenticación. Verifique sus credenciales de API.');
        expect(l10n.errorUnexpected,
            'Ocurrió un error inesperado. Intente de nuevo.');
        expect(l10n.retryConnection, 'Reintentar Conexión');
        expect(l10n.retryAfterWait, 'Reintentar Después');
      });

      test('analytics metrics section', () {
        expect(l10n.weeklyActivity, 'Actividad Semanal');
        expect(l10n.topicsLabel, 'Temas');
        expect(l10n.readiness, 'Disposición');
        expect(l10n.overallMastery, 'Dominio General');
        expect(l10n.avgTime, 'Tiempo Prom.');
        expect(l10n.badges, 'Insignias');
        expect(l10n.sessionHistoryExport, 'Historial de Sesiones');
        expect(l10n.progressExportedCsv, 'Progreso exportado a CSV');
        expect(l10n.sessionHistoryExportedCsv,
            'Historial de sesiones exportado a CSV');
        expect(l10n.exportPdf, 'Exportar PDF');
        expect(l10n.sessionHistoryExportedPdf,
            'Historial de sesiones exportado a PDF');
        expect(l10n.labelJson, 'JSON');
        expect(l10n.failedToStartPractice,
            'Error al iniciar la sesión de práctica');
      });
    });

    group('Parameterized Methods', () {
      test('recommendationWeakTopics', () {
        expect(l10n.recommendationWeakTopics(1),
            'Tiene 1 tema(s) que necesitan mejorar. Concéntrese en fortalecer estas áreas.');
        expect(l10n.recommendationWeakTopics(3),
            'Tiene 3 tema(s) que necesitan mejorar. Concéntrese en fortalecer estas áreas.');
        expect(l10n.recommendationWeakTopics(0),
            'Tiene 0 tema(s) que necesitan mejorar. Concéntrese en fortalecer estas áreas.');
      });
    });
  });

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
              Text(l.recommendationWeakTopics(3)),
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
