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
}
