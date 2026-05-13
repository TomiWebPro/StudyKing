import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';
import 'package:studyking/l10n/generated/app_localizations_es.dart';

void main() {
  group('AppLocalizationsEn - Missing Simple Getters', () {
    late AppLocalizationsEn l10n;

    setUp(() {
      l10n = AppLocalizationsEn();
    });

    test('analytics and metrics section', () {
      expect(l10n.avgSession, 'Avg Session');
      expect(l10n.totalSessionsLabel, 'Total Sessions');
      expect(l10n.currentStreakLabel, 'Current Streak');
      expect(l10n.sessionsByDayOfWeek, 'Sessions by Day of Week');
      expect(l10n.performanceMetrics, 'Performance Metrics');
    });

    test('topic and lesson empty states', () {
      expect(l10n.noTopicsYetAddSome, 'No topics yet - add some!');
      expect(l10n.noLessonsUsePlanner, 'No lessons - use Planner to generate!');
    });

    test('block types', () {
      expect(l10n.blockTypeExplanation, 'Explanation');
      expect(l10n.blockTypeExample, 'Example');
      expect(l10n.blockTypeExercise, 'Exercise');
      expect(l10n.blockTypeSlide, 'Slide');
      expect(l10n.blockTypeQuiz, 'Quiz');
      expect(l10n.blockTypeSummary, 'Summary');
    });

    test('drawing submitted', () {
      expect(l10n.drawingSubmitted, 'Drawing submitted');
    });

    test('study plan section', () {
      expect(l10n.todaysPlan, 'Today\'s Plan');
      expect(l10n.noStudyPlanToday, 'No study plan for today');
    });

    test('at risk and ready to advance', () {
      expect(l10n.atRiskTopics, 'At Risk Topics');
      expect(l10n.noAtRiskTopics, 'No at-risk topics. Keep up the good work!');
      expect(l10n.readyToAdvance, 'Ready to Advance');
      expect(l10n.keepPracticingToUnlock, 'Keep practicing to unlock advanced topics!');
    });

    test('mastery overview section', () {
      expect(l10n.masteryOverview, 'Mastery Overview');
      expect(l10n.totalTopicsLabel, 'Total Topics');
      expect(l10n.masteredLabel, 'Mastered');
      expect(l10n.weakLabel, 'Weak');
    });

    test('quick guide additional messages', () {
      expect(l10n.quickGuideWelcomeMessage, 'Hello! I\'m StudyKing\'s Quick Guide. Ask me anything about your studies!');
      expect(l10n.suggestedPromptExplain, 'Explain photosynthesis');
      expect(l10n.suggestedPromptQuiz, 'Quiz me on history');
      expect(l10n.suggestedPromptMath, 'Help with math problems');
      expect(l10n.quickGuideHelpContent, 'Quick Guide is your AI study assistant. You can:\n\n\u2022 Ask questions about any subject\n\u2022 Request explanations for concepts\n\u2022 Get help with practice problems\n\nJust type your question and tap send!');
      expect(l10n.semanticsMessageInput, 'Message input for Quick Guide');
    });

    test('fallback AI responses', () {
      expect(l10n.fallbackExplainResponse, 'Sure! I can help explain concepts. What topic would you like me to explain?');
      expect(l10n.fallbackQuizResponse, 'I can help with questions! Ask away and I\'ll do my best.');
      expect(l10n.fallbackMathResponse, 'I\'d be happy to help with math! What specific problem or topic would you like to work on?');
      expect(l10n.fallbackGeneralResponse, 'That\'s an interesting question! Let me help you understand it better.');
    });

    test('about application details', () {
      expect(l10n.aboutApplicationName, 'StudyKing');
      expect(l10n.aboutVersion, 'v0.1.0');
      expect(l10n.aboutLegalese, '\u00a9 2026 StudyKing.');
    });

    test('model and miscellaneous helpers', () {
      expect(l10n.unknownModelId, 'unknown-model');
      expect(l10n.unknownProviderName, 'Unknown');
      expect(l10n.examDateOptionalLabel, 'Exam Date (Optional):');
      expect(l10n.lessonFallbackTitle, 'Lesson');
      expect(l10n.questionTypeDefault, 'Question');
      expect(l10n.durationSeparator, ' ');
    });
  });

  group('AppLocalizationsEn - Missing Parameterized Methods', () {
    late AppLocalizationsEn l10n;

    setUp(() {
      l10n = AppLocalizationsEn();
    });

    group('daysCount', () {
      test('one', () => expect(l10n.daysCount(1), '1 day'));
      test('other', () {
        expect(l10n.daysCount(2), '2 days');
        expect(l10n.daysCount(7), '7 days');
        expect(l10n.daysCount(30), '30 days');
      });
    });

    group('blocksCount', () {
      test('one', () => expect(l10n.blocksCount(1), '1 block'));
      test('other', () {
        expect(l10n.blocksCount(2), '2 blocks');
        expect(l10n.blocksCount(10), '10 blocks');
      });
    });

    test('practiceModeType', () {
      expect(l10n.practiceModeType('Quick Practice', 'MCQ'), 'Quick Practice - MCQ');
      expect(l10n.practiceModeType('Spaced Repetition', 'Text'), 'Spaced Repetition - Text');
    });

    test('fallbackOption', () {
      expect(l10n.fallbackOption(1), 'Option 1');
      expect(l10n.fallbackOption(2), 'Option 2');
      expect(l10n.fallbackOption(10), 'Option 10');
    });

    test('unsupportedQuestionType', () {
      expect(l10n.unsupportedQuestionType('audio'), 'Unsupported question type: audio');
      expect(l10n.unsupportedQuestionType('video'), 'Unsupported question type: video');
    });

    test('questionsCountMetric', () {
      expect(l10n.questionsCountMetric(0), '0 questions');
      expect(l10n.questionsCountMetric(5), '5 questions');
      expect(l10n.questionsCountMetric(100), '100 questions');
    });

    test('minutesCountMetric', () {
      expect(l10n.minutesCountMetric(0), '0 min');
      expect(l10n.minutesCountMetric(15), '15 min');
      expect(l10n.minutesCountMetric(60), '60 min');
    });

    test('accuracyLabel', () {
      expect(l10n.accuracyLabel('85%'), 'Accuracy: 85%');
      expect(l10n.accuracyLabel('100%'), 'Accuracy: 100%');
    });

    test('avgAccuracyLabel', () {
      expect(l10n.avgAccuracyLabel('75%'), 'Avg Accuracy: 75%');
    });

    test('avgReadinessLabel', () {
      expect(l10n.avgReadinessLabel('80%'), 'Avg Readiness: 80%');
    });

    test('courseSessionLabel', () {
      expect(l10n.courseSessionLabel('Math', 1), 'Math - Session 1');
      expect(l10n.courseSessionLabel('Physics', 5), 'Physics - Session 5');
    });

    test('semanticsYouSaid', () {
      expect(l10n.semanticsYouSaid('Hello'), 'You said: Hello');
      expect(l10n.semanticsYouSaid('What is 2+2?'), 'You said: What is 2+2?');
    });

    test('semanticsQuickGuideSaid', () {
      expect(l10n.semanticsQuickGuideSaid('The answer is 4'), 'Quick Guide said: The answer is 4');
    });

    test('semanticsSendPrompt', () {
      expect(l10n.semanticsSendPrompt('Explain physics'), 'Send prompt: Explain physics');
    });

    test('errorWithMessage', () {
      expect(l10n.errorWithMessage('Network failure'), 'Error: Network failure');
      expect(l10n.errorWithMessage(''), 'Error: ');
    });
  });

  group('AppLocalizationsEs - Missing Simple Getters', () {
    late AppLocalizationsEs l10n;

    setUp(() {
      l10n = AppLocalizationsEs();
    });

    test('analytics and metrics section', () {
      expect(l10n.avgSession, 'Sesión Prom.');
      expect(l10n.totalSessionsLabel, 'Sesiones Totales');
      expect(l10n.currentStreakLabel, 'Racha Actual');
      expect(l10n.sessionsByDayOfWeek, 'Sesiones por Día de la Semana');
      expect(l10n.performanceMetrics, 'Métricas de Rendimiento');
    });

    test('topic and lesson empty states', () {
      expect(l10n.noTopicsYetAddSome, '¿No hay temas? ¡agregue algunos!');
      expect(l10n.noLessonsUsePlanner, '¿No hay lecciones? ¡use el Planificador para generar!');
    });

    test('block types', () {
      expect(l10n.blockTypeExplanation, 'Explicación');
      expect(l10n.blockTypeExample, 'Ejemplo');
      expect(l10n.blockTypeExercise, 'Ejercicio');
      expect(l10n.blockTypeSlide, 'Diapositiva');
      expect(l10n.blockTypeQuiz, 'Cuestionario');
      expect(l10n.blockTypeSummary, 'Resumen');
    });

    test('drawing submitted', () {
      expect(l10n.drawingSubmitted, 'Dibujo enviado');
    });

    test('study plan section', () {
      expect(l10n.todaysPlan, 'Plan de Hoy');
      expect(l10n.noStudyPlanToday, 'No hay plan de estudio para hoy');
    });

    test('at risk and ready to advance', () {
      expect(l10n.atRiskTopics, 'Temas en Riesgo');
      expect(l10n.noAtRiskTopics, 'Sin temas en riesgo. ¡Siga así!');
      expect(l10n.readyToAdvance, 'Listo para Avanzar');
      expect(l10n.keepPracticingToUnlock, '¡Siga practicando para desbloquear temas avanzados!');
    });

    test('mastery overview section', () {
      expect(l10n.masteryOverview, 'Resumen de Dominio');
      expect(l10n.totalTopicsLabel, 'Total de Temas');
      expect(l10n.masteredLabel, 'Dominado');
      expect(l10n.weakLabel, 'Débil');
    });

    test('quick guide additional messages', () {
      expect(l10n.quickGuideWelcomeMessage, '¡Hola! Soy la Guía Rápida de StudyKing. ¡Pregúnteme lo que sea sobre sus estudios!');
      expect(l10n.suggestedPromptExplain, 'Explica la fotosíntesis');
      expect(l10n.suggestedPromptQuiz, 'Examíname de historia');
      expect(l10n.suggestedPromptMath, 'Ayuda con problemas de mates');
      expect(l10n.quickGuideHelpContent, 'Guía Rápida es su asistente de estudio con IA. Puede:\n\n\u2022 Hacer preguntas sobre cualquier materia\n\u2022 Solicitar explicaciones de conceptos\n\u2022 Obtener ayuda con problemas de práctica\n\n¡Solo escriba su pregunta y presione enviar!');
      expect(l10n.semanticsMessageInput, 'Campo de mensaje para Guía Rápida');
    });

    test('fallback AI responses', () {
      expect(l10n.fallbackExplainResponse, '¡Claro! Puedo ayudar a explicar conceptos. ¿Qué tema le gustaría que explique?');
      expect(l10n.fallbackQuizResponse, '¡Puedo ayudar con preguntas! Pregunte lo que quiera y haré lo mejor posible.');
      expect(l10n.fallbackMathResponse, '¡Estaré encantado de ayudar con matemáticas! ¿Qué problema o tema específico le gustaría trabajar?');
      expect(l10n.fallbackGeneralResponse, '¡Esa es una pregunta interesante! Déjeme ayudarle a entenderla mejor.');
    });

    test('about application details', () {
      expect(l10n.aboutApplicationName, 'StudyKing');
      expect(l10n.aboutVersion, 'v0.1.0');
      expect(l10n.aboutLegalese, '\u00a9 2026 StudyKing.');
    });

    test('model and miscellaneous helpers', () {
      expect(l10n.unknownModelId, 'unknown-model');
      expect(l10n.unknownProviderName, 'Desconocido');
      expect(l10n.examDateOptionalLabel, 'Fecha de Examen (Opcional):');
      expect(l10n.lessonFallbackTitle, 'Lección');
      expect(l10n.questionTypeDefault, 'Pregunta');
      expect(l10n.durationSeparator, ' ');
    });
  });

  group('AppLocalizationsEs - Missing Parameterized Methods', () {
    late AppLocalizationsEs l10n;

    setUp(() {
      l10n = AppLocalizationsEs();
    });

    group('daysCount', () {
      test('one', () => expect(l10n.daysCount(1), '1 día'));
      test('other', () {
        expect(l10n.daysCount(2), '2 días');
        expect(l10n.daysCount(7), '7 días');
      });
    });

    group('blocksCount', () {
      test('one', () => expect(l10n.blocksCount(1), '1 bloque'));
      test('other', () {
        expect(l10n.blocksCount(2), '2 bloques');
        expect(l10n.blocksCount(10), '10 bloques');
      });
    });

    test('practiceModeType', () {
      expect(l10n.practiceModeType('Rápida', 'Opción Múltiple'), 'Rápida - Opción Múltiple');
    });

    test('fallbackOption', () {
      expect(l10n.fallbackOption(1), 'Opción 1');
      expect(l10n.fallbackOption(3), 'Opción 3');
    });

    test('unsupportedQuestionType', () {
      expect(l10n.unsupportedQuestionType('audio'), 'Tipo de pregunta no compatible: audio');
    });

    test('questionsCountMetric', () {
      expect(l10n.questionsCountMetric(0), '0 preguntas');
      expect(l10n.questionsCountMetric(5), '5 preguntas');
    });

    test('minutesCountMetric', () {
      expect(l10n.minutesCountMetric(0), '0 min');
      expect(l10n.minutesCountMetric(30), '30 min');
    });

    test('accuracyLabel', () {
      expect(l10n.accuracyLabel('85%'), 'Precisión: 85%');
    });

    test('avgAccuracyLabel', () {
      expect(l10n.avgAccuracyLabel('75%'), 'Precisión Prom.: 75%');
    });

    test('avgReadinessLabel', () {
      expect(l10n.avgReadinessLabel('80%'), 'Disposición Prom.: 80%');
    });

    test('courseSessionLabel', () {
      expect(l10n.courseSessionLabel('Matemáticas', 1), 'Matemáticas - Sesión 1');
    });

    test('semanticsYouSaid', () {
      expect(l10n.semanticsYouSaid('Hola'), 'Usted dijo: Hola');
    });

    test('semanticsQuickGuideSaid', () {
      expect(l10n.semanticsQuickGuideSaid('La respuesta es 4'), 'Guía Rápida dijo: La respuesta es 4');
    });

    test('semanticsSendPrompt', () {
      expect(l10n.semanticsSendPrompt('Explica física'), 'Enviar sugerencia: Explica física');
    });

    test('errorWithMessage', () {
      expect(l10n.errorWithMessage('Error de red'), 'Error: Error de red');
    });
  });

  group('Edge Case Tests for Plural Rules', () {
    group('English additional plurals', () {
      late AppLocalizationsEn l10n;
      setUp(() => l10n = AppLocalizationsEn());

      test('daysCount handles zero correctly', () {
        expect(l10n.daysCount(0), '0 days');
      });

      test('blocksCount handles zero correctly', () {
        expect(l10n.blocksCount(0), '0 blocks');
      });

      test('durationDays handles zero', () {
        expect(l10n.durationDays(0), '0d');
      });

      test('durationHours handles zero', () {
        expect(l10n.durationHours(0), '0h');
      });

      test('durationMinutes handles zero', () {
        expect(l10n.durationMinutes(0), '0m');
      });

      test('durationSeconds handles zero', () {
        expect(l10n.durationSeconds(0), '0s');
      });

      test('overDaysPlural handles large numbers', () {
        expect(l10n.overDaysPlural(365), 'over 365 days');
        expect(l10n.overDaysPlural(1000), 'over 1000 days');
      });

      test('totalHoursPlural handles zero', () {
        expect(l10n.totalHoursPlural(0), '0 total hours');
      });
    });

    group('Spanish additional plurals', () {
      late AppLocalizationsEs l10n;
      setUp(() => l10n = AppLocalizationsEs());

      test('daysCount handles zero correctly', () {
        expect(l10n.daysCount(0), '0 días');
      });

      test('blocksCount handles zero correctly', () {
        expect(l10n.blocksCount(0), '0 bloques');
      });

      test('durationDays handles zero', () {
        expect(l10n.durationDays(0), '0d');
      });

      test('durationHours handles zero', () {
        expect(l10n.durationHours(0), '0h');
      });

      test('durationMinutes handles zero', () {
        expect(l10n.durationMinutes(0), '0min');
      });

      test('durationSeconds handles zero', () {
        expect(l10n.durationSeconds(0), '0s');
      });

      test('overDaysPlural handles large numbers', () {
        expect(l10n.overDaysPlural(365), 'en 365 días');
      });

      test('totalHoursPlural handles zero', () {
        expect(l10n.totalHoursPlural(0), '0 horas totales');
      });
    });
  });

  group('Constructor Custom Locale Tests', () {
    test('AppLocalizationsEn accepts custom locale string', () {
      final en = AppLocalizationsEn('en-US');
      expect(en.localeName, 'en_US');
    });

    test('AppLocalizationsEn accepts empty locale string', () {
      final en = AppLocalizationsEn('');
      expect(en.localeName, '');
    });

    test('AppLocalizationsEs accepts custom locale string', () {
      final es = AppLocalizationsEs('es-AR');
      expect(es.localeName, 'es_AR');
    });

    test('AppLocalizationsEs accepts empty locale string', () {
      final es = AppLocalizationsEs('');
      expect(es.localeName, '');
    });

    test('AppLocalizationsEn is an AppLocalizations', () {
      expect(AppLocalizationsEn(), isA<AppLocalizations>());
    });

    test('AppLocalizationsEs is an AppLocalizations', () {
      expect(AppLocalizationsEs(), isA<AppLocalizations>());
    });
  });

  group('Additional AppLocalizations Static Tests', () {
    test('supportedLocales contains only en and es', () {
      expect(AppLocalizations.supportedLocales.length, 2);
      for (final locale in AppLocalizations.supportedLocales) {
        expect(['en', 'es'], contains(locale.languageCode));
      }
    });

    test('localizationsDelegates is const and contains expected count', () {
      const delegates = AppLocalizations.localizationsDelegates;
      expect(delegates.length, 4);
    });

    test('delegate hashcode is stable across calls', () {
      final d1 = AppLocalizations.delegate;
      final d2 = AppLocalizations.delegate;
      expect(d1.hashCode, equals(d2.hashCode));
    });

    test('delegate toString returns something', () {
      expect(AppLocalizations.delegate.toString(), isNotEmpty);
    });
  });

  group('Widget Tests for Missing Localizations', () {
    testWidgets('localized bottom nav labels render correctly in Spanish', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
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

      expect(find.text('Materias'), findsOneWidget);
      expect(find.text('Práctica'), findsOneWidget);
      expect(find.text('Ajustes'), findsOneWidget);
    });

    testWidgets('all mastery labels accessible in widget tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Text(l10n.masteryOverview),
                    Text(l10n.totalTopicsLabel),
                    Text(l10n.masteredLabel),
                    Text(l10n.weakLabel),
                    Text(l10n.accuracyLabel('80%')),
                    Text(l10n.avgAccuracyLabel('75%')),
                    Text(l10n.avgReadinessLabel('85%')),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Mastery Overview'), findsOneWidget);
      expect(find.text('Total Topics'), findsOneWidget);
      expect(find.text('Mastered'), findsOneWidget);
      expect(find.text('Weak'), findsOneWidget);
      expect(find.text('Accuracy: 80%'), findsOneWidget);
      expect(find.text('Avg Accuracy: 75%'), findsOneWidget);
      expect(find.text('Avg Readiness: 85%'), findsOneWidget);
    });

    testWidgets('block types and study plan labels in widget tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Text(l10n.blockTypeExplanation),
                    Text(l10n.blockTypeExample),
                    Text(l10n.blockTypeExercise),
                    Text(l10n.blockTypeSlide),
                    Text(l10n.blockTypeQuiz),
                    Text(l10n.blockTypeSummary),
                    Text(l10n.blocksCount(3)),
                    Text(l10n.todaysPlan),
                    Text(l10n.noStudyPlanToday),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Explanation'), findsOneWidget);
      expect(find.text('Example'), findsOneWidget);
      expect(find.text('Exercise'), findsOneWidget);
      expect(find.text('Slide'), findsOneWidget);
      expect(find.text('Quiz'), findsOneWidget);
      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('3 blocks'), findsOneWidget);
      expect(find.text('Today\'s Plan'), findsOneWidget);
      expect(find.text('No study plan for today'), findsOneWidget);
    });

    testWidgets('at-risk and ready-to-advance labels in widget tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Text(l10n.atRiskTopics),
                    Text(l10n.noAtRiskTopics),
                    Text(l10n.readyToAdvance),
                    Text(l10n.keepPracticingToUnlock),
                    Text(l10n.practiceModeType('Quick', 'MCQ')),
                    Text(l10n.fallbackOption(2)),
                    Text(l10n.unsupportedQuestionType('audio')),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('At Risk Topics'), findsOneWidget);
      expect(find.text('No at-risk topics. Keep up the good work!'), findsOneWidget);
      expect(find.text('Ready to Advance'), findsOneWidget);
      expect(find.text('Keep practicing to unlock advanced topics!'), findsOneWidget);
      expect(find.text('Quick - MCQ'), findsOneWidget);
      expect(find.text('Option 2'), findsOneWidget);
      expect(find.text('Unsupported question type: audio'), findsOneWidget);
    });

    testWidgets('quick guide extended labels in widget tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Text(l10n.quickGuideWelcomeMessage),
                    Text(l10n.suggestedPromptExplain),
                    Text(l10n.suggestedPromptQuiz),
                    Text(l10n.suggestedPromptMath),
                    Text(l10n.semanticsMessageInput),
                    Text(l10n.fallbackExplainResponse),
                    Text(l10n.fallbackQuizResponse),
                    Text(l10n.fallbackMathResponse),
                    Text(l10n.fallbackGeneralResponse),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Hello! I\'m StudyKing\'s Quick Guide. Ask me anything about your studies!'), findsOneWidget);
      expect(find.text('Explain photosynthesis'), findsOneWidget);
      expect(find.text('Quiz me on history'), findsOneWidget);
      expect(find.text('Help with math problems'), findsOneWidget);
      expect(find.text('Message input for Quick Guide'), findsOneWidget);
    });

    testWidgets('session analytics labels in widget tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Column(
                children: [
                  Text(l10n.avgSession),
                  Text(l10n.totalSessionsLabel),
                  Text(l10n.currentStreakLabel),
                  Text(l10n.sessionsByDayOfWeek),
                  Text(l10n.performanceMetrics),
                  Text(l10n.daysCount(5)),
                  Text(l10n.courseSessionLabel('Math', 3)),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('Avg Session'), findsOneWidget);
      expect(find.text('Total Sessions'), findsOneWidget);
      expect(find.text('Current Streak'), findsOneWidget);
      expect(find.text('Sessions by Day of Week'), findsOneWidget);
      expect(find.text('Performance Metrics'), findsOneWidget);
      expect(find.text('5 days'), findsOneWidget);
      expect(find.text('Math - Session 3'), findsOneWidget);
    });

    testWidgets('about and misc labels in widget tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Text(l10n.aboutApplicationName),
                    Text(l10n.aboutVersion),
                    Text(l10n.aboutLegalese),
                    Text(l10n.unknownModelId),
                    Text(l10n.unknownProviderName),
                    Text(l10n.examDateOptionalLabel),
                    Text(l10n.lessonFallbackTitle),
                    Text(l10n.questionTypeDefault),
                    Text('"${l10n.durationSeparator}"'),
                    Text(l10n.errorWithMessage('test')),
                    Text(l10n.semanticsYouSaid('hi')),
                    Text(l10n.semanticsQuickGuideSaid('hello')),
                    Text(l10n.semanticsSendPrompt('explain')),
                    Text(l10n.drawingSubmitted),
                    Text(l10n.questionsCountMetric(3)),
                    Text(l10n.minutesCountMetric(45)),
                    Text(l10n.noTopicsYetAddSome),
                    Text(l10n.noLessonsUsePlanner),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('StudyKing'), findsOneWidget);
      expect(find.text('v0.1.0'), findsOneWidget);
      expect(find.text('\u00a9 2026 StudyKing.'), findsOneWidget);
      expect(find.text('unknown-model'), findsOneWidget);
      expect(find.text('Unknown'), findsOneWidget);
      expect(find.text('Exam Date (Optional):'), findsOneWidget);
      expect(find.text('Lesson'), findsOneWidget);
      expect(find.text('Question'), findsOneWidget);
      expect(find.text('" "'), findsOneWidget);
      expect(find.text('Error: test'), findsOneWidget);
      expect(find.text('You said: hi'), findsOneWidget);
      expect(find.text('Quick Guide said: hello'), findsOneWidget);
      expect(find.text('Send prompt: explain'), findsOneWidget);
      expect(find.text('Drawing submitted'), findsOneWidget);
      expect(find.text('3 questions'), findsOneWidget);
      expect(find.text('45 min'), findsOneWidget);
      expect(find.text('No topics yet - add some!'), findsOneWidget);
      expect(find.text('No lessons - use Planner to generate!'), findsOneWidget);
    });
  });

  group('Locale Switching with Missing Locales', () {
    testWidgets('localizations fall back when no locale specified', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Text(l10n.subjects);
            },
          ),
        ),
      );

      expect(find.text('Subjects'), findsOneWidget);
    });

    testWidgets('localization works for all supported locales', (tester) async {
      for (final locale in AppLocalizations.supportedLocales) {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(l10n.appTitle);
              },
            ),
          ),
        );

        expect(find.text('StudyKing'), findsOneWidget);
      }
    });
  });

  group('lookupAppLocalizations Edge Cases', () {
    test('returns AppLocalizationsEn for en-US', () {
      final result = lookupAppLocalizations(const Locale('en', 'US'));
      expect(result, isA<AppLocalizationsEn>());
    });

    test('returns AppLocalizationsEs for es-ES', () {
      final result = lookupAppLocalizations(const Locale('es', 'ES'));
      expect(result, isA<AppLocalizationsEs>());
    });

    test('throws FlutterError for null-like unsupported locale', () {
      expect(
        () => lookupAppLocalizations(const Locale('xx')),
        throwsA(isA<FlutterError>()),
      );
    });
  });

  group('delegate.shouldReload', () {
    test('shouldReload returns false for same delegate type', () {
      final delegate = AppLocalizations.delegate;
      expect(delegate.shouldReload(delegate), isFalse);
    });

    test('shouldReload returns false for new delegate', () {
      final delegate1 = AppLocalizations.delegate;
      final delegate2 = AppLocalizations.delegate;
      expect(delegate1.shouldReload(delegate2), isFalse);
    });
  });
}
