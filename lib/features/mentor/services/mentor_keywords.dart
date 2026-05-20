class MentorKeywords {
  MentorKeywords._();

  static const Map<String, List<String>> extractKeywordsByLocale = {
    'en': ['about ', 'for ', 'on ', 'study ', 'learn ', 'review ', 'practice '],
    'es': ['sobre ', 'para ', 'de ', 'estudiar ', 'aprender ', 'repasar ', 'practicar ', 'acerca de ', 'acerca '],
    'fr': ['à propos de ', 'pour ', 'sur ', 'étudier ', 'apprendre ', 'réviser ', 'pratiquer '],
    'de': ['über ', 'für ', 'zu ', 'studieren ', 'lernen ', 'wiederholen ', 'üben '],
  };

  static const Map<String, List<String>> extractTopicKeywordsByLocale = {
    'en': ['topic ', 'subject ', 'lesson '],
    'es': ['tema ', 'materia ', 'lección ', 'asignatura '],
    'fr': ['sujet ', 'matière ', 'leçon '],
    'de': ['thema ', 'fach ', 'lektion '],
  };

  static const Map<String, List<String>> scheduleKeywordsByLocale = {
    'en': ['schedule'],
    'es': ['programar', 'agendar', 'citar'],
  };

  static const Map<String, List<String>> rescheduleKeywordsByLocale = {
    'en': ['reschedule', 'move ', 'postpone'],
    'es': ['reprogramar', 'reagendar', 'mover', 'posponer'],
  };

  static const Map<String, List<String>> planKeywordsByLocale = {
    'en': ['plan', 'roadmap', 'milestone'],
    'es': ['plan', 'planificar', 'hoja de ruta', 'hito'],
  };
}
