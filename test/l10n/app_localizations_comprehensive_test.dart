import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';
import 'package:studyking/l10n/generated/app_localizations_es.dart';

void main() {
  group('AppLocalizationsEn - Remaining Simple Getters', () {
    late AppLocalizationsEn l10n;

    setUp(() {
      l10n = AppLocalizationsEn();
    });

    test('mentor and tutor section', () {
      expect(l10n.mentor, 'Mentor');
      expect(l10n.aiTutor, 'AI Tutor');
      expect(l10n.startAiTutoring, 'Start AI Tutoring');
      expect(l10n.endLesson, 'End Lesson');
      expect(l10n.typeYourMessage, 'Type your message...');
      expect(l10n.send, 'Send');
      expect(l10n.progressReport, 'Progress Report');
      expect(l10n.askMentorAnything, 'Ask your mentor anything...');
      expect(l10n.mentorGreeting, 'AI Mentor');
      expect(l10n.mentorSubtitle, 'Your personal AI academic assistant');
      expect(l10n.startingLesson, 'Starting your lesson...');
      expect(l10n.lessonTimeEnded, 'Lesson time has ended. Click \'End Lesson\' to finish.');
      expect(l10n.lessonComplete, 'Lesson Complete');
      expect(l10n.errorOccurred, 'An error occurred. Please try again.');
      expect(l10n.errorWithResponse, 'Sorry, I encountered an error. Please try again.');
      expect(l10n.inProgress, 'In Progress');
      expect(l10n.completed, 'Completed');
      expect(l10n.notStarted, 'Not Started');
      expect(l10n.mentorWelcomeBody,
          'I can help with:\n• Scheduling and rescheduling lessons\n• Reviewing your study progress\n• Planning long-term study goals\n• Motivation and encouragement\n• Deciding what to study next\n\nHow can I help you today?');
    });

    test('roadmap section', () {
      expect(l10n.roadmaps, 'Roadmaps');
      expect(l10n.createRoadmap, 'Create Roadmap');
      expect(l10n.roadmapGoal, 'Learning Goal');
      expect(l10n.roadmapGoalHint, 'e.g., I want to learn Python in 90 days');
      expect(l10n.generateRoadmap, 'Generate Roadmap');
      expect(l10n.myRoadmaps, 'My Roadmaps');
      expect(l10n.milestones, 'Milestones');
      expect(l10n.milestone, 'Milestone');
      expect(l10n.targetCompletion, 'Target Completion');
      expect(l10n.noRoadmapsYet, 'No roadmaps yet');
      expect(l10n.timeline, 'Timeline');
    });

    test('notification settings section', () {
      expect(l10n.enableNotifications, 'Enable Notifications');
      expect(l10n.notificationPreferences, 'Notification Preferences');
      expect(l10n.dailyReminders, 'Daily Reminders');
      expect(l10n.revisionReminders, 'Revision Reminders');
      expect(l10n.notifChannelLessons, 'Lesson Notifications');
      expect(l10n.overworkAlerts, 'Overwork Alerts');
      expect(l10n.planAdjustmentNotifications, 'Plan Adjustment Alerts');
      expect(l10n.quietHours, 'Quiet Hours');
      expect(l10n.quietHoursStart, 'Quiet Hours Start');
      expect(l10n.quietHoursEnd, 'Quiet Hours End');
    });

    test('comprehensive export section', () {
      expect(l10n.exportComprehensiveReport, 'Export Full Progress Report');
      expect(l10n.comprehensiveCsv, 'Full Progress CSV');
      expect(l10n.comprehensivePdf, 'Full Progress PDF');
      expect(l10n.comprehensiveJson, 'Full Progress JSON');
      expect(l10n.comprehensiveReportExported, 'Comprehensive progress report exported');
    });

    test('roadmap metrics section', () {
      expect(l10n.activeRoadmaps, 'Active Roadmaps');
      expect(l10n.completedRoadmaps, 'Completed Roadmaps');
      expect(l10n.progressBySubject, 'Progress by Subject');
    });

    test('answer feedback section', () {
      expect(l10n.markschemeUnavailable, 'No markscheme available');
      expect(l10n.answerTooShort, 'Answer is too short. Please provide more details.');
      expect(l10n.goodResponseLength, 'Good response length.');
      expect(l10n.answerTooShortForCredit, 'Answer too short for full credit.');
      expect(l10n.noDrawingDetected, 'No drawing detected. Please draw something.');
      expect(l10n.invalidDrawingData, 'Invalid drawing data. Please redraw.');
      expect(l10n.allStepsIdentified, 'All required steps identified.');
      expect(l10n.specialHandlingRequired, 'This question type requires special handling.');
      expect(l10n.someAnswersIncorrect, 'Some answers are incorrect');
      expect(l10n.allRequiredStepsMissing, 'Some required steps missing');
    });

    test('focus mode and timer section', () {
      expect(l10n.focusMode, 'Study');
      expect(l10n.newFocusSession, 'New Focus Session');
      expect(l10n.refreshStats, 'Refresh stats');
      expect(l10n.dailyLimitReached, 'Daily Limit Reached');
      expect(l10n.dailyLimitReachedBody,
          'You\'ve reached your daily study limit — well done! Take a rest and come back tomorrow.');
      expect(l10n.breakTime, 'Break Time!');
      expect(l10n.focusTime, 'Focus Time');
      expect(l10n.timerRemaining, 'remaining');
      expect(l10n.timerPaused, 'PAUSED');
      expect(l10n.timerDone, 'DONE!');
      expect(l10n.resume, 'Resume');
      expect(l10n.pause, 'Pause');
      expect(l10n.markComplete, 'Mark Complete');
    });

    test('CSV column labels', () {
      expect(l10n.csvOverallStats, 'OVERALL STATS');
      expect(l10n.csvTopicMastery, 'TOPIC MASTERY');
      expect(l10n.csvAllAttempts, 'ALL ATTEMPTS');
      expect(l10n.csvWeeklyTrend, 'WEEKLY TREND');
      expect(l10n.csvBadges, 'BADGES');
      expect(l10n.csvColTotalAttempts, 'Total Attempts');
      expect(l10n.csvColCorrect, 'Correct');
      expect(l10n.csvColAccuracy, 'Accuracy (%)');
      expect(l10n.csvColAvgTime, 'Avg Time (s)');
      expect(l10n.csvColTotalHours, 'Total Hours');
      expect(l10n.csvColWeeklyActivity, 'Weekly Activity');
      expect(l10n.csvColDailyActivity, 'Daily Activity');
      expect(l10n.csvColTopicsStudied, 'Topics Studied');
      expect(l10n.csvColTopicId, 'Topic ID');
      expect(l10n.csvColMasteryLevel, 'Mastery Level');
      expect(l10n.csvColLastPracticed, 'Last Practiced');
      expect(l10n.csvColReviewUrgency, 'Review Urgency');
      expect(l10n.csvColQuestionId, 'Question ID');
      expect(l10n.csvColSubjectId, 'Subject ID');
      expect(l10n.csvColTime, 'Time (s)');
      expect(l10n.csvColTimestamp, 'Timestamp');
      expect(l10n.csvColWeek, 'Week');
      expect(l10n.csvColAttempts, 'Attempts');
      expect(l10n.csvColImprovement, 'Improvement');
      expect(l10n.csvColBadgeName, 'Badge Name');
      expect(l10n.csvColBadgeDescription, 'Description');
      expect(l10n.csvColDateUnlocked, 'Date Unlocked');
    });

    test('PDF report labels', () {
      expect(l10n.pdfProgressReport, 'StudyKing Progress Report');
      expect(l10n.pdfOverallStatistics, 'Overall Statistics');
      expect(l10n.pdfMetric, 'Metric');
      expect(l10n.pdfValue, 'Value');
      expect(l10n.pdfTopicMasteryBreakdown, 'Topic Mastery Breakdown');
      expect(l10n.pdfTableAttempts, 'Attempts');
      expect(l10n.pdfTableLevel, 'Level');
      expect(l10n.pdfTableTopic, 'Topic');
      expect(l10n.pdfBadgesEarned, 'Badges Earned');
      expect(l10n.pdfRecentActivitySummary, 'Recent Activity Summary');
      expect(l10n.pdfNoMasteryData, 'No mastery data available yet.');
      expect(l10n.pdfNoBadges, 'No badges earned yet. Keep studying!');
    });

    test('upload content section', () {
      expect(l10n.uploadContent, 'Upload Content');
      expect(l10n.addStudyMaterials, 'Add study materials to your library');
      expect(l10n.titleRequired, 'Title *');
      expect(l10n.titleHint, 'e.g. Chapter 5 Notes');
      expect(l10n.subjectOptional, 'Subject (optional)');
      expect(l10n.none, 'None');
      expect(l10n.pasteText, 'Paste Text');
      expect(l10n.urlLink, 'URL / Link');
      expect(l10n.urlRequired, 'URL *');
      expect(l10n.urlHint, 'https://example.com/notes');
      expect(l10n.contentRequired, 'Content *');
      expect(l10n.contentHint, 'Paste your study material here...');
      expect(l10n.uploading, 'Uploading...');
      expect(l10n.fillRequiredFields, 'Please fill in all required fields.');
      expect(l10n.contentUploadedSuccessfully, 'Content uploaded successfully!');
    });

    test('plan summary and LLM task manager section', () {
      expect(l10n.planSummary, 'Plan Summary');
      expect(l10n.total, 'Total');
      expect(l10n.newTopics, 'new');
      expect(l10n.reviewTopics, 'review');
      expect(l10n.coverage, 'Coverage');
      expect(l10n.studyDay, 'Study Day');
      expect(l10n.rest, 'Rest');
      expect(l10n.startTutoring, 'Start tutoring');
      expect(l10n.failedToGeneratePlan, 'Failed to generate plan');
      expect(l10n.llmTaskManager, 'LLM Task Manager');
      expect(l10n.noLlmTasksYet, 'No LLM tasks yet');
      expect(l10n.cancelTask, 'Cancel');
      expect(l10n.testConnection, 'Test Connection');
      expect(l10n.testing, 'Testing...');
      expect(l10n.noPlanForToday, 'No plan for today');
      expect(l10n.adjustPlan, 'Adjust Plan');
      expect(l10n.dismiss, 'Dismiss');
      expect(l10n.voiceInput, 'Voice input');
      expect(l10n.captureImage, 'Capture Image');
      expect(l10n.camera, 'Camera');
    });

    test('AI tutor and mode selection section', () {
      expect(l10n.aiTutor, 'AI Tutor');
      expect(l10n.interactiveConversationalLessons, 'Interactive conversational lessons');
      expect(l10n.personalStudyAssistantPlanner, 'Personal study assistant & planner');
      expect(l10n.chooseStudyMode, 'Choose a study mode');
      expect(l10n.clearConversation, 'Clear conversation');
      expect(l10n.senderYou, 'You');
      expect(l10n.senderTutor, 'Tutor');
      expect(l10n.senderSystem, 'System');
    });

    test('metrics and export section', () {
      expect(l10n.weakAreasAccuracy, 'Weak Areas (Accuracy < 60%)');
      expect(l10n.instrumentationDataExported, 'Instrumentation data exported');
    });
  });

  group('AppLocalizationsEn - Remaining Parameterized Methods', () {
    late AppLocalizationsEn l10n;

    setUp(() {
      l10n = AppLocalizationsEn();
    });

    test('readyToLearnAbout', () {
      expect(l10n.readyToLearnAbout('Physics'), 'I\'m ready to learn about Physics. Please teach me!');
      expect(l10n.readyToLearnAbout('Algebra'),
          'I\'m ready to learn about Algebra. Please teach me!');
    });

    test('paceLabel', () {
      expect(l10n.paceLabel(75), '75% pace');
      expect(l10n.paceLabel(100), '100% pace');
      expect(l10n.paceLabel(0), '0% pace');
    });

    test('correctCount', () {
      expect(l10n.correctCount(1), '1 correct');
      expect(l10n.correctCount(3), '3 correct');
      expect(l10n.correctCount(0), '0 correct');
    });

    test('remainingMinLabel', () {
      expect(l10n.remainingMinLabel(1), '1 min remaining');
      expect(l10n.remainingMinLabel(5), '5 min remaining');
      expect(l10n.remainingMinLabel(0), '0 min remaining');
    });

    test('correctCountLabel', () {
      expect(l10n.correctCountLabel(1), '1 correct');
      expect(l10n.correctCountLabel(5), '5 correct');
    });

    test('cameraError', () {
      expect(l10n.cameraError('permission denied'), 'Camera error: permission denied');
      expect(l10n.cameraError('not found'), 'Camera error: not found');
    });

    test('correctAnswerIs', () {
      expect(l10n.correctAnswerIs('42'), 'The correct answer is: 42');
      expect(l10n.correctAnswerIs('Paris'), 'The correct answer is: Paris');
    });

    test('allStepsFormat', () {
      expect(l10n.allStepsFormat(3), 'All 3 steps identified correctly!');
      expect(l10n.allStepsFormat(5), 'All 5 steps identified correctly!');
    });

    test('partialStepsFormat', () {
      expect(l10n.partialStepsFormat(2, 5, 'step3, step4'),
          'Identified 2 of 5 steps. Missing: step3, step4');
      expect(l10n.partialStepsFormat(0, 3, 'all'), 'Identified 0 of 3 steps. Missing: all');
    });

    test('noStepsFormat', () {
      expect(l10n.noStepsFormat('step1, step2'),
          'No required steps found in your answer. Key steps to include: step1, step2');
    });

    test('errorStartingSession', () {
      expect(l10n.errorStartingSession('timeout'), 'Error starting session: timeout');
      expect(l10n.errorStartingSession('no internet'), 'Error starting session: no internet');
    });

    test('sessionCompleted', () {
      expect(l10n.sessionCompleted(25), 'Session completed: 25m');
      expect(l10n.sessionCompleted(60), 'Session completed: 60m');
    });

    test('focusForMinutes', () {
      expect(l10n.focusForMinutes(25), 'Focus for 25 minutes');
      expect(l10n.focusForMinutes(50), 'Focus for 50 minutes');
    });

    test('completionOfValue', () {
      expect(l10n.completionOfValue('50.0%'), '50.0% Complete');
      expect(l10n.completionOfValue('100.0%'), '100.0% Complete');
      expect(l10n.completionOfValue('0.0%'), '0.0% Complete');
    });

    test('milestoneOfWithDeadline', () {
      expect(l10n.milestoneOfWithDeadline('Learn Basics', '2026-06-01'),
          'Learn Basics - Due 2026-06-01');
    });

    test('weekNumber', () {
      expect(l10n.weekNumber(1), 'Week 1');
      expect(l10n.weekNumber(12), 'Week 12');
    });

    test('milestoneForWeek', () {
      expect(l10n.milestoneForWeek(1), 'Milestone for week 1');
      expect(l10n.milestoneForWeek(5), 'Milestone for week 5');
    });

    test('pdfGenerated', () {
      expect(l10n.pdfGenerated('2026-05-14'), 'Generated: 2026-05-14');
    });

    test('pdfStudentId', () {
      expect(l10n.pdfStudentId('STU001'), 'Student ID: STU001');
    });

    test('pdfTotalAttemptsRecorded', () {
      expect(l10n.pdfTotalAttemptsRecorded(100), 'Total attempts recorded: 100');
      expect(l10n.pdfTotalAttemptsRecorded(0), 'Total attempts recorded: 0');
    });

    test('pdfDateRange', () {
      expect(l10n.pdfDateRange('2026-01-01', '2026-05-14'), 'Date range: 2026-01-01 to 2026-05-14');
    });

    test('pdfCorrectFraction', () {
      expect(l10n.pdfCorrectFraction(17, 20), 'Correct: 17/20');
      expect(l10n.pdfCorrectFraction(0, 10), 'Correct: 0/10');
    });

    test('questionsAndMinutes', () {
      expect(l10n.questionsAndMinutes(5, 30), '5Q \u00b7 30min');
      expect(l10n.questionsAndMinutes(0, 0), '0Q \u00b7 0min');
    });

    test('topicQuestionsAndMinutes', () {
      expect(l10n.topicQuestionsAndMinutes(3, 15), '3Q \u00b7 15min');
      expect(l10n.topicQuestionsAndMinutes(10, 45), '10Q \u00b7 45min');
    });

    test('activeCount', () {
      expect(l10n.activeCount(3), '3 active');
      expect(l10n.activeCount(0), '0 active');
      expect(l10n.activeCount(1), '1 active');
    });

    test('modelLabel', () {
      expect(l10n.modelLabel('gpt-4'), 'Model: gpt-4');
    });

    test('startedLabel', () {
      expect(l10n.startedLabel('10:00 AM'), 'Started: 10:00 AM');
    });

    test('endedLabel', () {
      expect(l10n.endedLabel('11:30 AM'), 'Ended: 11:30 AM');
    });

    test('tokensAndCost', () {
      expect(l10n.tokensAndCost(1500, '0.03'), 'Tokens: 1500 (0.03)');
      expect(l10n.tokensAndCost(0, '0.00'), 'Tokens: 0 (0.00)');
    });

    test('connectionSuccessful', () {
      expect(l10n.connectionSuccessful(120), 'Connection successful! Latency: 120ms');
      expect(l10n.connectionSuccessful(0), 'Connection successful! Latency: 0ms');
    });

    test('connectionFailed', () {
      expect(l10n.connectionFailed('timeout'), 'Connection failed: timeout');
    });

    test('sessionHistoryCsvGenerated', () {
      expect(l10n.sessionHistoryCsvGenerated(1024), 'Session history CSV generated (1024 chars)');
    });

    test('dailyPlanTarget', () {
      expect(l10n.dailyPlanTarget(10, 60), 'Today: 10Q, 60min');
      expect(l10n.dailyPlanTarget(0, 0), 'Today: 0Q, 0min');
    });

    test('planAdjustmentSuggested', () {
      expect(l10n.planAdjustmentSuggested(3),
          'You\'ve had 3 days of low plan adherence. Would you like to adjust your study plan?');
    });

    test('uploadFailed', () {
      expect(l10n.uploadFailed('network error'), 'Upload failed: network error');
    });

    test('focusLabel', () {
      expect(l10n.focusLabel('Math, Physics'), 'Focus: Math, Physics');
    });

    test('progressCsvGenerated', () {
      expect(l10n.progressCsvGenerated(2048), 'Progress CSV generated (2048 chars)');
    });

    test('exportFailed', () {
      expect(l10n.exportFailed('disk full'), 'Export failed: disk full');
    });

    test('attemptsCount', () {
      expect(l10n.attemptsCount(5), '5 attempts');
      expect(l10n.attemptsCount(0), '0 attempts');
      expect(l10n.attemptsCount(1), '1 attempt');
    });
  });

  group('AppLocalizationsEs - Remaining Simple Getters', () {
    late AppLocalizationsEs l10n;

    setUp(() {
      l10n = AppLocalizationsEs();
    });

    test('mentor and tutor section', () {
      expect(l10n.mentor, 'Mentor');
      expect(l10n.aiTutor, 'Tutor IA');
      expect(l10n.startAiTutoring, 'Iniciar Tutoría IA');
      expect(l10n.endLesson, 'Finalizar Lección');
      expect(l10n.typeYourMessage, 'Escriba su mensaje...');
      expect(l10n.send, 'Enviar');
      expect(l10n.progressReport, 'Informe de Progreso');
      expect(l10n.askMentorAnything, 'Pregúntele a su mentor...');
      expect(l10n.mentorGreeting, 'Mentor IA');
      expect(l10n.mentorSubtitle, 'Su asistente académico personal IA');
      expect(l10n.startingLesson, 'Iniciando su lección...');
      expect(l10n.lessonTimeEnded,
          'El tiempo de lección terminó. Toque \'Finalizar Lección\' para terminar.');
      expect(l10n.lessonComplete, 'Lección Completada');
      expect(l10n.errorOccurred, 'Ocurrió un error. Intente de nuevo.');
      expect(l10n.errorWithResponse, 'Lo siento, encontré un error. Intente de nuevo.');
      expect(l10n.inProgress, 'En Progreso');
      expect(l10n.completed, 'Completado');
      expect(l10n.notStarted, 'No Iniciado');
    });

    test('roadmap section', () {
      expect(l10n.roadmaps, 'Rutas de aprendizaje');
      expect(l10n.createRoadmap, 'Crear Roadmap');
      expect(l10n.roadmapGoal, 'Meta de Aprendizaje');
      expect(l10n.roadmapGoalHint, 'p. ej., Quiero aprender Python en 90 días');
      expect(l10n.generateRoadmap, 'Generar Roadmap');
      expect(l10n.myRoadmaps, 'Mis Roadmaps');
      expect(l10n.milestones, 'Hitos');
      expect(l10n.milestone, 'Hito');
      expect(l10n.targetCompletion, 'Finalización Prevista');
      expect(l10n.noRoadmapsYet, 'Aún no hay roadmaps');
      expect(l10n.timeline, 'Cronología');
    });

    test('notification settings section', () {
      expect(l10n.enableNotifications, 'Habilitar Notificaciones');
      expect(l10n.notificationPreferences, 'Preferencias de Notificaciones');
      expect(l10n.dailyReminders, 'Recordatorios Diarios');
      expect(l10n.revisionReminders, 'Recordatorios de Revisión');
      expect(l10n.notifChannelLessons, 'Notificaciones de Lecciones');
      expect(l10n.overworkAlerts, 'Alertas de Sobrecarga');
      expect(l10n.planAdjustmentNotifications, 'Alertas de Ajuste de Plan');
      expect(l10n.quietHours, 'Horas de Silencio');
      expect(l10n.quietHoursStart, 'Inicio Horas de Silencio');
      expect(l10n.quietHoursEnd, 'Fin Horas de Silencio');
    });

    test('comprehensive export section', () {
      expect(l10n.exportComprehensiveReport, 'Exportar Informe Completo');
      expect(l10n.comprehensiveCsv, 'CSV Completo');
      expect(l10n.comprehensivePdf, 'PDF Completo');
      expect(l10n.comprehensiveJson, 'JSON Completo');
      expect(l10n.comprehensiveReportExported, 'Informe completo exportado');
    });

    test('roadmap metrics section', () {
      expect(l10n.activeRoadmaps, 'Roadmaps Activos');
      expect(l10n.completedRoadmaps, 'Roadmaps Completados');
      expect(l10n.progressBySubject, 'Progreso por Materia');
    });

    test('answer feedback section', () {
      expect(l10n.markschemeUnavailable, 'No hay esquema de calificación disponible');
      expect(l10n.answerTooShort, 'La respuesta es demasiado corta. Proporcione más detalles.');
      expect(l10n.goodResponseLength, 'Buena longitud de respuesta.');
      expect(l10n.answerTooShortForCredit, 'Respuesta demasiado corta para crédito completo.');
      expect(l10n.noDrawingDetected, 'No se detectó dibujo. Por favor, dibuje algo.');
      expect(l10n.invalidDrawingData, 'Datos de dibujo inválidos. Por favor, vuelva a dibujar.');
      expect(l10n.allStepsIdentified, 'Todos los pasos requeridos identificados.');
      expect(l10n.specialHandlingRequired, 'Este tipo de pregunta requiere manejo especial.');
      expect(l10n.someAnswersIncorrect, 'Algunas respuestas son incorrectas');
      expect(l10n.allRequiredStepsMissing, 'Faltan algunos pasos requeridos');
    });

    test('focus mode and timer section', () {
      expect(l10n.focusMode, 'Estudio');
      expect(l10n.newFocusSession, 'Nueva Sesión de Enfoque');
      expect(l10n.refreshStats, 'Actualizar estadísticas');
      expect(l10n.dailyLimitReached, 'Límite Diario Alcanzado');
      expect(l10n.dailyLimitReachedBody,
          'Ha alcanzado su límite diario de estudio. ¡Bien hecho! Descanse y vuelva mañana.');
      expect(l10n.breakTime, '¡Descanso!');
      expect(l10n.focusTime, 'Tiempo de Enfoque');
      expect(l10n.timerRemaining, 'restante');
      expect(l10n.timerPaused, 'PAUSADO');
      expect(l10n.timerDone, '¡TERMINADO!');
      expect(l10n.resume, 'Reanudar');
      expect(l10n.pause, 'Pausar');
      expect(l10n.markComplete, 'Marcar como Completado');
    });

    test('CSV column labels', () {
      expect(l10n.csvOverallStats, 'ESTADÍSTICAS GENERALES');
      expect(l10n.csvTopicMastery, 'DOMINIO DE TEMAS');
      expect(l10n.csvAllAttempts, 'TODOS LOS INTENTOS');
      expect(l10n.csvWeeklyTrend, 'TENDENCIA SEMANAL');
      expect(l10n.csvBadges, 'INSIGNIAS');
      expect(l10n.csvColTotalAttempts, 'Intentos Totales');
      expect(l10n.csvColCorrect, 'Correctas');
      expect(l10n.csvColAccuracy, 'Precisión (%)');
      expect(l10n.csvColAvgTime, 'Tiempo Prom. (s)');
      expect(l10n.csvColTotalHours, 'Horas Totales');
      expect(l10n.csvColWeeklyActivity, 'Actividad Semanal');
      expect(l10n.csvColDailyActivity, 'Actividad Diaria');
      expect(l10n.csvColTopicsStudied, 'Temas Estudiados');
      expect(l10n.csvColTopicId, 'ID del Tema');
      expect(l10n.csvColMasteryLevel, 'Nivel de Dominio');
      expect(l10n.csvColLastPracticed, 'Última Práctica');
      expect(l10n.csvColReviewUrgency, 'Urgencia de Revisión');
      expect(l10n.csvColQuestionId, 'ID de Pregunta');
      expect(l10n.csvColSubjectId, 'ID de Materia');
      expect(l10n.csvColTime, 'Tiempo (s)');
      expect(l10n.csvColTimestamp, 'Marca de Tiempo');
      expect(l10n.csvColWeek, 'Semana');
      expect(l10n.csvColAttempts, 'Intentos');
      expect(l10n.csvColImprovement, 'Mejora');
      expect(l10n.csvColBadgeName, 'Nombre de Insignia');
      expect(l10n.csvColBadgeDescription, 'Descripción');
      expect(l10n.csvColDateUnlocked, 'Fecha de Desbloqueo');
    });

    test('PDF report labels', () {
      expect(l10n.pdfProgressReport, 'Informe de Progreso StudyKing');
      expect(l10n.pdfOverallStatistics, 'Estadísticas Generales');
      expect(l10n.pdfMetric, 'Métrica');
      expect(l10n.pdfValue, 'Valor');
      expect(l10n.pdfTopicMasteryBreakdown, 'Desglose de Dominio de Temas');
      expect(l10n.pdfTableAttempts, 'Intentos');
      expect(l10n.pdfTableLevel, 'Nivel');
      expect(l10n.pdfTableTopic, 'Tema');
      expect(l10n.pdfBadgesEarned, 'Insignias Obtenidas');
      expect(l10n.pdfRecentActivitySummary, 'Resumen de Actividad Reciente');
      expect(l10n.pdfNoMasteryData, 'Aún no hay datos de dominio.');
      expect(l10n.pdfNoBadges, 'Aún no hay insignias. ¡Sigue estudiando!');
    });

    test('upload content section', () {
      expect(l10n.uploadContent, 'Subir Contenido');
      expect(l10n.addStudyMaterials, 'Agregue materiales de estudio a su biblioteca');
      expect(l10n.titleRequired, 'Título *');
      expect(l10n.titleHint, 'p. ej. Notas del Capítulo 5');
      expect(l10n.subjectOptional, 'Materia (opcional)');
      expect(l10n.none, 'Ninguno');
      expect(l10n.pasteText, 'Pegar Texto');
      expect(l10n.urlLink, 'URL / Enlace');
      expect(l10n.urlRequired, 'URL *');
      expect(l10n.urlHint, 'https://example.com/notas');
      expect(l10n.contentRequired, 'Contenido *');
      expect(l10n.contentHint, 'Pegue su material de estudio aquí...');
      expect(l10n.uploading, 'Subiendo...');
      expect(l10n.fillRequiredFields, 'Por favor complete todos los campos requeridos.');
      expect(l10n.contentUploadedSuccessfully, '¡Contenido subido exitosamente!');
    });

    test('plan summary and LLM task manager section', () {
      expect(l10n.planSummary, 'Resumen del Plan');
      expect(l10n.total, 'Total');
      expect(l10n.newTopics, 'nuevos');
      expect(l10n.reviewTopics, 'revisión');
      expect(l10n.coverage, 'Cobertura');
      expect(l10n.studyDay, 'Día de Estudio');
      expect(l10n.rest, 'Descanso');
      expect(l10n.startTutoring, 'Iniciar tutoría');
      expect(l10n.failedToGeneratePlan, 'Error al generar el plan');
      expect(l10n.llmTaskManager, 'Administrador de Tareas LLM');
      expect(l10n.noLlmTasksYet, 'Aún no hay tareas LLM');
      expect(l10n.cancelTask, 'Cancelar');
      expect(l10n.testConnection, 'Probar Conexión');
      expect(l10n.testing, 'Probando...');
      expect(l10n.noPlanForToday, 'Sin plan para hoy');
      expect(l10n.adjustPlan, 'Ajustar Plan');
      expect(l10n.dismiss, 'Descartar');
      expect(l10n.voiceInput, 'Entrada de voz');
      expect(l10n.captureImage, 'Capturar Imagen');
      expect(l10n.camera, 'Cámara');
    });

    test('AI tutor and mode selection section', () {
      expect(l10n.aiTutor, 'Tutor IA');
      expect(l10n.interactiveConversationalLessons, 'Lecciones conversacionales interactivas');
      expect(l10n.personalStudyAssistantPlanner, 'Asistente personal de estudio y planificador');
      expect(l10n.chooseStudyMode, 'Elija un modo de estudio');
      expect(l10n.clearConversation, 'Borrar conversación');
      expect(l10n.senderYou, 'Usted');
      expect(l10n.senderTutor, 'Tutor');
      expect(l10n.senderSystem, 'Sistema');
    });

    test('metrics and export section', () {
      expect(l10n.weakAreasAccuracy, 'Áreas por mejorar (Precisión < 60 %)');
      expect(l10n.instrumentationDataExported, 'Datos de instrumentación exportados');
    });
  });

  group('AppLocalizationsEs - Remaining Parameterized Methods', () {
    late AppLocalizationsEs l10n;

    setUp(() {
      l10n = AppLocalizationsEs();
    });

    test('readyToLearnAbout', () {
      expect(l10n.readyToLearnAbout('Física'), 'Estoy listo para aprender sobre Física. ¡Enséñeme!');
    });

    test('paceLabel', () {
      expect(l10n.paceLabel(75), '75 % ritmo');
    });

    test('correctCount', () {
      expect(l10n.correctCount(1), '1 correcta');
      expect(l10n.correctCount(5), '5 correctas');
    });

    test('remainingMinLabel', () {
      expect(l10n.remainingMinLabel(1), '1 min restante');
      expect(l10n.remainingMinLabel(5), '5 min restantes');
    });

    test('correctCountLabel', () {
      expect(l10n.correctCountLabel(1), '1 correcta');
      expect(l10n.correctCountLabel(3), '3 correctas');
    });

    test('cameraError', () {
      expect(l10n.cameraError('permiso denegado'), 'Error de cámara: permiso denegado');
    });

    test('correctAnswerIs', () {
      expect(l10n.correctAnswerIs('42'), 'La respuesta correcta es: 42');
    });

    test('allStepsFormat', () {
      expect(l10n.allStepsFormat(3), '¡Los 3 pasos se han identificado correctamente!');
    });

    test('partialStepsFormat', () {
      expect(l10n.partialStepsFormat(2, 5, 'paso3'),
          'Identificó 2 de 5 pasos. Faltan: paso3');
    });

    test('noStepsFormat', () {
      expect(l10n.noStepsFormat('paso1, paso2'),
          'No se encontraron pasos requeridos en su respuesta. Pasos clave a incluir: paso1, paso2');
    });

    test('errorStartingSession', () {
      expect(l10n.errorStartingSession('tiempo agotado'), 'Error al iniciar sesión: tiempo agotado');
    });

    test('sessionCompleted', () {
      expect(l10n.sessionCompleted(25), 'Sesión completada: 25m');
    });

    test('focusForMinutes', () {
      expect(l10n.focusForMinutes(25), 'Enfóquese por 25 minutos');
    });

    test('completionOfValue', () {
      expect(l10n.completionOfValue('50,0 %'), '50,0 % Completo');
    });

    test('milestoneOfWithDeadline', () {
      expect(l10n.milestoneOfWithDeadline('Aprender', '2026-06-01'),
          'Aprender - Vence 2026-06-01');
    });

    test('weekNumber', () {
      expect(l10n.weekNumber(1), 'Semana 1');
    });

    test('milestoneForWeek', () {
      expect(l10n.milestoneForWeek(1), 'Hito de la semana 1');
    });

    test('pdfGenerated', () {
      expect(l10n.pdfGenerated('2026-05-14'), 'Generado: 2026-05-14');
    });

    test('pdfStudentId', () {
      expect(l10n.pdfStudentId('EST001'), 'ID de Estudiante: EST001');
    });

    test('pdfTotalAttemptsRecorded', () {
      expect(l10n.pdfTotalAttemptsRecorded(100), 'Intentos totales registrados: 100');
    });

    test('pdfDateRange', () {
      expect(l10n.pdfDateRange('2026-01-01', '2026-05-14'),
          'Rango de fechas: 2026-01-01 a 2026-05-14');
    });

    test('pdfCorrectFraction', () {
      expect(l10n.pdfCorrectFraction(17, 20), 'Correctas: 17/20');
    });

    test('questionsAndMinutes', () {
      expect(l10n.questionsAndMinutes(5, 30), '5P \u00b7 30min');
    });

    test('topicQuestionsAndMinutes', () {
      expect(l10n.topicQuestionsAndMinutes(3, 15), '3P \u00b7 15min');
    });

    test('activeCount', () {
      expect(l10n.activeCount(3), '3 activas');
    });

    test('modelLabel', () {
      expect(l10n.modelLabel('gpt-4'), 'Modelo: gpt-4');
    });

    test('startedLabel', () {
      expect(l10n.startedLabel('10:00'), 'Iniciado: 10:00');
    });

    test('endedLabel', () {
      expect(l10n.endedLabel('11:30'), 'Finalizado: 11:30');
    });

    test('tokensAndCost', () {
      expect(l10n.tokensAndCost(1500, '0.03'), 'Fichas: 1500 (0.03)');
    });

    test('connectionSuccessful', () {
      expect(l10n.connectionSuccessful(120), '¡Conexión exitosa! Latencia: 120ms');
    });

    test('connectionFailed', () {
      expect(l10n.connectionFailed('tiempo agotado'), 'Conexión fallida: tiempo agotado');
    });

    test('sessionHistoryCsvGenerated', () {
      expect(l10n.sessionHistoryCsvGenerated(1024),
          'CSV de historial de sesiones generado (1024 caracteres)');
    });

    test('dailyPlanTarget', () {
      expect(l10n.dailyPlanTarget(10, 60), 'Hoy: 10P, 60min');
    });

    test('planAdjustmentSuggested', () {
      expect(l10n.planAdjustmentSuggested(3),
          'Ha tenido 3 días de bajo cumplimiento del plan. ¿Desea ajustar su plan de estudio?');
    });

    test('uploadFailed', () {
      expect(l10n.uploadFailed('error de red'), 'Error al cargar: error de red');
    });

    test('focusLabel', () {
      expect(l10n.focusLabel('Mate, Física'), 'Enfoque: Mate, Física');
    });

    test('progressCsvGenerated', () {
      expect(l10n.progressCsvGenerated(2048), 'CSV de progreso generado (2048 caracteres)');
    });

    test('exportFailed', () {
      expect(l10n.exportFailed('disco lleno'), 'Error al exportar: disco lleno');
    });

    test('attemptsCount', () {
      expect(l10n.attemptsCount(5), '5 intentos');
    });
  });


  group('isSupported Locale Edge Cases', () {
    test('delegate.isSupported for valid locales', () {
      final delegate = AppLocalizations.delegate;
      expect(delegate.isSupported(const Locale('en')), isTrue);
      expect(delegate.isSupported(const Locale('es')), isTrue);
    });

    test('delegate.isSupported for invalid locales', () {
      final delegate = AppLocalizations.delegate;
      expect(delegate.isSupported(const Locale('fr')), isFalse);
      expect(delegate.isSupported(const Locale('de')), isFalse);
      expect(delegate.isSupported(const Locale('en', 'US')), isTrue);
    });

    test('delegate.isSupported for unsupported language code', () {
      final delegate = AppLocalizations.delegate;
      expect(delegate.isSupported(const Locale('ja')), isFalse);
    });
  });

  group('lookupAppLocalizations Additional Edge Cases', () {
    test('returns AppLocalizationsEn for en', () {
      final result = lookupAppLocalizations(const Locale('en'));
      expect(result, isA<AppLocalizationsEn>());
    });

    test('returns AppLocalizationsEs for es', () {
      final result = lookupAppLocalizations(const Locale('es'));
      expect(result, isA<AppLocalizationsEs>());
    });

    test('returns AppLocalizationsEn for en country variants', () {
      final result = lookupAppLocalizations(const Locale('en', 'GB'));
      expect(result, isA<AppLocalizationsEn>());
    });

    test('throws FlutterError for completely unsupported locale', () {
      expect(
        () => lookupAppLocalizations(const Locale('fr')),
        throwsA(isA<FlutterError>()),
      );
    });
  });

  group('AppLocalizations.delegate.toString and Equality', () {
    test('delegate hash code is stable', () {
      final d1 = AppLocalizations.delegate;
      final d2 = AppLocalizations.delegate;
      expect(d1.hashCode, d2.hashCode);
      expect(d1 == d2, isTrue);
    });

    test('delegate toString returns non-null', () {
      expect(AppLocalizations.delegate.toString(), isNotEmpty);
    });
  });
}
