// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'StudyKing';

  @override
  String get subjects => 'Materias';

  @override
  String get practice => 'Práctica';

  @override
  String get settings => 'Ajustes';

  @override
  String get studyPlanner => 'Planificador de Estudio';

  @override
  String get createStudyPlan => 'Crear Plan de Estudio';

  @override
  String get courseSubject => 'Curso/Materia';

  @override
  String get courseHint => 'ej., Física IB';

  @override
  String get days => 'Días';

  @override
  String get hoursPerDay => 'Horas/Día';

  @override
  String get generatePlan => 'Generar Plan';

  @override
  String get generating => 'Generando...';

  @override
  String get yourStudySchedule => 'Tu Horario de Estudio';

  @override
  String topicLabel(int number) {
    return 'Tema $number';
  }

  @override
  String sessionDurationMinutes(int minutes) {
    return '$minutes min de sesión';
  }

  @override
  String get fillAllFieldsCorrectly =>
      'Por favor complete todos los campos correctamente';

  @override
  String generatedPlanOverDays(String course, int days, int totalHours) {
    return 'Plan generado para $course en $days días ($totalHours horas totales)';
  }

  @override
  String overDaysPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
      zero: '0 días',
    );
    return 'en $_temp0';
  }

  @override
  String totalHoursPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas totales',
      one: '1 hora total',
    );
    return '$_temp0';
  }

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String get unknown => 'Desconocido';

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}d',
      one: '1d',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}h',
      one: '1h',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}m',
      one: '1m',
    );
    return '$_temp0';
  }

  @override
  String durationSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}s',
      one: '1s',
    );
    return '$_temp0';
  }

  @override
  String get practiceMode => 'Modo de Práctica';

  @override
  String get practiceOptions => 'Opciones de Práctica';

  @override
  String get noSubjects => 'Sin Materias';

  @override
  String get noPracticeSessionsYet => 'Sin Sesiones de Práctica';

  @override
  String get addSubjectsAndQuestionsToStartPracticing =>
      'Agrega materias y preguntas para comenzar a practicar';

  @override
  String get addSubjectsFromSubjectsTab =>
      'Agrega materias desde la pestaña Materias';

  @override
  String get addSubject => 'Agregar Materia';

  @override
  String get practiceModes => 'Modos de Práctica';

  @override
  String get quickPractice => 'Práctica Rápida';

  @override
  String randomQuestions(int count) {
    return '$count preguntas aleatorias';
  }

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get spacedRepetition => 'Repetición Espaciada';

  @override
  String get topicFocus => 'Enfoque por Tema';

  @override
  String get practiceSpecificTopics => 'Practica temas específicos';

  @override
  String get weakAreas => 'Áreas Débiles';

  @override
  String get focusOnMistakes => 'Enfócate en tus errores';

  @override
  String get yourSubjects => 'Tus Materias';

  @override
  String get readyForPractice => 'Listo para practicar';

  @override
  String get practiceAvailable => 'Práctica disponible';

  @override
  String get selectSubject => 'Seleccionar Materia';

  @override
  String get practiceModeTitle => 'Modo de Práctica';

  @override
  String get autoSelect => 'Selección Automática';

  @override
  String get aiPicksOptimalQuestions => 'La IA selecciona preguntas óptimas';

  @override
  String get chooseSubject => 'Elegir Materia';

  @override
  String get noCode => 'Sin código';

  @override
  String get topicSelectionComingSoon => '¡Selección de temas próximamente!';

  @override
  String get noQuestionsAvailable => 'No Hay Preguntas Disponibles';

  @override
  String get noQuestionsForSelectedSubject =>
      'No hay preguntas para la materia/tema seleccionado. ¡Comienza a crear preguntas!';

  @override
  String get time => 'Tiempo';

  @override
  String get score => 'Puntuación';

  @override
  String get correct => 'Correctas';

  @override
  String get yourAnswer => 'Tu Respuesta';

  @override
  String yourAnswerCharacters(int count) {
    return 'Tu Respuesta ($count caracteres)';
  }

  @override
  String get submitAnswer => 'Enviar Respuesta';

  @override
  String get correctFeedback => '¡Correcto!';

  @override
  String get incorrectFeedback => 'Incorrecto';

  @override
  String get previous => 'Anterior';

  @override
  String get next => 'Siguiente';

  @override
  String get sessionResults => 'Resultados de la Sesión';

  @override
  String get practiceComplete => '¡Práctica Completada!';

  @override
  String get totalQuestions => 'Total de Preguntas';

  @override
  String get correctAnswers => 'Respuestas Correctas';

  @override
  String get accuracy => 'Precisión';

  @override
  String get practiceAgain => 'Practicar de Nuevo';
}
