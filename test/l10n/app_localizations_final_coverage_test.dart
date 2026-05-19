import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';
import 'package:studyking/l10n/generated/app_localizations_es.dart';

void main() {
  group('_AppLocalizationsDelegate', () {
    test('isSupported returns true for en', () {
      expect(AppLocalizations.delegate.isSupported(const Locale('en')), isTrue);
    });

    test('isSupported returns true for es', () {
      expect(AppLocalizations.delegate.isSupported(const Locale('es')), isTrue);
    });

    test('isSupported returns false for unsupported locale', () {
      expect(AppLocalizations.delegate.isSupported(const Locale('fr')), isFalse);
    });

    test('isSupported returns false for xx', () {
      expect(AppLocalizations.delegate.isSupported(const Locale('xx')), isFalse);
    });

    test('isSupported returns true for en country variants', () {
      expect(AppLocalizations.delegate.isSupported(const Locale('en', 'US')), isTrue);
      expect(AppLocalizations.delegate.isSupported(const Locale('en', 'GB')), isTrue);
    });

    test('load returns AppLocalizationsEn for en locale', () async {
      final result = await AppLocalizations.delegate.load(const Locale('en'));
      expect(result, isA<AppLocalizationsEn>());
    });

    test('load returns AppLocalizationsEs for es locale', () async {
      final result = await AppLocalizations.delegate.load(const Locale('es'));
      expect(result, isA<AppLocalizationsEs>());
    });

    test('load throws for unsupported locale', () {
      expect(
        () => AppLocalizations.delegate.load(const Locale('fr')),
        throwsA(isA<FlutterError>()),
      );
    });

    test('delegate toString returns something meaningful', () {
      expect(AppLocalizations.delegate.toString(), contains('AppLocalizations'));
    });
  });

  group('AppLocalizationsEn - Remaining Simple Getters', () {
    late AppLocalizationsEn l10n;

    setUp(() {
      l10n = AppLocalizationsEn();
    });

    test('focus getter', () {
      expect(l10n.focus, 'Study');
    });

    test('getting started section', () {
      expect(l10n.gettingStarted, 'Getting Started');
      expect(l10n.gettingStartedDesc,
          'Complete these steps to get the most out of StudyKing');
      expect(l10n.addSubjectDesc,
          'Create your first subject to organize your study material');
      expect(l10n.uploadMaterial, 'Upload Study Material');
      expect(l10n.uploadMaterialDesc,
          'Upload PDFs, notes, and question banks to get started');
      expect(l10n.takePracticeQuiz, 'Take Your First Practice Quiz');
      expect(l10n.takePracticeQuizDesc,
          'Test your knowledge with adaptive practice questions');
      expect(l10n.scheduleAiTutor, 'Schedule an AI Tutor Session');
      expect(l10n.scheduleAiTutorDesc,
          'Get personalized one-on-one tutoring with AI');
    });

    test('file operations section', () {
      expect(l10n.fileSaved, 'File saved successfully');
      expect(l10n.fileShared, 'File shared successfully');
    });

    test('badge section', () {
      expect(l10n.noBadgesYet, 'No achievements yet. Keep studying!');
      expect(l10n.noOptionsAvailable, 'No options available');
    });

    test('planner section', () {
      expect(l10n.subjectProgress, 'Subject Progress');
      expect(l10n.pendingActions, 'Pending Actions');
      expect(l10n.scheduledLessons, 'Scheduled Lessons');
      expect(l10n.regeneratePlan, 'Regenerate Plan');
      expect(l10n.viewAllLessons, 'View All Lessons');
      expect(l10n.change, 'Change');
      expect(l10n.scheduling, 'Scheduling...');
      expect(l10n.accept, 'Accept');
      expect(l10n.scheduleALesson, 'Schedule a lesson');
      expect(l10n.rescheduleLesson, 'Reschedule lesson');
      expect(l10n.planAdjustmentTitle, 'Plan adjustment suggested');
      expect(l10n.actionNeeded, 'Action needed');
      expect(l10n.somethingWentWrong, 'Something went wrong');
      expect(l10n.openPlanner, 'Open Planner');
      expect(l10n.studyPlanOverview, 'Study Plan Overview');
    });

    test('badge names and descriptions', () {
      expect(l10n.badgeFirstStepName, 'First Step');
      expect(l10n.badgeFirstStepDesc, 'Answered your first question!');

      expect(l10n.badgeAccuracyGoldName, 'Accuracy Gold');
      expect(l10n.badgeAccuracyGoldDesc, 'Achieved 90%+ accuracy!');
      expect(l10n.badgeDailyScholarName, 'Daily Scholar');
      expect(l10n.badgeDailyScholarDesc, 'Studied consistently today!');
      expect(l10n.badgeDedicatedLearnerName, 'Dedicated Learner');
      expect(l10n.badgeDedicatedLearnerDesc, 'Studied 10+ hours total!');
      expect(l10n.badgeWeeklyWarriorName, 'Weekly Warrior');
      expect(l10n.badgeWeeklyWarriorDesc, 'Active for a full week!');
    });

    test('notification channel names and descriptions', () {
      expect(l10n.notifChannelGeneral, 'StudyKing Notifications');
      expect(l10n.notifChannelGeneralDesc, 'General StudyKing notifications');
      expect(l10n.notifChannelRevision, 'Revision Reminders');
      expect(l10n.notifChannelWellbeing, 'Wellbeing Alerts');
      expect(l10n.notifChannelPlanning, 'Planning Suggestions');
      expect(l10n.notifChannelLessons, 'Lesson Notifications');
      expect(l10n.notifChannelMastery, 'Mastery Alerts');
      expect(l10n.notifChannelBadges, 'Badge Notifications');
      expect(l10n.notifChannelDailyReminder, 'Daily Study Reminders');
      expect(l10n.notifChannelDailyReminderDesc, 'Daily reminders to study');
    });

    test('notification titles', () {
      expect(l10n.notifTitleTimeToReview, 'Time to Review!');
      expect(l10n.notifTitleTakeBreak, 'Take a Break');
      expect(l10n.notifTitlePlanAdjustment, 'Plan Adjustment');
      expect(l10n.notifTitleUpcomingLesson, 'Upcoming Lesson');
      expect(l10n.notifTitleTopicsNeedAttention, 'Topics Need Attention');
      expect(l10n.notifTitleBadgeUnlocked, 'Badge Unlocked!');
    });

    test('plan explanation labels', () {
      expect(l10n.planAccuracyLow,
          'Accuracy is below 60% — needs focused practice');
      expect(l10n.planReviewOverdue,
          'Review is overdue — forgetting risk is high');
      expect(l10n.planStreakLow, 'Streak is low — consistency needed');
      expect(l10n.planPrerequisite,
          'Prerequisite for upcoming topics — must master first');
      expect(l10n.planHighMastery, 'High mastery — ready to advance');
      expect(l10n.planGoodProgress,
          'Good progress — maintain consistency');
      expect(l10n.planDeveloping, 'Developing — needs more practice');
      expect(l10n.planAtRisk, 'At risk — review overdue');
      expect(l10n.planNeedsAttention,
          'Needs attention — focus on fundamentals');
    });

    test('plan reason labels', () {
      expect(l10n.planReasonRequiredDependent, 'Required for dependent topics');
      expect(l10n.planReasonWeakPerformance, 'Weak performance');
      expect(l10n.planReasonHighForgettingRisk, 'High forgetting risk');
      expect(l10n.planReasonNewSyllabusTopic, 'New syllabus topic');
      expect(l10n.planReasonPartOfGoal, 'Part of syllabus goal');
    });

    test('plan focus labels', () {
      expect(l10n.planFocusGeneralReview, 'General review');
      expect(l10n.planFocusWeakAreas, 'Focus on weak areas');
      expect(l10n.planFocusPracticeReview, 'Practice and review');
      expect(l10n.planFocusRestAndReview, 'Rest and review');
    });

    test('recommendation labels', () {
      expect(l10n.recommendAccuracyBelow60,
          'Your overall accuracy is below 60%. Focus on reviewing fundamental concepts.');
      expect(l10n.recommendReviewBasics, 'Review basic topics before advancing');
      expect(l10n.recommendAccuracyExcellent,
          'Excellent progress! Ready for advanced topics.');
      expect(l10n.recommendChallengingQuestions,
          'Try challenging practice questions');
      expect(l10n.recommendConsistency,
          'You studied less than 1 hour total. Consistency is key!');
      expect(l10n.recommendSetDailyGoal, 'Set a daily study goal of 30 minutes');
      expect(l10n.recommendNoActivity,
          'No study activity this week. Get back on track!');
      expect(l10n.recommendQuickReview,
          'Start with a quick 15-minute review session');
      expect(l10n.recommendAiTutor, 'Review weak topics with the AI tutor');
    });

    test('adaptation suggestion labels', () {
      expect(l10n.adapSuggestionFundamentals, 'Review basic concepts first');
      expect(l10n.adapSuggestionMorePractice,
          'More practice questions recommended');
      expect(l10n.adapSuggestionAdvancedTopics, 'Ready for advanced topics');
    });

    test('badge century club aliases', () {
      expect(l10n.badgeCenturyClubName, 'Century Club');
      expect(l10n.badgeCenturyClubDesc, 'Answered 100+ questions!');
    });

    test('suggestion aliases', () {
      expect(l10n.adapSuggestionFundamentals, 'Review basic concepts first');
      expect(l10n.adapSuggestionMorePractice, 'More practice questions recommended');
      expect(l10n.adapSuggestionAdvancedTopics, 'Ready for advanced topics');
    });

    test('miscellaneous section', () {
      expect(l10n.shareSessionsText, 'Study Sessions');
      expect(l10n.summary, 'Summary');
      expect(l10n.noLimit, 'No limit');
      expect(l10n.focusTimerDescription, 'Start a focused study session');
      expect(l10n.dailyStudyCap, 'Daily Study Cap');
      expect(l10n.tokenUsageSummary, 'Token Usage Summary');
      expect(l10n.totalTokens, 'Total Tokens');
      expect(l10n.totalCost, 'Total Cost');
      expect(l10n.failed, 'Failed');
      expect(l10n.subjectIdHint, 'e.g. sub_physics');
    });

    test('plan alias labels', () {
      expect(l10n.planAccuracyLow,
          'Accuracy is below 60% — needs focused practice');
      expect(l10n.planReviewOverdue,
          'Review is overdue — forgetting risk is high');
      expect(l10n.planStreakLow, 'Streak is low — consistency needed');
      expect(l10n.planPrerequisite,
          'Prerequisite for upcoming topics — must master first');
      expect(l10n.planRequiredForDependent, 'Required for dependent topics');
      expect(l10n.planWeakPerformance, 'Weak performance');
      expect(l10n.planHighForgettingRisk, 'High forgetting risk');
      expect(l10n.planNewSyllabusTopic, 'New syllabus topic');
      expect(l10n.planPartOfSyllabusGoal, 'Part of syllabus goal');
      expect(l10n.planHighMastery, 'High mastery — ready to advance');
      expect(l10n.planGoodProgress, 'Good progress — maintain consistency');
      expect(l10n.planDeveloping, 'Developing — needs more practice');
      expect(l10n.planAtRisk, 'At risk — review overdue');
      expect(l10n.planNeedsAttention, 'Needs attention — focus on fundamentals');
      expect(l10n.planRestAndReview, 'Rest and review');
      expect(l10n.planGeneralReview, 'General review');
      expect(l10n.planPracticeAndReview, 'Practice and review');
    });

    test('notification channel aliases', () {
      expect(l10n.notifChannelGeneral, 'StudyKing Notifications');
      expect(l10n.notifChannelGeneralDesc,
          'General StudyKing notifications');
      expect(l10n.notifChannelDailyReminder,
          'Daily Study Reminders');
      expect(l10n.notifChannelDailyReminderDesc,
          'Daily reminders to study');
      expect(l10n.notifChannelRevision, 'Revision Reminders');
      expect(l10n.notifChannelRevisionDesc,
          'Reminders to review topics that need practice');
      expect(l10n.notifChannelWellbeing, 'Wellbeing Alerts');
      expect(l10n.notifChannelWellbeingDesc,
          'Alerts about study-life balance and overwork');
      expect(l10n.notifChannelPlanning, 'Planning Suggestions');
      expect(l10n.notifChannelPlanningDesc,
          'Suggestions about study plan adjustments');
      expect(l10n.notifChannelLessons, 'Lesson Notifications');
      expect(l10n.notifChannelLessonsDesc,
          'Notifications about upcoming lessons');
      expect(l10n.notifChannelMastery, 'Mastery Alerts');
      expect(l10n.notifChannelMasteryDesc,
          'Alerts about low topic mastery and weak areas');
      expect(l10n.notifChannelBadges, 'Badge Notifications');
      expect(l10n.notifChannelBadgesDesc,
          'Notifications about earned badges and achievements');
    });

    test('notification title aliases', () {
      expect(l10n.notifTitleTimeToReview, 'Time to Review!');
      expect(l10n.notifTitleTakeBreak, 'Take a Break');
      expect(l10n.notifTitlePlanAdjustment, 'Plan Adjustment');
      expect(l10n.notifTitleUpcomingLesson, 'Upcoming Lesson');
      expect(l10n.notifTitleTopicsNeedAttention,
          'Topics Need Attention');
      expect(l10n.notifTitleBadgeUnlocked, 'Badge Unlocked!');
    });

    test('recommendation aliases', () {
      expect(l10n.recommendAccuracyBelow60,
          'Your overall accuracy is below 60%. Focus on reviewing fundamental concepts.');
      expect(l10n.recommendReviewBasics,
          'Review basic topics before advancing');
      expect(l10n.recommendAccuracyExcellent,
          'Excellent progress! Ready for advanced topics.');
      expect(l10n.recommendChallengingQuestions,
          'Try challenging practice questions');
      expect(l10n.recommendConsistency,
          'You studied less than 1 hour total. Consistency is key!');
      expect(l10n.recommendSetDailyGoal,
          'Set a daily study goal of 30 minutes');
      expect(l10n.recommendNoActivity,
          'No study activity this week. Get back on track!');
      expect(l10n.recommendQuickReview,
          'Start with a quick 15-minute review session');
      expect(l10n.recommendAiTutor,
          'Review weak topics with the AI tutor');
    });
  });

  group('AppLocalizationsEn - Remaining Parameterized Methods', () {
    late AppLocalizationsEn l10n;

    setUp(() {
      l10n = AppLocalizationsEn();
    });

    test('moreLessonsCount', () {
      expect(l10n.moreLessonsCount(3), '3 more...');
      expect(l10n.moreLessonsCount(1), '1 more...');
      expect(l10n.moreLessonsCount(0), '0 more...');
    });

    test('planBlocksDownstream', () {
      expect(l10n.planBlocksDownstream(3), 'Blocks 3 downstream topic(s)');
      expect(l10n.planBlocksDownstream(1), 'Blocks 1 downstream topic(s)');
      expect(l10n.planBlocksDownstream(0), 'Blocks 0 downstream topic(s)');
    });

    test('notifBodyOverwork', () {
      expect(l10n.notifBodyOverwork(5),
          'You\'ve studied 5 hours today. Remember to rest!');
    });

    test('notifBodyPlanAdjustment', () {
      expect(l10n.notifBodyPlanAdjustment(3),
          'You\'ve had 3 days of low adherence. Shall we adjust your plan?');
    });

    test('notifBodyLowMastery', () {
      expect(l10n.notifBodyLowMastery('Algebra, Geometry'),
          'Low mastery detected in: Algebra, Geometry');
    });

    test('notificationTimeToReviewBody', () {
      expect(l10n.notificationTimeToReviewBody(5, 'History'),
          'It\'s been 5 days since you practiced "History".');
    });

    test('notificationTakeABreakBody', () {
      expect(l10n.notifBodyOverwork(3),
          'You\'ve studied 3 hours today. Remember to rest!');
    });

    test('notificationPlanAdjustmentBody', () {
      expect(l10n.notifBodyPlanAdjustment(7),
          'You\'ve had 7 days of low adherence. Shall we adjust your plan?');
    });

    test('notificationUpcomingLessonBody', () {
      expect(l10n.notificationUpcomingLessonBody('Physics', '2:00 PM'),
          'Your lesson "Physics" starts at 2:00 PM');
    });

    test('notificationTopicsNeedAttentionBody', () {
      expect(l10n.notifBodyLowMastery('Math'),
          'Low mastery detected in: Math');
    });

    test('notificationBadgeUnlockedBody', () {
      expect(l10n.notificationBadgeUnlockedBody('Gold', '90% accuracy'),
          'You earned the "Gold" badge: 90% accuracy');
    });

    test('nudgeOverwork', () {
      expect(l10n.nudgeOverwork('6'),
          'You have studied 6 hours today. Consider taking a break!');
    });

    test('nudgeRevision', () {
      expect(l10n.nudgeRevision(7, 'Biology'),
          'It has been 7 days since you practiced "Biology". Time for a review!');
    });

    test('nudgePlanAdjustment', () {
      expect(l10n.nudgePlanAdjustment(5),
          'You have had 5 days of low plan adherence. Would you like to adjust your study plan?');
    });

    test('nudgeWeeklyDigest', () {
      expect(l10n.nudgeWeeklyDigest(50, 85, '12.5', 3, 2),
          'Weekly Digest: 50 questions answered, 85% accuracy, 12.5 hours studied, 3 weak areas, 2 badges earned.');
    });

    test('adherenceLow7Days', () {
      expect(l10n.adherenceLowDaysAdjust(10),
          'You have had 10 consecutive days of low adherence. Consider adjusting your study plan or discussing with your mentor.');
    });

    test('adherenceLow3Days', () {
      expect(l10n.adherenceLowDaysRegenerate(5),
          'You have had 5 consecutive days of low adherence. Would you like to regenerate your plan with adjusted targets?');
    });

    test('adherenceLowDaysAdjust', () {
      expect(l10n.adherenceLowDaysAdjust(7),
          'You have had 7 consecutive days of low adherence. Consider adjusting your study plan or discussing with your mentor.');
    });

    test('adherenceLowDaysRegenerate', () {
      expect(l10n.adherenceLowDaysRegenerate(3),
          'You have had 3 consecutive days of low adherence. Would you like to regenerate your plan with adjusted targets?');
    });

    test('adherenceLowToday', () {
      expect(l10n.adherenceLowToday(30, 60),
          'You studied 30 min today vs 60 min planned. Consider redistributing the remaining workload.');
    });

    test('adherencePartialToday', () {
      expect(l10n.adherencePartialToday(45, 60),
          'You studied 45 min today vs 60 min planned. Try to catch up with the remaining topics.');
    });

    test('adherenceExceededToday', () {
      expect(l10n.adherenceExceededToday(75, 60),
          'Great work! You studied 75 min vs 60 min planned.');
    });

    test('recommendWeakTopics', () {
      expect(l10n.recommendWeakTopics(3),
          'You have 3 topic(s) that need improvement. Focus on strengthening these areas.');
      expect(l10n.recommendWeakTopics(0),
          'You have 0 topic(s) that need improvement. Focus on strengthening these areas.');
    });
  });

  group('AppLocalizationsEs - Remaining Simple Getters', () {
    late AppLocalizationsEs l10n;

    setUp(() {
      l10n = AppLocalizationsEs();
    });

    test('focus getter', () {
      expect(l10n.focus, 'Estudio');
    });

    test('getting started section', () {
      expect(l10n.gettingStarted, 'Primeros Pasos');
      expect(l10n.gettingStartedDesc,
          'Complete estos pasos para aprovechar al máximo StudyKing');
      expect(l10n.addSubjectDesc,
          'Cree su primera materia para organizar su material de estudio');
      expect(l10n.uploadMaterial, 'Subir Material de Estudio');
      expect(l10n.uploadMaterialDesc,
          'Suba PDFs, notas y bancos de preguntas para comenzar');
      expect(l10n.takePracticeQuiz,
          'Realice su Primer Cuestionario de Práctica');
      expect(l10n.takePracticeQuizDesc,
          'Ponga a prueba sus conocimientos con preguntas de práctica adaptativas');
      expect(l10n.scheduleAiTutor, 'Programe una Sesión con el Tutor de IA');
      expect(l10n.scheduleAiTutorDesc,
          'Reciba tutoría personalizada uno a uno con IA');
    });

    test('file operations section', () {
      expect(l10n.fileSaved, 'Archivo guardado exitosamente');
      expect(l10n.fileShared, 'Archivo compartido exitosamente');
    });

    test('badge empty state', () {
      expect(l10n.noBadgesYet, 'Aún no hay logros. ¡Sigue estudiando!');
      expect(l10n.noOptionsAvailable, 'No hay opciones disponibles');
    });

    test('planner section', () {
      expect(l10n.subjectProgress, 'Progreso de la Materia');
      expect(l10n.pendingActions, 'Acciones Pendientes');
      expect(l10n.scheduledLessons, 'Lecciones Programadas');
      expect(l10n.regeneratePlan, 'Regenerar Plan');
      expect(l10n.viewAllLessons, 'Ver Todas las Lecciones');
      expect(l10n.change, 'Cambiar');
      expect(l10n.scheduling, 'Programando...');
      expect(l10n.accept, 'Aceptar');
      expect(l10n.scheduleALesson, 'Programar una lección');
      expect(l10n.rescheduleLesson, 'Reprogramar lección');
      expect(l10n.planAdjustmentTitle, 'Ajuste de plan sugerido');
      expect(l10n.actionNeeded, 'Acción necesaria');
      expect(l10n.somethingWentWrong, 'Algo salió mal');
      expect(l10n.openPlanner, 'Abrir Planificador');
      expect(l10n.studyPlanOverview, 'Resumen del Plan de Estudio');
    });

    test('badge names and descriptions', () {
      expect(l10n.badgeFirstStepName, 'Primer Paso');
      expect(l10n.badgeFirstStepDesc, '¡Respondió su primera pregunta!');

      expect(l10n.badgeAccuracyGoldName, 'Precisión de Oro');
      expect(l10n.badgeAccuracyGoldDesc, '¡Alcanzó más del 90% de precisión!');
      expect(l10n.badgeDailyScholarName, 'Estudioso Diario');
      expect(l10n.badgeDailyScholarDesc, '¡Estudió constantemente hoy!');
      expect(l10n.badgeDedicatedLearnerName, 'Aprendiz Dedicado');
      expect(l10n.badgeDedicatedLearnerDesc,
          '¡Estudió más de 10 horas en total!');
      expect(l10n.badgeWeeklyWarriorName, 'Guerrero Semanal');
      expect(l10n.badgeWeeklyWarriorDesc,
          '¡Activo durante una semana completa!');
    });

    test('notification channel names and descriptions', () {
      expect(l10n.notifChannelGeneral, 'Notificaciones de StudyKing');
      expect(l10n.notifChannelGeneralDesc,
          'Notificaciones generales de StudyKing');
      expect(l10n.notifChannelRevision, 'Recordatorios de Revisión');
      expect(l10n.notifChannelWellbeing, 'Alertas de Bienestar');
      expect(l10n.notifChannelPlanning, 'Sugerencias de Planificación');
      expect(l10n.notifChannelLessons, 'Notificaciones de Lecciones');
      expect(l10n.notifChannelMastery, 'Alertas de Dominio');
      expect(l10n.notifChannelBadges, 'Notificaciones de Insignias');
      expect(l10n.notifChannelDailyReminder,
          'Recordatorios de Estudio Diarios');
      expect(l10n.notifChannelDailyReminderDesc,
          'Recordatorios diarios para estudiar');
    });

    test('notification titles', () {
      expect(l10n.notifTitleTimeToReview, '¡Hora de Repasar!');
      expect(l10n.notifTitleTakeBreak, 'Tome un Descanso');
      expect(l10n.notifTitlePlanAdjustment, 'Ajuste de Plan');
      expect(l10n.notifTitleUpcomingLesson, 'Próxima Lección');
      expect(l10n.notifTitleTopicsNeedAttention,
          'Temas que Requieren Atención');
      expect(l10n.notifTitleBadgeUnlocked, '¡Insignia Desbloqueada!');
    });

    test('plan explanation labels', () {
      expect(l10n.planAccuracyLow,
          'La precisión está por debajo del 60% — necesita práctica enfocada');
      expect(l10n.planReviewOverdue,
          'El repaso está vencido — el riesgo de olvido es alto');
      expect(l10n.planStreakLow,
          'La racha es baja — se necesita constancia');
      expect(l10n.planPrerequisite,
          'Requisito previo para temas próximos — debe dominarlo primero');
      expect(l10n.planHighMastery,
          'Alto dominio — listo para avanzar');
      expect(l10n.planGoodProgress,
          'Buen progreso — mantenga la constancia');
      expect(l10n.planDeveloping,
          'En desarrollo — necesita más práctica');
      expect(l10n.planAtRisk, 'En riesgo — repaso vencido');
      expect(l10n.planNeedsAttention,
          'Necesita atención — enfoque en fundamentos');
    });

    test('plan reason labels', () {
      expect(l10n.planReasonRequiredDependent,
          'Requerido para temas dependientes');
      expect(l10n.planReasonWeakPerformance, 'Rendimiento bajo');
      expect(l10n.planReasonHighForgettingRisk, 'Alto riesgo de olvido');
      expect(l10n.planReasonNewSyllabusTopic, 'Nuevo tema del plan de estudios');
      expect(l10n.planReasonPartOfGoal,
          'Parte del objetivo del plan de estudios');
    });

    test('plan focus labels', () {
      expect(l10n.planFocusGeneralReview, 'Repaso general');
      expect(l10n.planFocusWeakAreas, 'Enfoque en áreas por mejorar');
      expect(l10n.planFocusPracticeReview, 'Práctica y repaso');
      expect(l10n.planFocusRestAndReview, 'Descanso y repaso');
    });

    test('recommendation labels', () {
      expect(l10n.recommendAccuracyBelow60,
          'Su precisión general está por debajo del 60%. Concéntrese en repasar conceptos fundamentales.');
      expect(l10n.recommendReviewBasics, 'Repase temas básicos antes de avanzar');
      expect(l10n.recommendAccuracyExcellent,
          '¡Excelente progreso! Listo para temas avanzados.');
      expect(l10n.recommendChallengingQuestions,
          'Intente preguntas de práctica desafiantes');
      expect(l10n.recommendConsistency,
          'Estudió menos de 1 hora en total. ¡La constancia es clave!');
      expect(l10n.recommendSetDailyGoal,
          'Establezca una meta diaria de 30 minutos');
      expect(l10n.recommendNoActivity,
          'Sin actividad de estudio esta semana. ¡Retome el ritmo!');
      expect(l10n.recommendQuickReview,
          'Comience con una sesión de repaso rápido de 15 minutos');
      expect(l10n.recommendAiTutor, 'Repase temas débiles con el tutor IA');
    });

    test('adaptation suggestion labels', () {
      expect(l10n.adapSuggestionFundamentals, 'Repase conceptos básicos primero');
      expect(l10n.adapSuggestionMorePractice,
          'Se recomiendan más preguntas de práctica');
      expect(l10n.adapSuggestionAdvancedTopics, 'Listo para temas avanzados');
    });

    test('badge century club aliases', () {
      expect(l10n.badgeCenturyClubName, 'Club del Centenario');
      expect(l10n.badgeCenturyClubDesc, '¡Respondió más de 100 preguntas!');
    });

    test('suggestion aliases', () {
      expect(l10n.adapSuggestionFundamentals, 'Repase conceptos básicos primero');
      expect(l10n.adapSuggestionMorePractice,
          'Se recomiendan más preguntas de práctica');
      expect(l10n.adapSuggestionAdvancedTopics, 'Listo para temas avanzados');
    });

    test('miscellaneous section', () {
      expect(l10n.shareSessionsText, 'Sesiones de Estudio');
      expect(l10n.summary, 'Resumen');
      expect(l10n.noLimit, 'Sin límite');
      expect(l10n.focusTimerDescription,
          'Inicie una sesión de estudio enfocada');
      expect(l10n.dailyStudyCap, 'Límite Diario de Estudio');
      expect(l10n.tokenUsageSummary, 'Resumen de Uso de Tokens');
      expect(l10n.totalTokens, 'Tokens Totales');
      expect(l10n.totalCost, 'Costo Total');
      expect(l10n.failed, 'Fallidas');
      expect(l10n.subjectIdHint, 'p. ej. sub_física');
    });

    test('plan alias labels', () {
      expect(l10n.planAccuracyLow,
          'La precisión está por debajo del 60% — necesita práctica enfocada');
      expect(l10n.planReviewOverdue,
          'El repaso está vencido — el riesgo de olvido es alto');
      expect(l10n.planStreakLow, 'La racha es baja — se necesita constancia');
      expect(l10n.planPrerequisite,
          'Requisito previo para temas próximos — debe dominarlo primero');
      expect(l10n.planRequiredForDependent,
          'Requerido para temas dependientes');
      expect(l10n.planWeakPerformance, 'Rendimiento débil');
      expect(l10n.planHighForgettingRisk, 'Alto riesgo de olvido');
      expect(l10n.planNewSyllabusTopic, 'Nuevo tema del temario');
      expect(l10n.planPartOfSyllabusGoal, 'Parte del objetivo del temario');
      expect(l10n.planHighMastery, 'Alto dominio — listo para avanzar');
      expect(l10n.planGoodProgress,
          'Buen progreso — mantenga la constancia');
      expect(l10n.planDeveloping, 'En desarrollo — necesita más práctica');
      expect(l10n.planAtRisk, 'En riesgo — repaso vencido');
      expect(l10n.planNeedsAttention,
          'Necesita atención — enfoque en fundamentos');
      expect(l10n.planRestAndReview, 'Descanso y repaso');
      expect(l10n.planGeneralReview, 'Repaso general');
      expect(l10n.planPracticeAndReview, 'Práctica y repaso');
    });

    test('notification channel aliases', () {
      expect(l10n.notifChannelGeneral,
          'Notificaciones de StudyKing');
      expect(l10n.notifChannelGeneralDesc,
          'Notificaciones generales de StudyKing');
      expect(l10n.notifChannelDailyReminder,
          'Recordatorios de Estudio Diarios');
      expect(l10n.notifChannelDailyReminderDesc,
          'Recordatorios diarios para estudiar');
      expect(l10n.notifChannelRevision, 'Recordatorios de Revisión');
      expect(l10n.notifChannelRevisionDesc,
          'Recordatorios para repasar temas que necesitan práctica');
      expect(l10n.notifChannelWellbeing, 'Alertas de Bienestar');
      expect(l10n.notifChannelWellbeingDesc,
          'Alertas sobre equilibrio estudio-vida y sobrecarga');
      expect(l10n.notifChannelPlanning,
          'Sugerencias de Planificación');
      expect(l10n.notifChannelPlanningDesc,
          'Sugerencias sobre ajustes al plan de estudio');
      expect(l10n.notifChannelLessons,
          'Notificaciones de Lecciones');
      expect(l10n.notifChannelLessonsDesc,
          'Notificaciones sobre próximas lecciones');
      expect(l10n.notifChannelMastery, 'Alertas de Dominio');
      expect(l10n.notifChannelMasteryDesc,
          'Alertas sobre bajo dominio de temas y áreas por mejorar');
      expect(l10n.notifChannelBadges,
          'Notificaciones de Insignias');
      expect(l10n.notifChannelBadgesDesc,
          'Notificaciones sobre insignias y logros obtenidos');
    });

    test('notification title aliases', () {
      expect(l10n.notifTitleTimeToReview, '¡Hora de Repasar!');
      expect(l10n.notifTitleTakeBreak, 'Tome un Descanso');
      expect(l10n.notifTitlePlanAdjustment, 'Ajuste de Plan');
      expect(l10n.notifTitleUpcomingLesson, 'Próxima Lección');
      expect(l10n.notifTitleTopicsNeedAttention,
          'Temas que Requieren Atención');
      expect(l10n.notifTitleBadgeUnlocked, '¡Insignia Desbloqueada!');
    });

    test('recommendation aliases', () {
      expect(l10n.recommendAccuracyBelow60,
          'Su precisión general está por debajo del 60%. Concéntrese en repasar conceptos fundamentales.'); // ignore: lines_longer_than_80_chars
      expect(l10n.recommendReviewBasics,
          'Repase temas básicos antes de avanzar');
      expect(l10n.recommendAccuracyExcellent,
          '¡Excelente progreso! Listo para temas avanzados.');
      expect(l10n.recommendChallengingQuestions,
          'Intente preguntas de práctica desafiantes');
      expect(l10n.recommendConsistency,
          'Estudió menos de 1 hora en total. ¡La constancia es clave!');
      expect(l10n.recommendSetDailyGoal,
          'Establezca una meta diaria de 30 minutos');
      expect(l10n.recommendNoActivity,
          'Sin actividad de estudio esta semana. ¡Retome el ritmo!');
      expect(l10n.recommendQuickReview,
          'Comience con una sesión de repaso rápido de 15 minutos');
      expect(l10n.recommendAiTutor,
          'Repase temas débiles con el tutor IA');
    });
  });

  group('AppLocalizationsEs - Remaining Parameterized Methods', () {
    late AppLocalizationsEs l10n;

    setUp(() {
      l10n = AppLocalizationsEs();
    });

    test('moreLessonsCount', () {
      expect(l10n.moreLessonsCount(3), '3 más...');
    });

    test('planBlocksDownstream', () {
      expect(l10n.planBlocksDownstream(3), 'Bloquea 3 tema(s) dependiente(s)');
    });

    test('notifBodyOverwork', () {
      expect(l10n.notifBodyOverwork(5),
          'Ha estudiado 5 horas hoy. ¡Recuerde descansar!');
    });

    test('notifBodyPlanAdjustment', () {
      expect(l10n.notifBodyPlanAdjustment(3),
          'Ha tenido 3 días de bajo cumplimiento. ¿Ajustamos su plan?');
    });

    test('notifBodyLowMastery', () => expect(
        l10n.notifBodyLowMastery('Álgebra'), 'Bajo dominio detectado en: Álgebra'));

    test('notificationTimeToReviewBody', () {
      expect(l10n.notificationTimeToReviewBody(5, 'Historia'),
          'Han pasado 5 días desde que practicó "Historia".');
    });

    test('notificationTakeABreakBody', () {
      expect(l10n.notifBodyOverwork(3),
          'Ha estudiado 3 horas hoy. ¡Recuerde descansar!');
    });

    test('notificationPlanAdjustmentBody', () {
      expect(l10n.notifBodyPlanAdjustment(7),
          'Ha tenido 7 días de bajo cumplimiento. ¿Ajustamos su plan?');
    });

    test('notificationUpcomingLessonBody', () {
      expect(l10n.notificationUpcomingLessonBody('Física', '2:00'),
          'Su lección "Física" comienza a las 2:00');
    });

    test('notificationTopicsNeedAttentionBody', () => expect(
        l10n.notifBodyLowMastery('Mate'),
        'Bajo dominio detectado en: Mate'));

    test('notificationBadgeUnlockedBody', () {
      expect(l10n.notificationBadgeUnlockedBody('Oro', '90% precisión'),
          'Obtuvo la insignia "Oro": 90% precisión');
    });

    test('nudgeOverwork', () {
      expect(l10n.nudgeOverwork('6'),
          'Ha estudiado 6 horas hoy. ¡Considere tomar un descanso!');
    });

    test('nudgeRevision', () {
      expect(l10n.nudgeRevision(7, 'Biología'),
          'Han pasado 7 días desde que practicó "Biología". ¡Hora de repasar!');
    });

    test('nudgePlanAdjustment', () {
      expect(l10n.nudgePlanAdjustment(5),
          'Ha tenido 5 días de bajo cumplimiento del plan. ¿Desea ajustar su plan de estudio?');
    });

    test('nudgeWeeklyDigest', () {
      expect(l10n.nudgeWeeklyDigest(50, 85, '12.5', 3, 2),
          'Resumen semanal: 50 preguntas respondidas, 85% precisión, 12.5 horas estudiadas, 3 áreas por mejorar, 2 insignias obtenidas.');
    });

    test('adherenceLow7Days', () {
      expect(l10n.adherenceLowDaysAdjust(10),
          'Ha tenido 10 días consecutivos de bajo cumplimiento. Considere ajustar su plan de estudio o consultar con su mentor.');
    });

    test('adherenceLow3Days', () {
      expect(l10n.adherenceLowDaysRegenerate(5),
          '¿Ha tenido 5 días consecutivos de bajo cumplimiento. Le gustaría regenerar su plan con objetivos ajustados?');
    });

    test('adherenceLowDaysAdjust', () {
      expect(l10n.adherenceLowDaysAdjust(7),
          'Ha tenido 7 días consecutivos de bajo cumplimiento. Considere ajustar su plan de estudio o consultar con su mentor.');
    });

    test('adherenceLowDaysRegenerate', () {
      expect(l10n.adherenceLowDaysRegenerate(3),
          '¿Ha tenido 3 días consecutivos de bajo cumplimiento. Le gustaría regenerar su plan con objetivos ajustados?');
    });

    test('adherenceLowToday', () {
      expect(l10n.adherenceLowToday(30, 60),
          'Ha estudiado 30 min hoy frente a los 60 min planificados. Considere redistribuir la carga restante.');
    });

    test('adherencePartialToday', () {
      expect(l10n.adherencePartialToday(45, 60),
          'Ha estudiado 45 min hoy frente a los 60 min planificados. Intente ponerse al día con los temas restantes.');
    });

    test('adherenceExceededToday', () {
      expect(l10n.adherenceExceededToday(75, 60),
          '¡Buen trabajo! Ha estudiado 75 min frente a los 60 min planificados.');
    });

    test('recommendWeakTopics', () {
      expect(l10n.recommendWeakTopics(3),
          'Tiene 3 tema(s) que necesitan mejorar. Concéntrese en fortalecer estas áreas.');
    });
  });


}
