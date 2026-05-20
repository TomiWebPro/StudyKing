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
  String get courseHint => 'p. ej., Física IB';

  @override
  String get days => 'Días';

  @override
  String get hoursPerDay => 'Horas/Día';

  @override
  String get generatePlan => 'Generar Plan';

  @override
  String get generating => 'Generando...';

  @override
  String get generatingReport => 'Generando informe...';

  @override
  String get yourStudySchedule => 'Su Horario de Estudio';

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
      'Por favor, complete todos los campos correctamente';

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
      'Agregue materias y preguntas para comenzar a practicar';

  @override
  String get addSubjectsFromSubjectsTab =>
      'Agregue materias desde la pestaña Materias';

  @override
  String get addSubject => 'Agregar Materia';

  @override
  String get practiceModes => 'Modos de Práctica';

  @override
  String get quickPractice => 'Práctica Rápida';

  @override
  String randomQuestions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count preguntas aleatorias',
      one: '1 pregunta aleatoria',
    );
    return '$_temp0';
  }

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get spacedRepetition => 'Repetición Espaciada';

  @override
  String get topicFocus => 'Enfoque por Tema';

  @override
  String get practiceSpecificTopics => 'Practique temas específicos';

  @override
  String get weakAreas => 'Áreas por mejorar';

  @override
  String get focusOnMistakes => 'Concéntrese en sus errores';

  @override
  String get yourSubjects => 'Sus Materias';

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
  String get noWeakAreasFound =>
      'No se encontraron áreas por mejorar. ¡Siga así!';

  @override
  String get atRiskQuestions => 'Preguntas en Riesgo';

  @override
  String get atRiskQuestionsDescription =>
      'Practica preguntas con puntuaciones de dominio más bajas';

  @override
  String get noWeakAreasQuestions =>
      'No hay preguntas disponibles para sus áreas por mejorar.';

  @override
  String get noQuestionsAvailable => 'No Hay Preguntas Disponibles';

  @override
  String get noQuestionsForSelectedSubject =>
      'No hay preguntas para la materia/tema seleccionado. ¡Comience a crear preguntas!';

  @override
  String get time => 'Tiempo';

  @override
  String get score => 'Puntuación';

  @override
  String get correct => 'Correctas';

  @override
  String get yourAnswer => 'Su Respuesta';

  @override
  String yourAnswerCharacters(int count) {
    return 'Su Respuesta ($count caracteres)';
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
  String get accuracy => 'Exactitud';

  @override
  String get examConfiguration => 'Configuración del Examen';

  @override
  String get startExam => 'Comenzar Examen';

  @override
  String get examDuration => 'Duración del Examen';

  @override
  String get numberOfQuestions => 'Número de Preguntas';

  @override
  String get incorrectLabel => 'Incorrectas';

  @override
  String get skippedLabel => 'Omitidas';

  @override
  String get examAutoSubmitted =>
      'El examen se envió automáticamente cuando se agotó el tiempo.';

  @override
  String get topicBreakdown => 'Desglose por Tema';

  @override
  String startingPractice(String mode) {
    return 'Comenzando $mode...';
  }

  @override
  String get backToPractice => 'Volver a la Práctica';

  @override
  String get swipeToDelete => 'Deslizar para eliminar';

  @override
  String get valueMustBePositive => 'El valor debe ser positivo';

  @override
  String get correctExceedsQuestions =>
      'Las respuestas correctas no pueden exceder el total de preguntas';

  @override
  String get practiceAgain => 'Practicar de Nuevo';

  @override
  String get allCaughtUp => '¡Todo al día!';

  @override
  String get noReviewsScheduled => 'No hay repasos programados.';

  @override
  String dueQuestionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pendientes',
      one: '1 pendiente',
    );
    return '$_temp0';
  }

  @override
  String get reviewDueQuestions => 'Repasar preguntas pendientes';

  @override
  String get selectTopic => 'Seleccionar Tema';

  @override
  String get noTopicsAvailable => 'No hay temas disponibles';

  @override
  String get questionsDueForReview => 'preguntas pendientes de repaso';

  @override
  String get spacedRepetitionMode => 'Repetición Espaciada';

  @override
  String get colorBlue => 'Azul';

  @override
  String get colorGreen => 'Verde';

  @override
  String get colorOrange => 'Naranja';

  @override
  String get colorPurple => 'Morado';

  @override
  String get colorPink => 'Rosa';

  @override
  String get colorCyan => 'Cian';

  @override
  String get colorAmber => 'Ámbar';

  @override
  String get colorDeepOrange => 'Naranja Oscuro';

  @override
  String get colorBlueGrey => 'Gris Azulado';

  @override
  String get profile => 'Perfil';

  @override
  String get nameIsRequired => 'El nombre es obligatorio';

  @override
  String get studentIdMustBeNumeric => 'El ID de estudiante debe ser numérico';

  @override
  String get profileSavedSuccessfully => 'Perfil guardado exitosamente';

  @override
  String errorSavingProfile(String error) {
    return 'Error al guardar el perfil: $error';
  }

  @override
  String get chooseAvatar => 'Elegir Avatar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get cancel => 'Cancelar';

  @override
  String selectAvatar(String iconKey) {
    return 'Seleccionar avatar $iconKey';
  }

  @override
  String get fullName => 'Nombre Completo';

  @override
  String get enterYourName => 'Ingrese su nombre';

  @override
  String get studentIdOptional => 'ID de Estudiante (Opcional)';

  @override
  String get yourStudentIdNumber => 'Su número de ID de estudiante';

  @override
  String get learningGoal => 'Objetivo de Aprendizaje';

  @override
  String get learningGoalHint => 'p. ej., Exámenes Finales, Certificaciones';

  @override
  String get preferredStudyTime => 'Horario de Estudio Preferido';

  @override
  String get preferredStudyTimeHint => 'p. ej., Tarde (6-9 p. m.)';

  @override
  String get accountInformation => 'Información de la Cuenta';

  @override
  String get language => 'Idioma';

  @override
  String get english => 'Inglés';

  @override
  String get spanish => 'Español';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get deleteAccountWarning =>
      'Eliminar su cuenta eliminará permanentemente todos los datos de estudio';

  @override
  String get delete => 'Eliminar';

  @override
  String get deleteAccount => 'Eliminar Cuenta';

  @override
  String get deleteAccountConfirmation =>
      '¿Está seguro de que desea eliminar su cuenta? Esta acción no se puede deshacer y eliminará permanentemente todos sus datos de estudio.';

  @override
  String get save => 'Guardar';

  @override
  String get userManagement => 'Gestión de Usuarios';

  @override
  String get currentUser => 'Usuario Actual';

  @override
  String get manageYourProfile => 'Administre su perfil';

  @override
  String get quickAccess => 'Acceso Rápido';

  @override
  String get quickGuide => 'Guía Rápida';

  @override
  String get aiPoweredStudyAssistant => 'Asistente de estudio impulsado por IA';

  @override
  String get appearance => 'Apariencia';

  @override
  String get theme => 'Tema';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get system => 'Sistema';

  @override
  String get fontSize => 'Tamaño de Fuente';

  @override
  String get small => 'Pequeño';

  @override
  String get fontSizeMedium => 'Mediano';

  @override
  String get large => 'Grande';

  @override
  String get leaveAnyway => 'Salir de todas formas';

  @override
  String get extraLarge => 'Extra Grande';

  @override
  String get aiConfiguration => 'Configuración de IA';

  @override
  String get apiKeys => 'Claves API';

  @override
  String get configured => 'Configurado';

  @override
  String get notConfigured => 'No configurado';

  @override
  String get aiModel => 'Modelo de IA';

  @override
  String get selectModelFromApi => 'Seleccione un modelo desde la API';

  @override
  String get requestTimeout => 'Tiempo de Espera';

  @override
  String secondsValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count segundos',
      one: '1 segundo',
    );
    return '$_temp0';
  }

  @override
  String get studyPreferences => 'Preferencias de Estudio';

  @override
  String get studyReminders => 'Recordatorios de Estudio';

  @override
  String get enableNotificationAlerts => 'Activar alertas de notificación';

  @override
  String get sessionDuration => 'Duración de la Sesión';

  @override
  String minutesValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutos',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String get studyAnalytics => 'Analítica de Estudio';

  @override
  String get totalStudySessions => 'Sesiones de Estudio Totales';

  @override
  String sessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesiones',
      one: '1 sesión',
    );
    return '$_temp0';
  }

  @override
  String get totalStudyTime => 'Tiempo Total de Estudio';

  @override
  String get aboutSection => 'Acerca de';

  @override
  String get aboutStudyKing => 'Acerca de StudyKing';

  @override
  String get versionInfo => 'Versión 0.1.0';

  @override
  String get signOut => 'Cerrar Sesión';

  @override
  String get apiKeyRequired => 'Clave API Requerida';

  @override
  String get pleaseConfigureApiKey =>
      'Por favor configure su clave API primero.';

  @override
  String get ok => 'Aceptar';

  @override
  String get unableToLoadModels =>
      'No se pueden cargar los modelos en este momento.';

  @override
  String get searchModels => 'Buscar modelos';

  @override
  String get modelRequestTimedOut =>
      'La solicitud del modelo superó el tiempo de espera. Intente de nuevo.';

  @override
  String get unableToLoadModelsTryAgain =>
      'No se pueden cargar los modelos. Intente de nuevo.';

  @override
  String mentorInitFailed(String error) {
    return 'Inicialización del mentor falló: $error. Ve a Configuración para configurar tu proveedor de IA, o reintenta.';
  }

  @override
  String get contentPipelineNotAvailable =>
      'Pipeline de contenido no disponible';

  @override
  String get mentorInitFailedHint =>
      'Problema de conexión — configura el proveedor de IA en Configuración';

  @override
  String tutorInitFailed(String error) {
    return 'Inicialización del tutor falló: $error. Ve a Configuración para configurar tu proveedor de IA, o reintenta.';
  }

  @override
  String get goBack => 'Volver';

  @override
  String get tapToRefreshSection => 'Toque para actualizar esta sección';

  @override
  String get retry => 'Reintentar';

  @override
  String get signOutConfirmation => '¿Está seguro de que desea cerrar sesión?';

  @override
  String get sessionsLabel => 'Sesiones';

  @override
  String get noActivity => 'Sin actividad — estuvo ausente esta semana.';

  @override
  String get questionsLabel => 'Preguntas';

  @override
  String get mySubjects => 'Mis Materias';

  @override
  String get addNewSubject => 'Agregar Nueva Materia';

  @override
  String get subjectName => 'Nombre de la Materia';

  @override
  String get subjectNameHint => 'p. ej., Física';

  @override
  String get subjectCodeOptional => 'Código de Materia (Opcional)';

  @override
  String get subjectCodeHint => 'p. ej., IB-FIS';

  @override
  String get themeColor => 'Color del Tema';

  @override
  String get subjectColor => 'Color de la Materia';

  @override
  String get examDateOptional => 'Fecha de Examen (Opcional)';

  @override
  String get backupAndRestore => 'Copia de Seguridad';

  @override
  String get backupAndRestoreTooltip => 'Copia de seguridad y restaurar';

  @override
  String get exportBackup => 'Exportar Copia';

  @override
  String get exportAllDataDescription => 'Exportar todos tus datos de estudio';

  @override
  String get importBackup => 'Importar Copia';

  @override
  String get importFromFileDescription => 'Restaurar desde un archivo de copia';

  @override
  String get backupExported => 'Copia exportada exitosamente';

  @override
  String get backupExportFailed => 'Error al exportar la copia';

  @override
  String get importConfirmTitle => 'Importar Copia de Seguridad';

  @override
  String importPreview(int boxes, int records) {
    String _temp0 = intl.Intl.pluralLogic(
      boxes,
      locale: localeName,
      other: '$boxes secciones',
      one: '1 sección',
    );
    String _temp1 = intl.Intl.pluralLogic(
      records,
      locale: localeName,
      other: '$records registros',
      one: '1 registro',
    );
    return 'Esta copia contiene $_temp0 con $_temp1. Los datos actuales pueden sobrescribirse. ¿Continuar?';
  }

  @override
  String get importSuccess => 'Datos restaurados exitosamente';

  @override
  String get importFailed => 'Error al restaurar los datos';

  @override
  String get invalidBackupFile => 'Archivo de copia no válido';

  @override
  String get selectBackupFile => 'Seleccionar archivo de copia';

  @override
  String get selectDate => 'Seleccionar fecha';

  @override
  String get createSubject => 'Crear Materia';

  @override
  String get subjectCreatedSuccessfully => 'Materia creada exitosamente';

  @override
  String uploadPrompt(String subject) {
    return '¿Desea subir material de estudio para $subject?';
  }

  @override
  String get noThanks => 'No, gracias';

  @override
  String errorCreatingSubject(String error) {
    return 'Error al crear la materia: $error';
  }

  @override
  String get pleaseEnterSubjectName =>
      'Por favor ingrese un nombre para la materia';

  @override
  String get descriptionOptional => 'Descripción (Opcional)';

  @override
  String get descriptionHint => 'Breve descripción de la materia';

  @override
  String get teacherOptional => 'Profesor (Opcional)';

  @override
  String get teacherHint => 'p. ej., Dr. Juan García';

  @override
  String get syllabusScopeOptional => 'Plan de Estudios/Alcance (Opcional)';

  @override
  String get syllabusHint => 'Breve resumen del plan de estudios';

  @override
  String get teacherNameHint => 'Ingrese el nombre del profesor';

  @override
  String get syllabusDescriptionHint =>
      'Ingrese la descripción del plan de estudios';

  @override
  String get noSubjectsYet => 'Sin materias todavía';

  @override
  String get addFirstSubject =>
      'Agregue su primera materia para comenzar a estudiar';

  @override
  String get practiceSessions => 'Sesiones de práctica';

  @override
  String get startPractice => 'Comenzar Práctica';

  @override
  String get noPracticeHistory => 'Sin historial de práctica';

  @override
  String get viewAllSessions => 'Ver Todas las Sesiones';

  @override
  String get editSubject => 'Editar Materia';

  @override
  String get deleteSubject => 'Eliminar Materia';

  @override
  String get deleteSubjectConfirmation =>
      '¿Está seguro de que desea eliminar esta materia? Esto también eliminará todas las lecciones y preguntas asociadas.';

  @override
  String get sessionDetails => 'Detalles de la Sesión';

  @override
  String get close => 'Cerrar';

  @override
  String get date => 'Fecha';

  @override
  String get duration => 'Duración';

  @override
  String get questions => 'Preguntas';

  @override
  String get lessonsTab => 'Lecciones';

  @override
  String get practiceTab => 'Práctica';

  @override
  String get historyTab => 'Historial';

  @override
  String get statsTab => 'Estadísticas';

  @override
  String get noLessonsYet => 'Sin lecciones todavía';

  @override
  String get startLearningByCreatingTopics =>
      'Comience a aprender creando temas y preguntas';

  @override
  String get addTopic => 'Agregar Tema';

  @override
  String get lesson => 'Lección';

  @override
  String questionsCount(int count) {
    return 'Preguntas: $count';
  }

  @override
  String practiceQuestionsFrom(String subjectName) {
    return 'Practique preguntas de $subjectName';
  }

  @override
  String get practiceProgress => 'Progreso de la Práctica';

  @override
  String get overallScore => 'Puntuación General';

  @override
  String get keepPracticing => '¡Siga practicando para mejorar su puntuación!';

  @override
  String sessionNumber(int number) {
    return 'Sesión $number';
  }

  @override
  String get selectFormat => 'Seleccione el formato de pregunta:';

  @override
  String get studySessionTracker => 'Seguimiento de sesiones de estudio';

  @override
  String get start => 'Iniciar';

  @override
  String get end => 'Finalizar';

  @override
  String get sessionComplete => 'Sesión Completada';

  @override
  String get howManyQuestions => '¿Cuántas preguntas respondió?';

  @override
  String get questionsAnswered => 'Preguntas Respondidas';

  @override
  String get skip => 'Omitir';

  @override
  String get graphRenderer => 'Renderizador de Gráficos';

  @override
  String get refreshGraph => 'Actualizar gráfico';

  @override
  String get validateGraphType => 'Validar tipo de gráfico';

  @override
  String get uploadData => 'Subir Datos';

  @override
  String get uploadDataFile => 'Subir Archivo de Datos';

  @override
  String get orPasteDataDirectly => 'O pegue los datos directamente:';

  @override
  String get pasteDataHint => 'Pegue datos separados por comas...';

  @override
  String get graphTypeDetection => 'Detección de Tipo de Gráfico';

  @override
  String get autoDetectFromData => 'Detección automática desde datos:';

  @override
  String get lineGraph => 'Gráfico de Líneas';

  @override
  String get barChart => 'Gráfico de Barras';

  @override
  String get scatterPlot => 'Diagrama de Dispersión';

  @override
  String get pieChart => 'Gráfico Circular';

  @override
  String get llmValidation => 'Validación con LLM';

  @override
  String get useLlmToValidateGraph => 'Usar LLM para validar el gráfico:';

  @override
  String get describeWhatYouSee => 'Describa lo que ve en el gráfico...';

  @override
  String get validateWithLlm => 'Validar con LLM';

  @override
  String get validating => 'Validando...';

  @override
  String get renderedGraph => 'Gráfico generado';

  @override
  String get noDataUploaded => 'No hay datos subidos';

  @override
  String get uploadOrPasteData => 'Suba o pegue datos para visualizar';

  @override
  String get selectGraphType => 'Seleccione un tipo de gráfico para visualizar';

  @override
  String graphVisualization(String graphType) {
    return 'Visualización de $graphType';
  }

  @override
  String dataPointsCount(int count) {
    return 'Puntos de datos: $count';
  }

  @override
  String graphTypeSetTo(String graphType) {
    return 'Gráfico cambiado a $graphType';
  }

  @override
  String get uploadDataFileDialog => 'Subir Archivo de Datos';

  @override
  String get fileUploadImplemented =>
      'La funcionalidad de carga de archivos se implementaría aquí.';

  @override
  String get graphValidation => 'Validación de Gráfico';

  @override
  String typeLabel(String graphType) {
    return 'Tipo: $graphType';
  }

  @override
  String get considerUsingPieChart =>
      'Considere usar un gráfico circular para conjuntos pequeños de datos';

  @override
  String get considerUsingBarChart =>
      'Considere usar un gráfico de barras para conjuntos grandes de datos';

  @override
  String get graphTypeMatchesData =>
      'El tipo de gráfico coincide con la estructura de datos';

  @override
  String get graphRefreshed => 'Gráfico actualizado';

  @override
  String get pleaseSelectGraphType =>
      'Por favor seleccione un tipo de gráfico primero';

  @override
  String get validationComplete => 'Validación completada';

  @override
  String validationFailed(String error) {
    return 'Validación fallida: $error';
  }

  @override
  String get graphTypeDetectionError => 'Error al detectar el tipo de gráfico';

  @override
  String get imageCaptured =>
      'Imagen capturada. Puede agregar notas en el campo de contenido arriba.';

  @override
  String cameraError(String error) {
    return 'Error de cámara: $error';
  }

  @override
  String get lessonScheduler => 'Planificador de Lecciones';

  @override
  String get upcomingLessons => 'Próximas Lecciones';

  @override
  String get selectSubjectLabel => 'Seleccionar Materia';

  @override
  String get generateQuestionTypes => 'Generar Tipos de Preguntas';

  @override
  String get lessonProgress => 'Progreso de la Lección';

  @override
  String percentComplete(int percent, int completed, int total) {
    return '$percent % Completado: $completed/$total preguntas generadas';
  }

  @override
  String get scheduleLesson => 'Programar Lección';

  @override
  String get selectCalendarDate =>
      'Seleccione una fecha de calendario para la lección';

  @override
  String get done => 'Hecho';

  @override
  String get createNewLesson => 'Crear Nueva Lección';

  @override
  String get editExistingLesson => 'Editar Lección Existente';

  @override
  String get mcq => 'Opción Múltiple';

  @override
  String get inputLabel => 'Entrada';

  @override
  String get graphLabel => 'Gráfico';

  @override
  String get quickGuideHelp => 'Ayuda de Guía Rápida';

  @override
  String get help => 'Ayuda';

  @override
  String get quickGuideIsThinking => 'Guía Rápida está pensando...';

  @override
  String get suggestedPrompts => 'Sugerencias';

  @override
  String get askAnything => 'Pregunte lo que sea...';

  @override
  String get sendMessage => 'Enviar mensaje';

  @override
  String get messageInputHint => 'Escriba su pregunta aquí';

  @override
  String get quickGuideHelpTitle => 'Ayuda de Guía Rápida';

  @override
  String get gotIt => 'Entendido';

  @override
  String get addAnswerBeforeSubmitting =>
      'Agregue una respuesta antes de enviar.';

  @override
  String get nextQuestion => 'Siguiente Pregunta';

  @override
  String get type => 'Tipo';

  @override
  String get pdfLabel => 'PDF';

  @override
  String get syllabusLabel => 'Plan de estudios';

  @override
  String get textbookLabel => 'Libro de texto';

  @override
  String get videoLabel => 'Video';

  @override
  String get lectureNotesLabel => 'Apuntes de clase';

  @override
  String get externalResourceLabel => 'Recurso externo';

  @override
  String get imageLabel => 'Imagen';

  @override
  String get webPageLabel => 'Página web';

  @override
  String get audioLabel => 'Audio';

  @override
  String get documentLabel => 'Documento';

  @override
  String get typeYourAnswerHere => 'Escriba su respuesta aquí...';

  @override
  String get writeYourEssayAnswer => 'Escriba su respuesta de ensayo...';

  @override
  String get questionTypeNotSupported =>
      'Este tipo de pregunta aún no es compatible en esta vista.';

  @override
  String get multipleChoice => 'Opción Múltiple';

  @override
  String get multipleSelect => 'Selección Múltiple';

  @override
  String get textAnswer => 'Respuesta de Texto';

  @override
  String get math => 'Matemáticas';

  @override
  String get essay => 'Ensayo';

  @override
  String get diagram => 'Diagrama';

  @override
  String get graphQuestion => 'Gráfico';

  @override
  String get stepByStep => 'Paso a Paso';

  @override
  String get audioRecording => 'Grabación de Audio';

  @override
  String get canvas => 'Lienzo';

  @override
  String get fileUpload => 'Subir Archivo';

  @override
  String get graphDrawing => 'Dibujo de Gráfico';

  @override
  String difficultyLabel(String level) {
    return 'Dificultad: $level';
  }

  @override
  String get easy => 'Fácil';

  @override
  String get difficultyMedium => 'Mediano';

  @override
  String get hard => 'Difícil';

  @override
  String get selectAsAnswer => 'Seleccionar como respuesta';

  @override
  String get selectedRightOption => 'Opción correcta seleccionada';

  @override
  String get tryAgain => 'Intente de nuevo';

  @override
  String get drawHere => 'Dibuje aquí...';

  @override
  String get undoLastStroke => 'Deshacer último trazo';

  @override
  String get redoLastStroke => 'Rehacer último trazo';

  @override
  String get openDrawingCanvas => 'Abrir lienzo de dibujo';

  @override
  String get clearAllDrawings => 'Borrar todos los dibujos';

  @override
  String get canvasIsEmpty => 'El lienzo está vacío';

  @override
  String drawingWithStrokes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dibujo con $count trazos',
      one: 'Dibujo con 1 trazo',
    );
    return '$_temp0';
  }

  @override
  String get saveDrawing => 'Guardar Dibujo';

  @override
  String get drawingSaved => 'Dibujo guardado.';

  @override
  String get failedToSaveDrawing => 'Error al guardar el dibujo. Reintente.';

  @override
  String get drawingCanvas => 'Lienzo de dibujo';

  @override
  String get drawYourAnswer =>
      'Dibuje su respuesta en el lienzo usando su dedo o lápiz óptico';

  @override
  String get apiConfiguration => 'Configuración de API';

  @override
  String get configureApiKeys => 'Configurar Claves API';

  @override
  String get configureApiKeysDescription =>
      'Ingrese sus credenciales de OpenRouter a continuación. Se utilizan para impulsar las funciones de IA.';

  @override
  String get openRouterApiKey => 'Clave API de OpenRouter';

  @override
  String get apiBaseUrl => 'URL Base de la API';

  @override
  String get apiKeyHint => 'sk-or-v1-...';

  @override
  String get apiBaseUrlHint => 'https://openrouter.ai/api/v1';

  @override
  String get apiKeyDescription =>
      'Requerido para la generación de contenido con LLM. Obtenga su clave en https://openrouter.ai/keys';

  @override
  String get apiBaseUrlDescription =>
      'La URL del endpoint para el servicio de IA';

  @override
  String get saveApiKeys => 'Guardar Claves API';

  @override
  String get apiKeyCannotBeEmpty => 'La clave API no puede estar vacía';

  @override
  String get apiKeysSavedSuccessfully => 'Claves API guardadas exitosamente';

  @override
  String get unableToSaveApiConfig =>
      'No se puede guardar la configuración de API. Intente de nuevo.';

  @override
  String get currentSession => 'Sesión Actual';

  @override
  String get noActiveSession => 'Sin Sesión Activa';

  @override
  String get tapStartToBegin => 'Toque Iniciar para comenzar a rastrear';

  @override
  String get recentSessions => 'Sesiones Recientes';

  @override
  String ofLabel(int count1, int count2) {
    return '$count1 de $count2';
  }

  @override
  String get viewAll => 'Ver Todo';

  @override
  String get noSessionsYet => 'Sin sesiones todavía';

  @override
  String get startYourFirstSession => '¡Comience su primera sesión!';

  @override
  String get filterByDate => 'Filtrar por Fecha';

  @override
  String get filterBySubject => 'Filtrar por Materia';

  @override
  String get clearFilters => 'Limpiar filtros';

  @override
  String get clearFilterLabel => 'Limpiar';

  @override
  String get totalTime => 'Tiempo Total';

  @override
  String get average => 'Promedio';

  @override
  String get noSessionsFoundForFilters =>
      'No se encontraron sesiones para los filtros seleccionados';

  @override
  String get tryAdjustingFilters => 'Intente ajustar sus filtros';

  @override
  String get startStudyingToTrack =>
      'Comience a estudiar para rastrear su progreso';

  @override
  String get sessionDeleted => 'Sesión eliminada';

  @override
  String get undo => 'Deshacer';

  @override
  String failedToDeleteSession(String error) {
    return 'Error al eliminar la sesión: $error';
  }

  @override
  String get deleteSession => 'Eliminar Sesión';

  @override
  String get deleteSessionConfirmation =>
      '¿Está seguro de que desea eliminar esta sesión?';

  @override
  String get noQuestions => 'Sin preguntas';

  @override
  String questionsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count preguntas',
      one: '1 pregunta',
    );
    return '$_temp0';
  }

  @override
  String correctOf(int correct, int total) {
    return 'Correctas: $correct/$total';
  }

  @override
  String get selectDateToFilter => 'Seleccione una fecha para filtrar sesiones';

  @override
  String get filterBySubjectTitle => 'Filtrar por Materia';

  @override
  String get sessionHistory => 'Historial de Sesiones';

  @override
  String get dashboard => 'Panel';

  @override
  String get studyDashboard => 'Panel de Estudio';

  @override
  String get studyTime => 'Tiempo de Estudio';

  @override
  String get planAdherence => 'Cumplimiento del Plan';

  @override
  String get masteryOverview => 'Resumen de Dominio';

  @override
  String get topicPerformance => 'Rendimiento por Tema';

  @override
  String get achievements => 'Logros';

  @override
  String get exportCsv => 'Exportar CSV';

  @override
  String get instrumentation => 'Estadísticas de Progreso';

  @override
  String get overall => 'General';

  @override
  String get thisWeek => 'Esta Semana';

  @override
  String get totalTopics => 'Temas Totales';

  @override
  String get mastered => 'Dominados';

  @override
  String get topics => 'Temas';

  @override
  String get practiceAllWeakAreas => 'Practicar Todas las áreas por mejorar';

  @override
  String get practiceThisTopic => 'Practicar este tema';

  @override
  String get noTopicDataYet =>
      'Aún no hay datos de temas. ¡Empiece a estudiar para ver su progreso!';

  @override
  String get masteryLevelNovice => 'Novato';

  @override
  String get masteryLevelBrowsing => 'Explorando';

  @override
  String get masteryLevelDeveloping => 'En Desarrollo';

  @override
  String get masteryLevelProficient => 'Competente';

  @override
  String get masteryLevelExpert => 'Experto';

  @override
  String progressCsvGenerated(int length) {
    return 'CSV de progreso generado ($length caracteres)';
  }

  @override
  String exportFailed(String error) {
    return 'Error al exportar: $error';
  }

  @override
  String get instrumentationDataExported =>
      'Datos de instrumentación exportados';

  @override
  String attemptsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count intentos',
      one: '1 intento',
    );
    return '$_temp0';
  }

  @override
  String get weakAreasAccuracy => 'Áreas por mejorar (Precisión < 60 %)';

  @override
  String get uploadContent => 'Subir Contenido';

  @override
  String get addStudyMaterials =>
      'Agregue materiales de estudio a su biblioteca';

  @override
  String get titleRequired => 'Título *';

  @override
  String get titleHint => 'p. ej. Notas del Capítulo 5';

  @override
  String get subjectOptional => 'Materia (opcional)';

  @override
  String get none => 'Ninguno';

  @override
  String get pasteText => 'Pegar Texto';

  @override
  String get urlLink => 'URL / Enlace';

  @override
  String get urlRequired => 'URL *';

  @override
  String get urlHint => 'https://example.com/notas';

  @override
  String get contentRequired => 'Contenido *';

  @override
  String get contentHint => 'Pegue su material de estudio aquí...';

  @override
  String get uploading => 'Subiendo...';

  @override
  String get fillRequiredFields =>
      'Por favor complete todos los campos requeridos.';

  @override
  String get contentUploadedSuccessfully => '¡Contenido subido exitosamente!';

  @override
  String uploadFailed(String error) {
    return 'Error al cargar: $error';
  }

  @override
  String get planSummary => 'Resumen del Plan';

  @override
  String get total => 'Total';

  @override
  String get newTopics => 'nuevos';

  @override
  String get reviewTopics => 'revisión';

  @override
  String get coverage => 'Cobertura';

  @override
  String focusLabel(String areas) {
    return 'Enfoque: $areas';
  }

  @override
  String get studyDay => 'Día de Estudio';

  @override
  String get rest => 'Descanso';

  @override
  String get startTutoring => 'Iniciar tutoría';

  @override
  String questionsAndMinutes(int questions, int minutes) {
    return '${questions}P · ${minutes}min';
  }

  @override
  String topicQuestionsAndMinutes(int questions, int minutes) {
    return '${questions}P · ${minutes}min';
  }

  @override
  String get failedToGeneratePlan => 'Error al generar el plan';

  @override
  String get llmTaskManager => 'Administrador de Tareas LLM';

  @override
  String activeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activas',
      one: '1 activa',
    );
    return '$_temp0';
  }

  @override
  String get noLlmTasksYet => 'Aún no hay tareas LLM';

  @override
  String modelLabel(String modelId) {
    return 'Modelo: $modelId';
  }

  @override
  String startedLabel(String time) {
    return 'Iniciado: $time';
  }

  @override
  String endedLabel(String time) {
    return 'Finalizado: $time';
  }

  @override
  String tokensAndCost(int count, String cost) {
    return 'Fichas: $count ($cost)';
  }

  @override
  String get cancelTask => 'Cancelar';

  @override
  String get testConnection => 'Probar Conexión';

  @override
  String get testing => 'Probando...';

  @override
  String connectionSuccessful(int latency) {
    return '¡Conexión exitosa! Latencia: ${latency}ms';
  }

  @override
  String connectionFailed(String error) {
    return 'Conexión fallida: $error';
  }

  @override
  String sessionHistoryCsvGenerated(int length) {
    return 'CSV de historial de sesiones generado ($length caracteres)';
  }

  @override
  String dailyPlanTarget(int questions, int minutes) {
    return 'Hoy: ${questions}P, ${minutes}min';
  }

  @override
  String get noPlanForToday => 'Sin plan para hoy';

  @override
  String planAdjustmentSuggested(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return 'Ha tenido $_temp0 de bajo cumplimiento del plan. ¿Desea ajustar su plan de estudio?';
  }

  @override
  String get adjustPlan => 'Ajustar Plan';

  @override
  String get dismiss => 'Descartar';

  @override
  String get voiceInput => 'Entrada de Voz';

  @override
  String get captureImage => 'Capturar Imagen';

  @override
  String get camera => 'Cámara';

  @override
  String errorSavingSubject(String error) {
    return 'Error al guardar la materia: $error';
  }

  @override
  String failedToSaveSession(String error) {
    return 'Error al guardar la sesión: $error';
  }

  @override
  String get avgSession => 'Sesión Prom.';

  @override
  String get totalSessionsLabel => 'Sesiones Totales';

  @override
  String get currentStreakLabel => 'Racha Actual';

  @override
  String get sessionsByDayOfWeek => 'Sesiones por Día de la Semana';

  @override
  String get performanceMetrics => 'Métricas de Rendimiento';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get noTopicsYetAddSome => '¿No hay temas? ¡Agregue algunos!';

  @override
  String get noLessonsUsePlanner =>
      '¿No hay lecciones? ¡Use el Planificador para generar!';

  @override
  String get mentor => 'Mentor';

  @override
  String get startAiTutoring => 'Iniciar Tutoría IA';

  @override
  String get endLesson => 'Finalizar Lección';

  @override
  String get typeYourMessage => 'Escriba su mensaje...';

  @override
  String get send => 'Enviar';

  @override
  String get progressReport => 'Informe de Progreso';

  @override
  String get askMentorAnything => 'Pregúntele a su mentor...';

  @override
  String get mentorGreeting => 'Mentor IA';

  @override
  String get mentorSubtitle => 'Su asistente académico personal IA';

  @override
  String get startingLesson => 'Iniciando su lección...';

  @override
  String get lessonTimeEnded =>
      'El tiempo de lección terminó. Toque \'Finalizar Lección\' para terminar.';

  @override
  String get lessonComplete => 'Lección Completada';

  @override
  String get errorOccurred => 'Ocurrió un error. Intente de nuevo.';

  @override
  String get inProgress => 'En Progreso';

  @override
  String get completed => 'Completado';

  @override
  String get notStarted => 'No Iniciado';

  @override
  String blocksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bloques',
      one: '1 bloque',
    );
    return '$_temp0';
  }

  @override
  String get blockTypeExplanation => 'Explicación';

  @override
  String get blockTypeExample => 'Ejemplo';

  @override
  String get blockTypeExercise => 'Ejercicio';

  @override
  String get blockTypeSlide => 'Diapositiva';

  @override
  String get blockTypeQuiz => 'Cuestionario';

  @override
  String get blockTypeSummary => 'Resumen';

  @override
  String practiceModeType(String mode, String type) {
    return '$mode - $type';
  }

  @override
  String get examMode => 'Modo de Examen';

  @override
  String get examModeDescription => 'Simulación de examen cronometrado';

  @override
  String get sourcePractice => 'Práctica por Fuente';

  @override
  String get sourcePracticeDescription => 'Practique por fuente';

  @override
  String get noSourcesAvailable => 'No hay fuentes disponibles';

  @override
  String get howConfident => '¿Qué tan seguro está?';

  @override
  String get confidenceRatingOf => 'de';

  @override
  String get notConfidentAtAll => 'Nada seguro';

  @override
  String get slightlyConfident => 'Ligeramente seguro';

  @override
  String get moderatelyConfident => 'Moderadamente seguro';

  @override
  String get quiteConfident => 'Bastante seguro';

  @override
  String get veryConfident => 'Muy seguro';

  @override
  String get reviewMistakes => 'Revisar Errores';

  @override
  String reviewMistakesDescription(int count) {
    return 'Revisar $count errores de esta sesión';
  }

  @override
  String get noMistakesToReview => 'No hay errores que revisar';

  @override
  String get redoIncorrectQuestions => 'Rehacer Preguntas Incorrectas';

  @override
  String get noAnswerProvided => 'No se proporcionó respuesta';

  @override
  String get correctAnswer => 'Respuesta Correcta';

  @override
  String get practiceBySource => 'Practicar por Fuente';

  @override
  String get practiceBySourceDescription =>
      'Seleccione una fuente para practicar preguntas';

  @override
  String fallbackOption(int number) {
    return 'Opción $number';
  }

  @override
  String get drawingSubmitted => 'Dibujo enviado';

  @override
  String unsupportedQuestionType(String type) {
    return 'Tipo de pregunta no compatible: $type';
  }

  @override
  String get todaysPlan => 'Plan de Hoy';

  @override
  String get noStudyPlanToday => 'No hay plan de estudio para hoy';

  @override
  String questionsCountMetric(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count preguntas',
      one: '1 pregunta',
    );
    return '$_temp0';
  }

  @override
  String questionsAbbreviation(int count) {
    return '${count}P';
  }

  @override
  String minutesCountMetric(int count) {
    return '$count min';
  }

  @override
  String get atRiskTopics => 'Temas en riesgo';

  @override
  String get noAtRiskTopics => 'No hay temas en riesgo. ¡Siga así!';

  @override
  String accuracyLabel(String percent) {
    return 'Precisión: $percent';
  }

  @override
  String get readyToAdvance => 'Listo para Avanzar';

  @override
  String get keepPracticingToUnlock =>
      '¡Siga practicando para desbloquear temas avanzados!';

  @override
  String get totalTopicsLabel => 'Total de Temas';

  @override
  String get masteredLabel => 'Dominados';

  @override
  String get weakLabel => 'Por mejorar';

  @override
  String avgAccuracyLabel(String percent) {
    return 'Precisión Prom.: $percent';
  }

  @override
  String avgReadinessLabel(String percent) {
    return 'Preparación Prom.: $percent';
  }

  @override
  String courseSessionLabel(String course, int number) {
    return '$course - Sesión $number';
  }

  @override
  String get quickGuideWelcomeMessage =>
      '¡Hola! Soy la Guía Rápida de StudyKing. ¡Pregúnteme lo que sea sobre sus estudios!';

  @override
  String get suggestedPromptExplain => 'Explica la fotosíntesis';

  @override
  String get suggestedPromptQuiz => 'Examíname de historia';

  @override
  String get suggestedPromptMath => 'Ayuda con problemas de matemáticas';

  @override
  String get quickGuideHelpContent =>
      'Guía Rápida es su asistente de estudio con IA. Puede:\n\n• Hacer preguntas sobre cualquier materia\n• Solicitar explicaciones de conceptos\n• Obtener ayuda con problemas de práctica\n\n¡Solo escriba su pregunta y presione enviar!';

  @override
  String semanticsYouSaid(String message) {
    return 'Usted dijo: $message';
  }

  @override
  String semanticsQuickGuideSaid(String message) {
    return 'Guía Rápida dijo: $message';
  }

  @override
  String semanticsSendPrompt(String prompt) {
    return 'Enviar sugerencia: $prompt';
  }

  @override
  String get semanticsMessageInput => 'Campo de mensaje para Guía Rápida';

  @override
  String get fallbackExplainResponse =>
      '¡Claro! Puedo ayudar a explicar conceptos. ¿Qué tema le gustaría que explique?';

  @override
  String get fallbackQuizResponse =>
      '¡Puedo ayudar con preguntas! Pregunte lo que quiera y haré lo mejor posible.';

  @override
  String get fallbackMathResponse =>
      '¡Estaré encantado de ayudar con matemáticas! ¿Qué problema o tema específico le gustaría trabajar?';

  @override
  String get fallbackGeneralResponse =>
      '¡Esa es una pregunta interesante! Déjeme ayudarle a entenderla mejor.';

  @override
  String get quickGuideSystemPrompt =>
      'Es la Guía Rápida de StudyKing, un asistente de estudio de IA útil. Proporciona respuestas concisas y educativas. Ayuda con explicaciones, preguntas de examen y problemas matemáticos. Responde en español de manera conversacional.';

  @override
  String get mentorSystemPrompt =>
      'Eres un mentor de IA conocedor y alentador para un estudiante. Tu función es guiar su viaje de aprendizaje, proporcionar motivación y ayudarlos a desarrollar hábitos de estudio efectivos. Mantén las respuestas concisas, solidarias y procesables.';

  @override
  String get mentorSystemPromptScheduling =>
      'IMPORTANTE: Cuando el estudiante pregunte sobre programar lecciones, crear planes o reprogramar, tu respuesta debe reconocer la solicitud e indicar que presentarás una propuesta de confirmación. No digas ni impliques que la programación o el cambio de plan se ha comprometido o completado. Usa lenguaje condicional como \"Puedo ayudarte con eso\", \"Déjame verificar la disponibilidad\" o \"Prepararé una propuesta para que la confirmes\". Después de tu respuesta, el sistema presentará un diálogo de confirmación al estudiante antes de aplicar cualquier cambio.';

  @override
  String get aboutApplicationName => 'StudyKing';

  @override
  String get aboutVersion => 'v1.0.0';

  @override
  String get aboutLegalese => '© 2026 StudyKing.';

  @override
  String get activeLessonTimer =>
      'Tiene un temporizador de lección activo. ¿Salir de todas formas?';

  @override
  String get unknownModelId => 'unknown-model';

  @override
  String get unknownProviderName => 'Desconocido';

  @override
  String get examDateOptionalLabel => 'Fecha de Examen (Opcional):';

  @override
  String get lessonFallbackTitle => 'Lección';

  @override
  String lessonFallbackContent(String topicTitle) {
    return 'Estudia los conceptos clave de $topicTitle. Concéntrate en entender los principios fundamentales.';
  }

  @override
  String get lessonPlanFallbackTitle => 'Plan de lección para esta sesión';

  @override
  String errorWithMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get questionTypeDefault => 'Pregunta';

  @override
  String get durationSeparator => ' ';

  @override
  String get accessibility => 'Accesibilidad';

  @override
  String get highContrastMode => 'Modo de Alto Contraste';

  @override
  String get highContrastDescription =>
      'Aumente el contraste para mejor visibilidad';

  @override
  String get largeTouchTargets => 'Objetivos Táctiles Grandes';

  @override
  String get largeTouchTargetsDescription =>
      'Aumente el tamaño de los objetivos táctiles';

  @override
  String get reduceMotion => 'Reducir movimiento';

  @override
  String get reduceMotionDescription =>
      'Reducir o desactivar animaciones de movimiento';

  @override
  String get errorNetworkConnection =>
      'No se puede conectar al servidor. Verifique su conexión a internet e intente de nuevo.';

  @override
  String get errorApiKeyMissing =>
      'Se requiere una clave API. Configúrela en Ajustes.';

  @override
  String get errorInvalidApiKey =>
      'Clave API no válida. Verifique sus credenciales en Ajustes.';

  @override
  String get errorApiRateLimit =>
      'Demasiadas solicitudes. Espere un momento e intente de nuevo.';

  @override
  String get errorApiNotFound => 'El recurso solicitado no fue encontrado.';

  @override
  String get errorApiInternalServer =>
      'El servidor encontró un error. Intente de nuevo más tarde.';

  @override
  String get errorDatabase =>
      'Ocurrió un error de base de datos. Intente de nuevo.';

  @override
  String get errorPdfParse =>
      'No se puede analizar el archivo PDF. Asegúrese de que sea un PDF válido.';

  @override
  String get errorContentGeneration =>
      'Error al generar contenido. Intente de nuevo.';

  @override
  String get errorLlmUnavailable =>
      'El servicio de IA no está disponible temporalmente. Intente de nuevo.';

  @override
  String get errorApiAuth =>
      'Error de autenticación. Verifique sus credenciales de API.';

  @override
  String get errorUnexpected =>
      'Ocurrió un error inesperado. Intente de nuevo.';

  @override
  String get retryConnection => 'Reintentar Conexión';

  @override
  String get retryAfterWait => 'Reintentar Después';

  @override
  String get weeklyActivity => 'Actividad Semanal';

  @override
  String get topicsLabel => 'Temas';

  @override
  String get readiness => 'Preparación';

  @override
  String get confidence => 'Confianza';

  @override
  String get forgettingRisk => 'Riesgo de Olvido';

  @override
  String get reviewUrgency => 'Urgencia de Repaso';

  @override
  String get lastAttempted => 'Último Intento';

  @override
  String get lastUpdated => 'Última Actualización';

  @override
  String get accuracyTrend => 'Tendencia de Precisión';

  @override
  String get loadingSyllabusProgress =>
      'Cargando progreso del plan de estudios...';

  @override
  String pageIndicatorAria(int count, int total) {
    return 'Página $count de $total';
  }

  @override
  String get overallMastery => 'Dominio General';

  @override
  String get avgTime => 'Tiempo Prom.';

  @override
  String get badges => 'Insignias';

  @override
  String get sessionHistoryExport => 'Historial de Sesiones';

  @override
  String get progressExportedCsv => 'Progreso exportado a CSV';

  @override
  String get sessionHistoryExportedCsv =>
      'Historial de sesiones exportado a CSV';

  @override
  String get exportPdf => 'Exportar PDF';

  @override
  String get sessionHistoryExportedPdf =>
      'Historial de sesiones exportado a PDF';

  @override
  String get sessionHistoryExportedJson =>
      'Historial de sesiones exportado a JSON';

  @override
  String get labelJson => 'JSON';

  @override
  String get unsavedChanges => 'Cambios sin guardar';

  @override
  String get unsavedChangesDescription =>
      'Tiene cambios sin guardar. ¿Está seguro de que quiere descartarlos?';

  @override
  String get discard => 'Descartar';

  @override
  String get goToSettings => 'Ir a Configuración';

  @override
  String get failedToLoadLesson =>
      'Error al cargar la lección. Verifica tu conexión e intenta de nuevo.';

  @override
  String get failedToStartPractice => 'Error al iniciar la sesión de práctica';

  @override
  String get aiTutor => 'Tutor IA';

  @override
  String get interactiveConversationalLessons =>
      'Lecciones conversacionales interactivas';

  @override
  String get personalStudyAssistantPlanner =>
      'Asistente personal de estudio y planificador';

  @override
  String get chooseStudyMode => 'Elija un modo de estudio';

  @override
  String get clearConversation => 'Borrar conversación';

  @override
  String get senderYou => 'Usted';

  @override
  String get senderTutor => 'Tutor';

  @override
  String get senderSystem => 'Sistema';

  @override
  String remainingMinLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min restantes',
      one: '1 min restante',
    );
    return '$_temp0';
  }

  @override
  String correctCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count correctas',
      one: '1 correcta',
    );
    return '$_temp0';
  }

  @override
  String get mentorWelcomeBody =>
      'Puedo ayudar con:\n• Programar y reprogramar lecciones\n• Revisar su progreso de estudio\n• Planificar objetivos de estudio a largo plazo\n• Motivación y ánimo\n• Decidir qué estudiar a continuación\n\n¿Cómo puedo ayudarle hoy?';

  @override
  String readyToLearnAbout(String topic) {
    return 'Estoy listo para aprender sobre $topic. ¡Enséñeme!';
  }

  @override
  String scheduledLessonGreeting(String topic) {
    return 'Bienvenido a mi lección programada sobre $topic. ¡Estoy listo para aprender!';
  }

  @override
  String get scheduledLessonSystemContext =>
      'Nota: Este estudiante ha programado esta sesión de lección con antelación. La sesión tiene una duración fija establecida en su plan de estudio. Reconoce adecuadamente la naturaleza programada y respeta el límite de tiempo.';

  @override
  String correctCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count correctas',
      one: '1 correcta',
    );
    return '$_temp0';
  }

  @override
  String paceLabel(int pace) {
    return '$pace % ritmo';
  }

  @override
  String get errorWithResponse =>
      'Lo siento, encontré un error. Intente de nuevo.';

  @override
  String get mentorRejectionResponse =>
      '¡No hay problema! No haré ningún cambio. Avíseme si necesita algo más.';

  @override
  String get mentorNoLessonsScheduled =>
      'Aún no tiene lecciones programadas. ¿Le gustaría que le ayude a crear un plan de estudio? Puedo ayudarle a establecer sesiones de estudio regulares para sus materias.';

  @override
  String get mentorUpcomingLessonsHeader =>
      'Aquí están sus próximas lecciones:\n';

  @override
  String mentorLessonEntry(String topic, String date, int duration) {
    return '• $topic el $date ($duration min)\n';
  }

  @override
  String get mentorReschedulePrompt =>
      '\n¿Le gustaría reprogramar alguna de estas?';

  @override
  String mentorRecentSessionOnDate(String date) {
    return 'Su sesión de estudio más reciente fue el $date. ¿Le gustaría programar una nueva lección?';
  }

  @override
  String get mentorNotStarted =>
      'Parece que aún no ha empezado. ¿Le gustaría que le ayude a programar su primera lección?';

  @override
  String get mentorScheduleError =>
      'Tuve problemas al consultar su horario. Inténtelo de nuevo más tarde.';

  @override
  String get mentorProgressError =>
      'Tuve problemas al generar su informe de progreso. Inténtelo de nuevo más tarde.';

  @override
  String get mentorNotStartedStudying =>
      '¡Aún no ha empezado a estudiar! ¿Le gustaría que le ayude a crear un plan de estudio para empezar?';

  @override
  String get mentorToday => 'hoy';

  @override
  String mentorDaysAgo(int daysCount) {
    String _temp0 = intl.Intl.pluralLogic(
      daysCount,
      locale: localeName,
      other: 'hace $daysCount días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String mentorInactiveDays(int daysCount) {
    return 'Noté que no ha estudiado en $daysCount días. ¿Le gustaría programar una sesión de estudio para retomar el ritmo? ¡La constancia es clave para progresar!';
  }

  @override
  String mentorGreatJobStayingActive(String daysAgo) {
    return '¡Buen trabajo manteniéndose activo! Su última sesión de estudio fue $daysAgo. ¡Siga así!';
  }

  @override
  String get mentorWelcomeStart =>
      '¡Bienvenido! Comencemos con sus estudios. ¿Le gustaría programar una lección?';

  @override
  String get mentorActivityCheckError =>
      'Tuve problemas al verificar su actividad. ¿Cómo puedo ayudarle hoy?';

  @override
  String mentorRescheduledConfirmation(String topic) {
    return 'He notado el cambio. Su lección \"$topic\" ha sido reprogramada. ¿Hay algo más en lo que pueda ayudar?';
  }

  @override
  String get mentorNewSessionAdded =>
      '¡Genial! He agregado una nueva sesión de estudio a su horario. Puede revisar los detalles en su planificador.';

  @override
  String get mentorChangesDone =>
      '¡Listo! Los cambios se han realizado en su horario.';

  @override
  String get mentorAccuracy => 'Exactitud';

  @override
  String get mentorBadges => 'Insignias';

  @override
  String get mentorRecommendationsSection => 'Recomendaciones';

  @override
  String get mentorProgressReportTitle =>
      '📊 **Su Informe de Progreso de Estudio**\n';

  @override
  String mentorOverallAccuracy(String accuracy, String correct, String total) {
    return '**Precisión General:** $accuracy% ($correct/$total correctas)';
  }

  @override
  String mentorTotalStudyTime(String hours) {
    return '**Tiempo Total de Estudio:** $hours horas';
  }

  @override
  String mentorWeeklyActivity(String attempts) {
    return '**Actividad Semanal:** $attempts intentos';
  }

  @override
  String mentorCompletedLessons(String count) {
    return '**Lecciones Completadas:** $count';
  }

  @override
  String mentorTopicsStudied(String count) {
    return '**Temas Estudiados:** $count';
  }

  @override
  String get mentorAreasNeedingAttention =>
      '\n**Áreas que necesitan atención:**';

  @override
  String mentorTopicAccuracyEntry(String topic, int accuracy) {
    return '• $topic (precisión: $accuracy%)';
  }

  @override
  String get mentorBadgesEarned => '\n**Insignias obtenidas:**';

  @override
  String mentorBadgeEntry(String name, String description) {
    return '• $name: $description';
  }

  @override
  String get mentorRecommendations => '\n**Recomendaciones:**';

  @override
  String mentorRecommendationEntry(String message) {
    return '• $message';
  }

  @override
  String get mentorProgressReportError =>
      'No se pudo generar el informe de progreso. Inténtelo de nuevo más tarde.';

  @override
  String get mentorApiKeyMissing => 'Servicio de IA no configurado.';

  @override
  String get mentorNoSubjects =>
      'Aún no ha añadido ninguna materia. ¿Le gustaría ayuda para configurar su primera materia?';

  @override
  String get mentorDoingWell =>
      '¡Lo está haciendo bien! ¿Le gustaría revisar su progreso, programar una nueva lección o practicar algunas preguntas?';

  @override
  String get roadmaps => 'Rutas de aprendizaje';

  @override
  String get createRoadmap => 'Crear Roadmap';

  @override
  String get roadmapGoal => 'Meta de Aprendizaje';

  @override
  String get roadmapGoalHint => 'p. ej., Quiero aprender Física IB en 180 días';

  @override
  String get generateRoadmap => 'Generar Roadmap';

  @override
  String get myRoadmaps => 'Mis Roadmaps';

  @override
  String get milestones => 'Hitos';

  @override
  String get milestone => 'Hito';

  @override
  String milestoneShort(int order) {
    return 'H$order';
  }

  @override
  String get targetCompletion => 'Finalización Prevista';

  @override
  String get noRoadmapsYet => 'Aún no hay roadmaps';

  @override
  String get timeline => 'Cronología';

  @override
  String completionOfValue(String value) {
    return '$value Completo';
  }

  @override
  String milestoneOfWithDeadline(String title, String deadline) {
    return '$title - Vence $deadline';
  }

  @override
  String get enableNotifications => 'Habilitar Notificaciones';

  @override
  String get notificationPreferences => 'Preferencias de Notificaciones';

  @override
  String get dailyReminders => 'Recordatorios Diarios';

  @override
  String get revisionReminders => 'Recordatorios de Revisión';

  @override
  String get overworkAlerts => 'Alertas de Sobrecarga';

  @override
  String get planAdjustmentNotifications => 'Alertas de Ajuste de Plan';

  @override
  String get quietHours => 'Horas de Silencio';

  @override
  String get quietHoursStart => 'Inicio Horas de Silencio';

  @override
  String get quietHoursEnd => 'Fin Horas de Silencio';

  @override
  String get exportComprehensiveReport => 'Exportar Informe Completo';

  @override
  String get comprehensiveCsv => 'CSV Completo';

  @override
  String get comprehensivePdf => 'PDF Completo';

  @override
  String get comprehensiveJson => 'JSON Completo';

  @override
  String get comprehensiveReportExported => 'Informe completo exportado';

  @override
  String get exportCsvDetail =>
      'CSV: estadísticas generales, dominio de temas, todos los intentos (uno por fila), tendencia semanal, insignias.';

  @override
  String get exportPdfDetail =>
      'PDF: informe formateado con tablas, gráficos y desgloses de dominio adecuados para impresión.';

  @override
  String get exportJsonDetail =>
      'JSON: exportación de datos estructurados para análisis programático.';

  @override
  String get exportProgressCsvDetail =>
      'CSV de estadísticas: resumen de estadísticas y visión general del progreso (más ligero que el CSV completo).';

  @override
  String get exportInstrumentationDetail =>
      'Analíticas de Progreso: métricas de adherencia al plan y mejora de dominio para análisis.';

  @override
  String get backupRestoreHint =>
      'Para una copia de seguridad completa (materias, preguntas, configuraciones), vaya a Configuración → Copia de seguridad y Restauración.';

  @override
  String get activeRoadmaps => 'Roadmaps Activos';

  @override
  String get completedRoadmaps => 'Roadmaps Completados';

  @override
  String get progressBySubject => 'Progreso por Materia';

  @override
  String weekNumber(int number) {
    return 'Semana $number';
  }

  @override
  String milestoneForWeek(int number) {
    return 'Hito de la semana $number';
  }

  @override
  String get markschemeUnavailable =>
      'No hay esquema de calificación disponible';

  @override
  String get answerTooShort =>
      'La respuesta es demasiado corta. Proporcione más detalles.';

  @override
  String get goodResponseLength => 'Buena longitud de respuesta.';

  @override
  String get answerTooShortForCredit =>
      'Respuesta demasiado corta para crédito completo.';

  @override
  String get noDrawingDetected =>
      'No se detectó dibujo. Por favor, dibuje algo.';

  @override
  String get invalidDrawingData =>
      'Datos de dibujo inválidos. Por favor, vuelva a dibujar.';

  @override
  String get allStepsIdentified => 'Todos los pasos requeridos identificados.';

  @override
  String get specialHandlingRequired =>
      'Este tipo de pregunta requiere manejo especial.';

  @override
  String get someAnswersIncorrect => 'Algunas respuestas son incorrectas';

  @override
  String correctAnswerIs(String answer) {
    return 'La respuesta correcta es: $answer';
  }

  @override
  String allStepsFormat(int count) {
    return '¡Los $count pasos se han identificado correctamente!';
  }

  @override
  String partialStepsFormat(int matched, int total, String missing) {
    return 'Identificó $matched de $total pasos. Faltan: $missing';
  }

  @override
  String noStepsFormat(String steps) {
    return 'No se encontraron pasos requeridos en su respuesta. Pasos clave a incluir: $steps';
  }

  @override
  String get allRequiredStepsMissing => 'Faltan algunos pasos requeridos';

  @override
  String get focusMode => 'Estudio';

  @override
  String get newFocusSession => 'Nueva Sesión de Enfoque';

  @override
  String get refreshStats => 'Actualizar estadísticas';

  @override
  String errorStartingSession(String error) {
    return 'Error al iniciar sesión: $error';
  }

  @override
  String get dailyLimitReached => 'Límite Diario Alcanzado';

  @override
  String get dailyLimitReachedBody =>
      'Ha alcanzado su límite diario de estudio. ¡Bien hecho! Descanse y vuelva mañana.';

  @override
  String get breakTime => '¡Descanso!';

  @override
  String sessionCompleted(int minutes) {
    return 'Sesión completada: ${minutes}m';
  }

  @override
  String get focus => 'Estudio';

  @override
  String focusForMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Enfóquese por $minutes minutos',
      one: 'Enfóquese por 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String get focusTime => 'Tiempo de Enfoque';

  @override
  String get timerRemaining => 'restante';

  @override
  String get timerPaused => 'PAUSADO';

  @override
  String get title => 'Título';

  @override
  String get timerDone => '¡TERMINADO!';

  @override
  String get resume => 'Reanudar';

  @override
  String get pause => 'Pausar';

  @override
  String get markComplete => 'Marcar como Completado';

  @override
  String get csvOverallStats => 'ESTADÍSTICAS GENERALES';

  @override
  String get csvTopicMastery => 'DOMINIO DE TEMAS';

  @override
  String get csvAllAttempts => 'TODOS LOS INTENTOS';

  @override
  String get csvWeeklyTrend => 'TENDENCIA SEMANAL';

  @override
  String get csvBadges => 'INSIGNIAS';

  @override
  String get csvColTotalAttempts => 'Intentos Totales';

  @override
  String get csvColCorrect => 'Correctas';

  @override
  String get csvColAccuracy => 'Precisión (%)';

  @override
  String get csvColAvgTime => 'Tiempo Prom. (s)';

  @override
  String get csvColTotalHours => 'Horas Totales';

  @override
  String get csvColWeeklyActivity => 'Actividad Semanal';

  @override
  String get csvColDailyActivity => 'Actividad Diaria';

  @override
  String get csvColTopicsStudied => 'Temas Estudiados';

  @override
  String get csvColTopicId => 'ID del Tema';

  @override
  String get csvColMasteryLevel => 'Nivel de Dominio';

  @override
  String get csvColLastPracticed => 'Última Práctica';

  @override
  String get csvColReviewUrgency => 'Urgencia de Revisión';

  @override
  String get csvColQuestionId => 'ID de Pregunta';

  @override
  String get csvColSubjectId => 'ID de Materia';

  @override
  String get csvColTime => 'Tiempo (s)';

  @override
  String get csvColTimestamp => 'Marca de Tiempo';

  @override
  String get csvColWeek => 'Semana';

  @override
  String get csvColAttempts => 'Intentos';

  @override
  String get csvColImprovement => 'Mejora';

  @override
  String get csvColBadgeName => 'Nombre de Insignia';

  @override
  String get csvColBadgeDescription => 'Descripción';

  @override
  String get csvColDateUnlocked => 'Fecha de Desbloqueo';

  @override
  String get pdfProgressReport => 'Informe de Progreso StudyKing';

  @override
  String pdfGenerated(String date) {
    return 'Generado: $date';
  }

  @override
  String pdfStudentId(String id) {
    return 'ID de Estudiante: $id';
  }

  @override
  String get pdfOverallStatistics => 'Estadísticas Generales';

  @override
  String get pdfMetric => 'Métrica';

  @override
  String get pdfValue => 'Valor';

  @override
  String get pdfTopicMasteryBreakdown => 'Desglose de Dominio de Temas';

  @override
  String get pdfTableAttempts => 'Intentos';

  @override
  String get pdfTableLevel => 'Nivel';

  @override
  String get pdfTableTopic => 'Tema';

  @override
  String get pdfBadgesEarned => 'Insignias Obtenidas';

  @override
  String get pdfRecentActivitySummary => 'Resumen de Actividad Reciente';

  @override
  String get pdfNoMasteryData => 'Aún no hay datos de dominio.';

  @override
  String get pdfNoBadges => 'Aún no hay insignias. ¡Sigue estudiando!';

  @override
  String pdfTotalAttemptsRecorded(int count) {
    return 'Intentos totales registrados: $count';
  }

  @override
  String pdfDateRange(String start, String end) {
    return 'Rango de fechas: $start a $end';
  }

  @override
  String pdfCorrectFraction(int correct, int total) {
    return 'Correctas: $correct/$total';
  }

  @override
  String get gettingStarted => 'Primeros Pasos';

  @override
  String get gettingStartedDesc =>
      'Complete estos pasos para aprovechar al máximo StudyKing';

  @override
  String get addSubjectDesc =>
      'Cree su primera materia para organizar su material de estudio';

  @override
  String get uploadMaterial => 'Subir Material de Estudio';

  @override
  String get uploadAndAnalyze => 'Subir y Analizar';

  @override
  String get uploadMaterialDesc =>
      'Suba PDFs, notas y bancos de preguntas para comenzar';

  @override
  String get takePracticeQuiz => 'Realice su Primer Cuestionario de Práctica';

  @override
  String get takePracticeQuizDesc =>
      'Ponga a prueba sus conocimientos con preguntas de práctica adaptativas';

  @override
  String get scheduleAiTutor => 'Programe una Sesión con el Tutor de IA';

  @override
  String get scheduleAiTutorDesc =>
      'Reciba tutoría personalizada uno a uno con IA';

  @override
  String get nextStep => 'Siguiente Paso';

  @override
  String topicsAutoCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count temas auto-creados del plan de estudios',
      one: '1 tema auto-creado del plan de estudios',
    );
    return '$_temp0';
  }

  @override
  String get fileSaved => 'Archivo guardado exitosamente';

  @override
  String get fileShared => 'Archivo compartido exitosamente';

  @override
  String get noBadgesYet => 'Aún no hay logros. ¡Sigue estudiando!';

  @override
  String get noOptionsAvailable => 'No hay opciones disponibles';

  @override
  String get subjectProgress => 'Progreso de la Materia';

  @override
  String get pendingActions => 'Acciones Pendientes';

  @override
  String get scheduledLessons => 'Lecciones Programadas';

  @override
  String get regeneratePlan => 'Regenerar Plan';

  @override
  String get viewAllLessons => 'Ver Todas las Lecciones';

  @override
  String get change => 'Cambiar';

  @override
  String get scheduling => 'Programando...';

  @override
  String get accept => 'Aceptar';

  @override
  String get scheduleALesson => 'Programar una lección';

  @override
  String get rescheduleLesson => 'Reprogramar lección';

  @override
  String get planAdjustmentTitle => 'Ajuste de plan sugerido';

  @override
  String get actionNeeded => 'Acción necesaria';

  @override
  String get somethingWentWrong => 'Algo salió mal';

  @override
  String get openPlanner => 'Abrir Planificador';

  @override
  String get studyPlanOverview => 'Resumen del Plan de Estudio';

  @override
  String moreLessonsCount(int count) {
    return '$count más...';
  }

  @override
  String get badgeFirstStepName => 'Primer Paso';

  @override
  String get badgeFirstStepDesc => '¡Respondió su primera pregunta!';

  @override
  String get badgeAccuracyGoldName => 'Precisión de Oro';

  @override
  String get badgeAccuracyGoldDesc => '¡Alcanzó más del 90% de precisión!';

  @override
  String get badgeDailyScholarName => 'Estudioso Diario';

  @override
  String get badgeDailyScholarDesc => '¡Estudió de manera constante hoy!';

  @override
  String get badgeDedicatedLearnerName => 'Aprendiz Dedicado';

  @override
  String get badgeDedicatedLearnerDesc => '¡Estudió más de 10 horas en total!';

  @override
  String get badgeWeeklyWarriorName => 'Guerrero Semanal';

  @override
  String get badgeWeeklyWarriorDesc => '¡Activo durante una semana completa!';

  @override
  String get notifChannelGeneral => 'Notificaciones de StudyKing';

  @override
  String get notifChannelGeneralDesc => 'Notificaciones generales de StudyKing';

  @override
  String get notifChannelRevision => 'Recordatorios de Revisión';

  @override
  String get notifChannelWellbeing => 'Alertas de Bienestar';

  @override
  String get notifChannelPlanning => 'Sugerencias de Planificación';

  @override
  String get notifChannelLessons => 'Notificaciones de Lecciones';

  @override
  String get notifChannelMastery => 'Alertas de Dominio';

  @override
  String get notifChannelBadges => 'Notificaciones de Insignias';

  @override
  String get notifChannelDailyReminder => 'Recordatorios de Estudio Diarios';

  @override
  String get notifChannelDailyReminderDesc =>
      'Recordatorios diarios para estudiar';

  @override
  String get notifTitleTimeToReview => '¡Hora de Repasar!';

  @override
  String get notifTitleTakeBreak => 'Tome un Descanso';

  @override
  String notifBodyOverwork(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours horas',
      one: '1 hora',
    );
    return 'Ha estudiado $_temp0 hoy. ¡Recuerde descansar!';
  }

  @override
  String get notifTitlePlanAdjustment => 'Ajuste de Plan';

  @override
  String notifBodyPlanAdjustment(int days) {
    return 'Ha tenido $days días de bajo cumplimiento. ¿Ajustamos su plan?';
  }

  @override
  String get notifTitleUpcomingLesson => 'Próxima Lección';

  @override
  String get notifTitleTopicsNeedAttention => 'Temas que Requieren Atención';

  @override
  String notifBodyLowMastery(String topics) {
    return 'Bajo dominio detectado en: $topics';
  }

  @override
  String get notifTitleBadgeUnlocked => '¡Insignia Desbloqueada!';

  @override
  String get recommendAccuracyBelow60 =>
      'Su precisión general está por debajo del 60%. Concéntrese en repasar conceptos fundamentales.';

  @override
  String get recommendReviewBasics => 'Repase temas básicos antes de avanzar';

  @override
  String get recommendAccuracyExcellent =>
      '¡Excelente progreso! Listo para temas avanzados.';

  @override
  String get recommendChallengingQuestions =>
      'Intente preguntas de práctica desafiantes';

  @override
  String get recommendConsistency =>
      'Estudió menos de 1 hora en total. ¡La constancia es clave!';

  @override
  String get recommendSetDailyGoal =>
      'Establezca una meta diaria de 30 minutos';

  @override
  String get recommendNoActivity =>
      'Sin actividad de estudio esta semana. ¡Retome el ritmo!';

  @override
  String get recommendQuickReview =>
      'Comience con una sesión de repaso rápido de 15 minutos';

  @override
  String recommendWeakTopics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Tiene $count temas que necesitan mejorar. Concéntrese en fortalecer estas áreas.',
      one:
          'Tiene 1 tema que necesita mejorar. Concéntrese en fortalecer esta área.',
    );
    return '$_temp0';
  }

  @override
  String get recommendAiTutor => 'Repase temas débiles con el tutor IA';

  @override
  String nudgeOverwork(String hours) {
    return 'Ha estudiado $hours horas hoy. ¡Considere tomar un descanso!';
  }

  @override
  String nudgeRevision(int days, String topic) {
    return 'Han pasado $days días desde que practicó \"$topic\". ¡Hora de repasar!';
  }

  @override
  String nudgePlanAdjustment(int days) {
    return 'Ha tenido $days días de bajo cumplimiento del plan. ¿Desea ajustar su plan de estudio?';
  }

  @override
  String get planReasonRequiredDependent => 'Requerido para temas dependientes';

  @override
  String get planReasonWeakPerformance => 'Rendimiento bajo';

  @override
  String get planReasonHighForgettingRisk => 'Alto riesgo de olvido';

  @override
  String get planReasonNewSyllabusTopic => 'Nuevo tema del plan de estudios';

  @override
  String get planReasonPartOfGoal => 'Parte del objetivo del plan de estudios';

  @override
  String get planFocusGeneralReview => 'Repaso general';

  @override
  String get planFocusWeakAreas => 'Enfoque en áreas por mejorar';

  @override
  String get planFocusPracticeReview => 'Práctica y repaso';

  @override
  String get planFocusRestAndReview => 'Descanso y repaso';

  @override
  String get adapSuggestionFundamentals => 'Repase conceptos básicos primero';

  @override
  String get adapSuggestionMorePractice =>
      'Se recomiendan más preguntas de práctica';

  @override
  String get adapSuggestionAdvancedTopics => 'Listo para temas avanzados';

  @override
  String get badgeCenturyClubName => 'Club del Centenario';

  @override
  String get badgeCenturyClubDesc => '¡Respondió más de 100 preguntas!';

  @override
  String nudgeWeeklyDigest(
    int weeklyActivity,
    int accuracy,
    String totalHours,
    int weakCount,
    int badgeCount,
  ) {
    return 'Resumen semanal: $weeklyActivity preguntas respondidas, $accuracy% precisión, $totalHours horas estudiadas, $weakCount áreas por mejorar, $badgeCount insignias obtenidas.';
  }

  @override
  String notificationTimeToReviewBody(int days, String topic) {
    return 'Han pasado $days días desde que practicó \"$topic\".';
  }

  @override
  String notificationUpcomingLessonBody(String lesson, String time) {
    return 'Su lección \"$lesson\" comienza a las $time';
  }

  @override
  String notificationBadgeUnlockedBody(String badge, String description) {
    return 'Obtuvo la insignia \"$badge\": $description';
  }

  @override
  String get notifChannelRevisionDesc =>
      'Recordatorios para repasar temas que necesitan práctica';

  @override
  String get notifChannelWellbeingDesc =>
      'Alertas sobre equilibrio estudio-vida y sobrecarga';

  @override
  String get notifChannelPlanningDesc =>
      'Sugerencias sobre ajustes al plan de estudio';

  @override
  String get notifChannelLessonsDesc =>
      'Notificaciones sobre próximas lecciones';

  @override
  String get notifChannelMasteryDesc =>
      'Alertas sobre bajo dominio de temas y áreas por mejorar';

  @override
  String get notifChannelBadgesDesc =>
      'Notificaciones sobre insignias y logros obtenidos';

  @override
  String get notifChannelMentor => 'Mensajes del Mentor';

  @override
  String get notifChannelMentorDesc =>
      'Registros y sugerencias proactivas del mentor';

  @override
  String lessonReadyBody(String topicTitle) {
    return '$topicTitle tiene una lección lista';
  }

  @override
  String get planAccuracyLow =>
      'La precisión está por debajo del 60% — necesita práctica enfocada';

  @override
  String get planReviewOverdue =>
      'El repaso está vencido — el riesgo de olvido es alto';

  @override
  String get planStreakLow => 'La racha es baja — se necesita constancia';

  @override
  String get planPrerequisite =>
      'Requisito previo para temas próximos — debe dominarlo primero';

  @override
  String planBlocksDownstream(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bloquea $count temas dependientes',
      one: 'Bloquea 1 tema dependiente',
    );
    return '$_temp0';
  }

  @override
  String get planRequiredForDependent => 'Requerido para temas dependientes';

  @override
  String get planWeakPerformance => 'Rendimiento débil';

  @override
  String get planHighForgettingRisk => 'Alto riesgo de olvido';

  @override
  String get planNewSyllabusTopic => 'Nuevo tema del temario';

  @override
  String get planPartOfSyllabusGoal => 'Parte del objetivo del temario';

  @override
  String get planHighMastery => 'Alto dominio — listo para avanzar';

  @override
  String get planGoodProgress => 'Buen progreso — mantenga la constancia';

  @override
  String get planDeveloping => 'En desarrollo — necesita más práctica';

  @override
  String get planAtRisk => 'En riesgo — repaso vencido';

  @override
  String get planNeedsAttention => 'Necesita atención — enfoque en fundamentos';

  @override
  String get planRestAndReview => 'Descanso y repaso';

  @override
  String get planGeneralReview => 'Repaso general';

  @override
  String get planPracticeAndReview => 'Práctica y repaso';

  @override
  String adherenceLowDaysAdjust(int days) {
    return 'Ha tenido $days días consecutivos de bajo cumplimiento. Considere ajustar su plan de estudio o consultar con su mentor.';
  }

  @override
  String adherenceLowDaysRegenerate(int days) {
    return 'Ha tenido $days días consecutivos de bajo cumplimiento. ¿Le gustaría regenerar su plan con objetivos ajustados?';
  }

  @override
  String get shareSessionsText => 'Sesiones de Estudio';

  @override
  String get summary => 'Resumen';

  @override
  String get noLimit => 'Sin límite';

  @override
  String get focusTimerDescription => 'Inicie una sesión de estudio enfocada';

  @override
  String get dailyStudyCap => 'Límite Diario de Estudio';

  @override
  String get tokenUsageSummary => 'Resumen de Uso de Tokens';

  @override
  String get totalTokens => 'Tokens Totales';

  @override
  String get totalCost => 'Costo Total';

  @override
  String get failed => 'Fallidas';

  @override
  String get llmStatusQueued => 'En cola';

  @override
  String get llmStatusCancelled => 'Cancelada';

  @override
  String get subjectIdHint => 'p. ej. sub_física';

  @override
  String adherenceLowToday(int actualMinutes, int plannedMinutes) {
    return 'Ha estudiado $actualMinutes min hoy frente a los $plannedMinutes min planificados. Considere redistribuir la carga restante.';
  }

  @override
  String adherencePartialToday(int actualMinutes, int plannedMinutes) {
    return 'Ha estudiado $actualMinutes min hoy frente a los $plannedMinutes min planificados. Intente ponerse al día con los temas restantes.';
  }

  @override
  String adherenceExceededToday(int actualMinutes, int plannedMinutes) {
    return '¡Buen trabajo! Ha estudiado $actualMinutes min frente a los $plannedMinutes min planificados.';
  }

  @override
  String overtimeLabel(int minutes) {
    return '+${minutes}m';
  }

  @override
  String get correctAnswerKeywords =>
      'correcto,bien,sí,entiendo,comprendo,cierto,exactamente,así es';

  @override
  String get incorrectAnswerKeywords =>
      'incorrecto,mal,no estoy seguro,confundido,no sé,no entiendo,no comprendo,error,equivocado';

  @override
  String get exerciseKeywords =>
      'ejercicio,práctica,pregunta,examen,problema,prueba,reto,ejemplo';

  @override
  String get timeConflict => 'Conflicto de horario con una lección programada';

  @override
  String get planGeneratedSuccessfully => 'Plan generado exitosamente';

  @override
  String get syllabusPlanGenerated =>
      'Plan basado en el programa generado exitosamente';

  @override
  String get failedToGenerateSyllabusPlan =>
      'Error al generar el plan basado en el programa';

  @override
  String get failedToCreateRoadmap => 'Error al crear la hoja de ruta';

  @override
  String get failedToUpdateMilestone => 'Error al actualizar el hito';

  @override
  String roadmapCreated(String goal) {
    return '¡Hoja de ruta \"$goal\" creada!';
  }

  @override
  String get roadmapDeleted => 'Hoja de ruta eliminada';

  @override
  String get roadmapDeleteConfirm => '¿Eliminar esta hoja de ruta?';

  @override
  String get roadmapUpdated => 'Hoja de ruta actualizada';

  @override
  String get milestoneUpdated => 'Hito actualizado';

  @override
  String get enterValidNumber => 'Ingrese un número válido';

  @override
  String get actionAccepted => 'Acción aceptada';

  @override
  String get failedToExecuteAction =>
      'Error al ejecutar la acción — faltan parámetros';

  @override
  String get failedToAcceptAction => 'Error al aceptar la acción';

  @override
  String get failedToDismissAction => 'Error al descartar la acción';

  @override
  String get lessonScheduled => 'Lección programada';

  @override
  String get failedToScheduleLesson => 'Error al programar la lección';

  @override
  String get planRegeneratedFromAdherence =>
      'Plan regenerado según tu cumplimiento';

  @override
  String get failedToRegeneratePlan => 'Error al regenerar el plan';

  @override
  String get missedWorkloadRedistributed =>
      'Trabajo pendiente redistribuido en los próximos 3 días';

  @override
  String get failedToRedistributeWorkload =>
      'Error al redistribuir el trabajo pendiente';

  @override
  String get planAdjusted => 'Ritmo de estudio ajustado exitosamente';

  @override
  String get failedToAdjustPlan => 'Error al ajustar el ritmo de estudio';

  @override
  String get progressOverview => 'Resumen de Progreso';

  @override
  String get todaysProgress => 'Progreso de Hoy';

  @override
  String get weekly => 'Semanal';

  @override
  String get actual => 'Real';

  @override
  String get planned => 'Planificado';

  @override
  String get noStudyPlanYet => 'Aún no hay plan de estudio';

  @override
  String get calendar => 'Calendario';

  @override
  String get redistribute => 'Redistribuir';

  @override
  String topicCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count temas',
      one: '1 tema',
    );
    return '$_temp0';
  }

  @override
  String syllabusTopics(int count) {
    return 'Temas: $count temas del programa';
  }

  @override
  String get masteryRequirement => 'Dominio >= 80% en todos los temas del hito';

  @override
  String noTopicsFoundForSubject(String subjectId) {
    return 'No se encontraron temas para la materia $subjectId';
  }

  @override
  String failedToResolveSyllabus(String error) {
    return 'Error al resolver el programa: $error';
  }

  @override
  String failedToGetQuestionsForTopic(String error) {
    return 'Error al obtener preguntas para el tema: $error';
  }

  @override
  String failedToGetQuestionsForTopics(String error) {
    return 'Error al obtener preguntas para los temas: $error';
  }

  @override
  String filePickerError(String error) {
    return 'Error del selector de archivos: $error';
  }

  @override
  String get urlFetchSuccess => 'Contenido de URL obtenido exitosamente';

  @override
  String urlFetchFailed(String error) {
    return 'Error al obtener URL: $error';
  }

  @override
  String urlFetchError(String error) {
    return 'Error de obtención de URL: $error';
  }

  @override
  String get file => 'Archivo';

  @override
  String get fetchAndScrape => 'Obtener y extraer';

  @override
  String hoursAbbreviation(String hours) {
    return '${hours}h';
  }

  @override
  String tokensLabel(String count) {
    return '$count fichas';
  }

  @override
  String usageRecordFormat(String date, String cost, String costPerToken) {
    return '$date: $cost, costo/token: $costPerToken';
  }

  @override
  String usageSummary(String totalCost, String totalTokens, String avgCost) {
    return 'Uso: $totalCost de $totalTokens tokens, promedio: $avgCost por cada 1k tokens';
  }

  @override
  String get tapToExpand => 'Toca para expandir';

  @override
  String get tapToCollapse => 'Toca para colapsar';

  @override
  String get sendHint =>
      'Presiona Enter para enviar, Ctrl+Enter para nueva línea';

  @override
  String get shareProgressReport => 'Informe de Progreso de StudyKing';

  @override
  String get shareSessionHistory => 'Historial de Sesiones de StudyKing';

  @override
  String get shareInstrumentationData =>
      'Datos de Instrumentación de StudyKing';

  @override
  String get instrumentationDashboard => '=== Panel de Instrumentación ===';

  @override
  String instrumentationGenerated(String date) {
    return 'Generado: $date';
  }

  @override
  String get instrumentationPlanAdherence => '--- Cumplimiento del Plan ---';

  @override
  String get instrumentationMasteryImprovement => '--- Mejora del Dominio ---';

  @override
  String get partialLabel => 'Parcial';

  @override
  String get localeEn => 'Inglés';

  @override
  String get localeEs => 'Español';

  @override
  String get welcomeToStudyKing => 'Bienvenido a StudyKing';

  @override
  String get onboardingDescription =>
      'Tu compañero de aprendizaje con IA. StudyKing te ayuda a dominar cualquier materia con planificación inteligente, práctica adaptativa y tutoría con IA.';

  @override
  String get onboardingSubjectsDesc => 'Añade y organiza tus materias y temas';

  @override
  String get onboardingPracticeDesc =>
      'Practica con preguntas adaptativas y repaso espaciado';

  @override
  String get onboardingMentorDesc =>
      'Recibe recomendaciones de estudio personalizadas';

  @override
  String get onboardingFocusDesc =>
      'Centro de práctica rápida con temporizador: practique preguntas y realice un seguimiento del enfoque';

  @override
  String get onboardingSettingsDesc =>
      'Configure claves API, apariencia y preferencias';

  @override
  String get dontShowAgain => 'No mostrar de nuevo';

  @override
  String get needApiKeyNotice =>
      'Nota: Las funciones de IA requieren una clave API. Configúrela en Ajustes.';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get apiKeyNeeded =>
      'StudyKing necesita una clave API para usar funciones de IA. Configúrala ahora.';

  @override
  String get configureNow => 'Configurar Ahora';

  @override
  String get dataStorageNotice => 'Almacenamiento Local de Datos';

  @override
  String get dataStorageDescription =>
      'StudyKing almacena todos tus datos localmente en este dispositivo. Para evitar la pérdida de datos, usa la función de Copia de Seguridad en Configuración (Configuración > Copia de Seguridad y Restauración).';

  @override
  String get toggleVisibility => 'Alternar visibilidad';

  @override
  String get moreOptions => 'Más opciones';

  @override
  String get iUnderstand => 'Entiendo';

  @override
  String get tutorNeedsSubject =>
      'Por favor, crea primero una materia y un plan de estudio antes de usar el Tutor de IA. El tutor necesita el contexto de un tema para proporcionar lecciones efectivas.';

  @override
  String get aiTaskMonitor => 'Monitor de Tareas de IA';

  @override
  String get viewActiveAiTasks =>
      'Ver tareas activas de inferencia de IA y uso de tokens';

  @override
  String get endLessonConfirmation =>
      '¿Finalizar tu lección? Tu progreso se guardará.';

  @override
  String get continueLesson => 'Continuar Lección';

  @override
  String get backNavigationConfirm => '¿Finalizar lección y guardar progreso?';

  @override
  String get discardAndExit => 'Descartar y Salir';

  @override
  String get saveAndExit => 'Guardar y Salir';

  @override
  String get lessonSavedMessage => 'Tu lección se ha guardado correctamente.';

  @override
  String get cancelLessonConfirmation =>
      '¿Está seguro de que desea cancelar esta lección?';

  @override
  String get orphanedSessionFound => 'Lección Incompleta Encontrada';

  @override
  String orphanedSessionMessage(String topicTitle, String time) {
    return 'Se encontró una lección incompleta sobre \"$topicTitle\" de $time. ¿Qué desea hacer?';
  }

  @override
  String sessionProgressLabel(int current, int total) {
    return 'Progreso de la sesión: $current de $total';
  }

  @override
  String examProgressLabel(int current, int total) {
    return 'Progreso del examen: $current de $total';
  }

  @override
  String get decreaseDuration => 'Disminuir duración';

  @override
  String get increaseDuration => 'Aumentar duración';

  @override
  String nudgeOverworkMinutes(int minutes, int cap) {
    return 'Ha estudiado $minutes minutos hoy, lo que excede su límite diario de $cap minutos. ¡Considere tomar un descanso!';
  }

  @override
  String nudgeLateNight(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Noté que tuvo $count sesiones de estudio nocturnas. ¡Recuerde que descansar es importante para aprender efectivamente!',
      one:
          'Noté que tuvo 1 sesión de estudio nocturna. ¡Recuerde que descansar es importante para aprender efectivamente!',
    );
    return '$_temp0';
  }

  @override
  String nudgeRevisionNeeded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Tiene $count preguntas próximas a su fecha de revisión. ¡Es hora de una sesión de repaso!',
      one:
          'Tiene 1 pregunta próxima a su fecha de revisión. ¡Es hora de una sesión de repaso!',
    );
    return '$_temp0';
  }

  @override
  String nudgeStreakDays(int count) {
    return '¡Felicidades por su racha de estudio de $count días! ¡Siga con esa consistencia tan increíble!';
  }

  @override
  String get nudgeInactive48h =>
      'Han pasado más de 48 horas desde su última sesión de estudio. ¿Se encuentra bien? ¿Le gustaría programar una revisión corta?';

  @override
  String nudgeInactive7d(int days) {
    return 'Han pasado $days días. ¡Retomemos con una sesión de repaso corta!';
  }

  @override
  String nudgeInactive14d(int days) {
    return '¡Bienvenido de nuevo! Han pasado $days días. Planeemos su reincorporación.';
  }

  @override
  String nudgeInactive30d(int days) {
    return 'Han pasado $days días desde su última sesión. ¿Le gustaría ayuda para crear un plan de regreso personalizado?';
  }

  @override
  String welcomeBackDays(int days) {
    return '¡Bienvenido de nuevo! Ha estado ausente durante $days días.';
  }

  @override
  String get absenceDetectedTitle => 'Ausencia Detectada';

  @override
  String absenceDetectedBody(int days) {
    return 'No ha usado StudyKing en $days días. ¿Cómo le gustaría proceder?';
  }

  @override
  String extendPlan(int days) {
    return 'Extender plan de estudio por $days días';
  }

  @override
  String get missedLessonLabel => 'Perdida';

  @override
  String get staleSessionLabel => 'No completada';

  @override
  String get catchUp => 'Ponerse al día';

  @override
  String get catchUpTitle => '¿Cómo le gustaría ponerse al día?';

  @override
  String catchUpDescription(int days) {
    return 'Estuvo ausente durante $days días. Elija una estrategia:';
  }

  @override
  String get catchUpRedistribute => 'Redistribuir en los días restantes';

  @override
  String catchUpExtend(int days) {
    return 'Extender plan por $days días';
  }

  @override
  String planExtended(int days) {
    return 'Plan de estudio extendido por $days días';
  }

  @override
  String get failedToExtendPlan => 'Error al extender el plan de estudio';

  @override
  String get failedToCatchUp =>
      'Error al procesar la estrategia de recuperación';

  @override
  String get missedDismissed => 'Lecciones perdidas descartadas';

  @override
  String get failedToDismissMissed => 'Error al descartar lecciones perdidas';

  @override
  String get dismissAllMissed => 'Descartar todas las perdidas';

  @override
  String missedLessonsCount(int count) {
    return 'Lecciones Perdidas ($count)';
  }

  @override
  String mentorScheduleConflict(String time, String freeSlot) {
    return 'La hora propuesta ($time) entra en conflicto con una lección existente. Espacio libre sugerido: $freeSlot. ¿Lo reservo allí?';
  }

  @override
  String mentorScheduleSuccess(String topic, String time) {
    return 'Lección \"$topic\" programada para $time (30 min). Puede revisarla o reprogramarla en cualquier momento.';
  }

  @override
  String get mentorScheduleFail =>
      'No pude programar la lección. Por favor, inténtelo de nuevo o revise su planificador.';

  @override
  String toolScheduleLessonResult(String topicTitle) {
    return 'Lección programada: $topicTitle';
  }

  @override
  String get toolScheduleLessonFail => 'Error al programar la lección';

  @override
  String get toolGenerateBlocksFail => 'Error al generar bloques de lección';

  @override
  String toolCreatePlanResult(String course, int days) {
    return 'Plan creado para $course durante $days días';
  }

  @override
  String get toolCreatePlanFail => 'Error al crear el plan';

  @override
  String get mentorRescheduleNotFound =>
      'No se pudo encontrar la lección para reprogramar. Es posible que ya haya sido eliminada o completada.';

  @override
  String mentorRescheduleNoFreeSlot(String topic) {
    return 'No se pudo encontrar un espacio libre para reprogramar \"$topic\". Por favor, verifique su disponibilidad en el planificador.';
  }

  @override
  String mentorReschedulePending(String topic, String time) {
    return 'Reprogramación sugerida de \"$topic\" para $time - confirmación pendiente almacenada en el repositorio.';
  }

  @override
  String mentorPlanDaysPrompt(int days) {
    return 'Puedo ayudar a crear un plan de estudio. ¿Le gustaría que configure una hoja de ruta de $days días? Por favor, confirme y proporcione la materia o el objetivo en el que le gustaría enfocarse.';
  }

  @override
  String get lessonPlanSystemPrompt =>
      'Usted es un diseñador curricular que crea planes de lección. Responda solo con JSON válido.';

  @override
  String lessonPlanUserPrompt(
    String subjectId,
    String topicTitle,
    int durationMinutes,
  ) {
    return 'Usted es un tutor de IA experto en $subjectId. Cree un plan de lección estructurado para el tema \"$topicTitle\".\n\nLa lección debe durar $durationMinutes minutos.\n\nDevuelva un objeto JSON.';
  }

  @override
  String tutorSystemPrompt(String subjectId, String topicTitle) {
    return 'Usted es un tutor de IA para $subjectId enseñando \"$topicTitle\". Sea conversacional, cálido y educativo.';
  }

  @override
  String tutorInstructionPrompt(String timeContext, String paceContext) {
    return 'Directrices:\n- $timeContext\n- $paceContext\n- Explique conceptos paso a paso\n- Adáptese al nivel del estudiante\n- Motive siempre al estudiante\n- Si responde correctamente, acelere; si tiene dificultades, simplifique\n- Lleve la cuenta del tiempo de la lección - sea consciente del tiempo\n- Haga preguntas para verificar la comprensión\n- Nunca dé respuestas directamente - guíe al estudiante\n- Inserte ejercicios inline de forma natural en la conversación\n- Celebre las respuestas correctas con elogios específicos\n- Para respuestas incorrectas, explique por qué y guíe hacia el razonamiento correcto';
  }

  @override
  String get summarySystemPrompt =>
      'Usted es un tutor escribiendo notas de lección.';

  @override
  String summaryUserPrompt(
    String topicTitle,
    int exerciseCount,
    int correctCount,
    int confidencePercent,
    String adaptivePace,
  ) {
    return 'Resuma lo cubierto en esta lección sobre \"$topicTitle\".\nIncluya:\n1. Conceptos clave explicados\n2. Preguntas respondidas ($exerciseCount ejercicios, $correctCount correctas)\n3. Nivel de comprensión aparente del estudiante (confianza: $confidencePercent%)\n4. Ritmo adaptativo utilizado (${adaptivePace}x)\n5. Recomendaciones para la próxima lección\n\nManténgalo conciso y constructivo.';
  }

  @override
  String languageInstruction(String localeName) {
    return 'IMPORTANTE: Responda en el mismo idioma que el estudiante (locale: $localeName). No use inglés a menos que el estudiante lo haga.';
  }

  @override
  String get evaluationSystemPrompt =>
      'Usted es un evaluador académico experto. Devuelva solo JSON válido.';

  @override
  String get evaluatorSystemPrompt =>
      'Usted es un evaluador académico experto. Evalúe la respuesta del estudiante y devuelva un objeto JSON con: score (0.0-1.0), explanation, partialCredit (opcional), conceptBreakdown (mapa opcional de concepto->puntaje). Sea justo y alentador. Considere crédito parcial para respuestas parcialmente correctas.';

  @override
  String get classifySystemPrompt =>
      'Usted es un clasificador de contenido. Responda solo con el nombre del tema.';

  @override
  String classifyUserPrompt(String topics, String content) {
    return 'Clasifique el siguiente contenido en uno de estos temas: $topics.\n\nContenido:\n$content\n\nDevuelva solo el nombre del tema más relevante de la lista. No explique. No añada texto adicional.';
  }

  @override
  String get summarizeSystemPrompt =>
      'Usted es un asistente de resumen. Proporcione resúmenes concisos.';

  @override
  String summarizeUserPrompt(String content) {
    return 'Resuma el siguiente contenido en 3-5 oraciones concisas.\n\nContenido:\n$content\n\nProporcione solo el texto del resumen.';
  }

  @override
  String get generateQuestionSystemPrompt =>
      'Usted es un generador de preguntas. Devuelva solo un array JSON válido.';

  @override
  String generateQuestionUserPrompt(String content) {
    return 'Analice el siguiente contenido y extraiga cualquier pregunta existente que contenga.\nTambién genere 3-5 nuevas preguntas de práctica basadas en el contenido.\nDevuelva SOLO un array JSON de objetos de pregunta.\nCada objeto debe tener: \"text\" (la pregunta), \"type\" (uno de: \"singleChoice\", \"multiChoice\", \"typedAnswer\", \"mathExpression\", \"essay\"), \"options\" (lista de opciones de respuesta, requerido para singleChoice y multiChoice), \"correctAnswer\" (el texto de la opción correcta), \"explanation\" (explicación breve).\nPara preguntas multiChoice, correctAnswer debe ser la primera opción correcta e incluya un array \"acceptableAnswers\" con todas las opciones correctas.\nPara typedAnswer y mathExpression, proporcione options como lista vacía y correctAnswer como la respuesta esperada.\n\nContenido:\n$content';
  }

  @override
  String get aiDefaultSystemPrompt =>
      'Usted es un asistente de estudio de IA útil llamado StudyKing. Mantenga las respuestas concisas y educativas.';

  @override
  String get transcribeSystemPrompt =>
      'Usted es un asistente de transcripción. Transcriba contenido de audio/video con precisión.';

  @override
  String transcribeUserPrompt(String content) {
    return 'Transcriba el siguiente contenido de audio/video.\nDevuelva solo el texto transcrito. Preserve el lenguaje natural y el formato.\n\nContenido: $content';
  }

  @override
  String get ocrSystemPrompt =>
      'Usted es un asistente de OCR. Extraiga texto de imágenes con precisión.';

  @override
  String ocrUserPrompt(String content) {
    return 'Extraiga todo el texto visible en el contenido de esta imagen.\nDevuelva solo el texto extraído, preservando el formato original tanto como sea posible.\nSi no hay texto visible, devuelva una cadena vacía.\n\nContenido de la imagen (base64 o referencia): $content';
  }

  @override
  String get modelNotConfigured =>
      'No hay un modelo de IA configurado. Vaya a Configuración y seleccione un proveedor de modelo antes de generar preguntas.';

  @override
  String get generateQuestionsFromContent =>
      'Generar preguntas desde este contenido';

  @override
  String get generateQuestionsFromContentHint =>
      'La IA creará preguntas de práctica basadas en el material subido';

  @override
  String get uploadMaterialsToCreateQuestions =>
      'Sube materiales para crear preguntas';

  @override
  String get noQuestionsPracticeHint =>
      'Aún no tiene preguntas de práctica. Suba materiales de estudio para generar preguntas.';

  @override
  String get uploadMaterials => 'Subir Materiales';

  @override
  String get questionsToday => 'Preguntas Hoy';

  @override
  String get currentStreak => 'Racha Actual';

  @override
  String get dueForReview => 'Pendientes de Repaso';

  @override
  String get practiceAtLeastTen =>
      'Practica al menos 10 preguntas para identificar áreas débiles';

  @override
  String get uploadMaterialsToGenerateTopics =>
      'Sube materiales para generar temas';

  @override
  String get confirmExitPractice => '¿Salir de la sesión de práctica?';

  @override
  String get confirmExitPracticeBody =>
      'Su progreso en esta sesión se guardará, pero saldrá antes de completar todas las preguntas.';

  @override
  String get stay => 'Quedarse';

  @override
  String get exit => 'Salir';

  @override
  String get noQuestionsForSubject =>
      'No se encontraron preguntas de práctica para esta materia. Intenta subir materiales de estudio primero.';

  @override
  String get confirmExitFocus => '¿Finalizar sesión de enfoque?';

  @override
  String get confirmExitFocusBody =>
      'Tiene una sesión de enfoque activa. Al finalizarla temprano se guardará su progreso hasta ahora.';

  @override
  String get endSession => 'Finalizar Sesión';

  @override
  String get sourceWithNoQuestions =>
      '0 preguntas — genera preguntas desde esta fuente';

  @override
  String get requiredField => 'Campo obligatorio';

  @override
  String get gallery => 'Galería';

  @override
  String get requiredFieldIndicator => '*';

  @override
  String get expressionLabel => 'Expresión: ';

  @override
  String get defaultLessonGoal => 'Comprender el tema';

  @override
  String get sectionIntroduction => 'Introducción';

  @override
  String get sectionMainContent => 'Contenido Principal';

  @override
  String get sectionPractice => 'Práctica';

  @override
  String get checkpointStarted => 'Lección iniciada';

  @override
  String get checkpointTopicCovered => 'Tema cubierto';

  @override
  String get checkpointPracticeCompleted => 'Práctica completada';

  @override
  String get sessionType => 'Tipo';

  @override
  String get sessionTypePractice => 'Práctica';

  @override
  String get sessionTypeFocus => 'Enfoque';

  @override
  String get sessionTypeTutoring => 'Tutoría';

  @override
  String get sessionTypeManual => 'Manual';

  @override
  String get addCourseSubject => 'Agregar Curso/Materia';

  @override
  String hoursPerDayAbbrev(String hours) {
    return '$hours h/día';
  }

  @override
  String lessonTimeStatus(String topicId, String time, String completedSuffix) {
    return '$topicId, $time$completedSuffix';
  }

  @override
  String practiceModeWithSubject(String mode, String subject) {
    return '$mode - $subject';
  }

  @override
  String mentorWelcomeFull(String greeting, String body) {
    return '$greeting\n\n$body';
  }

  @override
  String get unknownError => 'Error desconocido';

  @override
  String failedToLoadPlan(Object error) {
    return 'Error al cargar el plan: $error';
  }

  @override
  String backupExportFailedWithError(String error) {
    return 'Error al exportar la copia de seguridad: $error';
  }

  @override
  String invalidBackupFileWithError(String error) {
    return 'Archivo de copia no válido: $error';
  }

  @override
  String get backupBoxSubjects => 'Materias';

  @override
  String get backupBoxTopics => 'Temas';

  @override
  String get backupBoxQuestions => 'Preguntas';

  @override
  String get backupBoxSources => 'Fuentes';

  @override
  String get backupBoxLessons => 'Lecciones';

  @override
  String get backupBoxLessonBlocks => 'Bloques de Lecciones';

  @override
  String get backupBoxSessionsTyped => 'Sesiones';

  @override
  String get backupBoxSessions => 'Sesiones (antiguas)';

  @override
  String get backupBoxMasteryStates => 'Estados de Dominio';

  @override
  String get backupBoxQuestionMasteryStates => 'Dominio de Preguntas';

  @override
  String get backupBoxQuestionEvaluations => 'Evaluaciones de Preguntas';

  @override
  String get backupBoxLearningPlans => 'Planes de Estudio';

  @override
  String get backupBoxPlanAdherence => 'Adhesión al Plan';

  @override
  String get backupBoxPlanAdherenceMetrics => 'Métricas del Plan';

  @override
  String get backupBoxMasteryImprovementMetrics => 'Métricas de Dominio';

  @override
  String get backupBoxConversations => 'Conversaciones';

  @override
  String get backupBoxTutorSessions => 'Sesiones de Tutoría';

  @override
  String get backupBoxTopicDependencies => 'Dependencias de Temas';

  @override
  String get backupBoxSettings => 'Ajustes';

  @override
  String get backupBoxProfile => 'Perfil';

  @override
  String get backupBoxAnswers => 'Respuestas';

  @override
  String get backupBoxAttempts => 'Intentos';

  @override
  String get backupBoxBadges => 'Insignias';

  @override
  String get backupBoxEngagementNudges => 'Notificaciones de Compromiso';

  @override
  String get backupBoxFocusSessions => 'Sesiones de Enfoque';

  @override
  String get backupBoxPendingActions => 'Acciones Pendientes';

  @override
  String get backupBoxProgress => 'Progreso';

  @override
  String get backupBoxTasks => 'Tareas';

  @override
  String get backupBoxStudentAvailability => 'Disponibilidad del Estudiante';

  @override
  String get backupBoxRoadmaps => 'Hoja de Ruta';

  @override
  String get backupBoxLlmTasks => 'Tareas del LLM';

  @override
  String get backupBoxLlmUsageRecords => 'Registros de Uso del LLM';

  @override
  String get apiKeyPlaintextWarning =>
      'Tus claves API serán legibles como texto plano en el archivo de respaldo. Cualquier persona con acceso a este archivo puede usar tus claves API.';

  @override
  String boxCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cajas',
      one: '1 caja',
    );
    return '$_temp0';
  }

  @override
  String andMoreCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count más',
      one: '1 más',
    );
    return '... y $_temp0';
  }

  @override
  String get signOutClearList => 'Lo que se borrará:';

  @override
  String get signOutClearsApiKey => 'Clave API';

  @override
  String get signOutClearsAiModel => 'Modelo de IA seleccionado';

  @override
  String get signOutPreservesStudyData =>
      'Tus datos de estudio se conservarán.';

  @override
  String get importRestartHint =>
      'Es posible que se necesite un reinicio para que todos los cambios aparezcan.';

  @override
  String get studentIdMismatchTitle =>
      'Se detectó una discrepancia en la ID del estudiante';

  @override
  String studentIdMismatchBody(String currentId, String backupId) {
    return 'Actual: $currentId\nRespaldo: $backupId';
  }

  @override
  String get studentIdMismatchAction =>
      '¿Actualizar los registros del estudiante para que coincidan con la ID actual?';

  @override
  String questionsCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count preguntas disponibles',
      one: '1 pregunta disponible',
      zero: 'No hay preguntas disponibles',
    );
    return '$_temp0';
  }

  @override
  String get mentorBulletPoint => '• ';

  @override
  String get pageNotFound => 'Página no encontrada';

  @override
  String get pageNotFoundDescription =>
      'La página que buscas no existe o el enlace no es válido.';

  @override
  String get goToDashboard => 'Ir al Panel';

  @override
  String get sending => 'Enviando';

  @override
  String get dailyReminderDescription =>
      'Reciba un recordatorio diario para estudiar a su hora preferida';

  @override
  String get reminderTime => 'Hora del Recordatorio';

  @override
  String get dailyReminderTimeHelp => 'Hora del Recordatorio Diario';

  @override
  String get checkNudgesNow => 'Revisar Avisos Ahora';

  @override
  String get runNudgeChecks => 'Ejecutar avisos inmediatamente';

  @override
  String get nudgeCheckComplete => 'Revisión de avisos completada';

  @override
  String get nudgeCheckFailed => 'Revisión de avisos fallida';

  @override
  String get dailyCapWarningTitle => 'Advertencia de Límite Diario';

  @override
  String dailyCapWarningBody(int selectedMinutes, int remaining) {
    return 'Iniciar esta sesión excederá su límite diario. $selectedMinutes min seleccionados, $remaining min restantes. ¿Continuar?';
  }

  @override
  String get continueAnyway => 'Continuar de Todas Formas';

  @override
  String get focusFirstVisitHelp =>
      'Configure un temporizador y estudie sin distracciones. Las sesiones completadas cuentan para su plan diario.';

  @override
  String get contentManagement => 'Gestión de Contenido';

  @override
  String get myUploads => 'Mis Cargas';

  @override
  String get viewMyUploads => 'Ver sus materiales cargados';

  @override
  String get questionBank => 'Banco de Preguntas';

  @override
  String get browseAndManageQuestions => 'Explorar y gestionar preguntas';

  @override
  String get failedUploads => 'Cargas Fallidas';

  @override
  String sourceCountFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fuentes fallaron al procesarse',
      one: '1 fuente falló al procesarse',
    );
    return '$_temp0';
  }

  @override
  String get noFailedUploads => 'Sin cargas fallidas';

  @override
  String get breakDuration => 'Duración del Descanso';

  @override
  String get sessionTracking => 'Seguimiento de Sesiones';

  @override
  String get manualSessionTracker => 'Rastreador de Sesiones Manual';

  @override
  String get manualSessionTrackerDescription =>
      'Seguimiento manual del tiempo de estudio';

  @override
  String get sessionHistoryDescription =>
      'Revisar sesiones de estudio anteriores';

  @override
  String get exportProgressCsv => 'Exportar Progreso CSV';

  @override
  String get featureLabelIngestion => 'Ingestión';

  @override
  String get featureLabelGeneral => 'General';

  @override
  String get deleteSourceTitle => 'Eliminar fuente';

  @override
  String get deleteSourceBody =>
      '¿Está seguro de que desea eliminar esta fuente?';

  @override
  String get dailyReminderNotificationTitle => 'Recordatorio de estudio diario';

  @override
  String get dailyReminderNotificationBody =>
      '¡Hora de estudiar! Tiene tareas de estudio planificadas para hoy.';

  @override
  String get addSubjectsForFocusHint =>
      'Agregue materias en Configuración para realizar un seguimiento del enfoque por materia.';

  @override
  String get retrying => 'Reintentando...';

  @override
  String get unableToResolveSubject =>
      'No se pudo encontrar la materia para este tema.';

  @override
  String get questionDeleted => 'Pregunta eliminada';

  @override
  String get deleteQuestion => 'Eliminar pregunta';

  @override
  String get deleteQuestionConfirm =>
      '¿Está seguro de que desea eliminar esta pregunta?';

  @override
  String get deleteQuestions => 'Eliminar preguntas';

  @override
  String deleteQuestionsConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count preguntas',
      one: '1 pregunta',
    );
    return '¿Está seguro de que desea eliminar $_temp0?';
  }

  @override
  String questionsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count preguntas eliminadas',
      one: '1 pregunta eliminada',
    );
    return '$_temp0';
  }

  @override
  String get editQuestion => 'Editar pregunta';

  @override
  String get questionText => 'Texto de la pregunta';

  @override
  String get questionBankScreen => 'Banco de preguntas';

  @override
  String questionSubtitle(String questionType, String difficulty) {
    return '$questionType • $difficulty';
  }

  @override
  String get cancelSelection => 'Cancelar selección';

  @override
  String get deleteSelected => 'Eliminar seleccionadas';

  @override
  String get selectMultiple => 'Seleccionar múltiples';

  @override
  String get searchQuestions => 'Buscar preguntas';

  @override
  String get allSubjects => 'Todas las materias';

  @override
  String get allTypes => 'Todos los tipos';

  @override
  String get allSources => 'Todas las fuentes';

  @override
  String get acceleratePace =>
      'El estudiante lo está haciendo bien. Acelere el ritmo.';

  @override
  String get slowDownPace =>
      'El estudiante parece tener dificultades. Reduzca la velocidad, simplifique las explicaciones y proporcione más ejemplos.';

  @override
  String get maintainPace => 'Mantenga un ritmo de enseñanza constante.';

  @override
  String get greetingContext => 'Comience la lección calurosamente.';

  @override
  String get teachingContext =>
      'Enseñe el concepto paso a paso. Involucre al estudiante con preguntas.';

  @override
  String get exerciseContext =>
      'Dé al estudiante una pregunta de práctica para evaluar su comprensión.';

  @override
  String get feedbackContext =>
      'Proporcione retroalimentación constructiva sobre su respuesta.';

  @override
  String get adaptiveReviewContext =>
      'El estudiante necesita ayuda adicional. Vuelva a explicar el concepto de forma más sencilla. Use ejemplos diferentes.';

  @override
  String get closingContext => 'Concluya la lección. Resuma los puntos clave.';

  @override
  String evaluateStudentAnswerIntro(
    String subjectId,
    String topicTitle,
    String question,
    String studentAnswer,
  ) {
    return 'Evalúe esta respuesta del estudiante para la materia \"$subjectId\" sobre el tema \"$topicTitle\".\n\nPregunta: $question\n\nRespuesta del estudiante: $studentAnswer\n\nDevuelva un objeto JSON con:';
  }

  @override
  String minutesSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutos',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String breakRemainingLabel(String formattedTime) {
    return 'Quedan $formattedTime de descanso';
  }

  @override
  String get loading => 'Cargando...';

  @override
  String get pending => 'Pendiente';

  @override
  String get extracting => 'Extrayendo';

  @override
  String get processing => 'Procesando';

  @override
  String get summarizing => 'Resumiendo';

  @override
  String get generatingQuestions => 'Generando Preguntas';

  @override
  String get contentLibrary => 'Biblioteca de Contenido';

  @override
  String get sortOrder => 'Ordenar';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get allStatuses => 'Todos los estados';

  @override
  String get sourceDeleted => 'Fuente eliminada';

  @override
  String get alsoDeleteQuestions =>
      'Eliminar también las preguntas generadas de esta fuente';

  @override
  String get reprocess => 'Reprocesar';

  @override
  String sourcesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fuentes',
      one: '1 fuente',
    );
    return '$_temp0';
  }

  @override
  String get sourceNotFound => 'Fuente no encontrada';

  @override
  String get errorLoadingSource =>
      'Ocurrió un error al cargar la fuente. Intente de nuevo.';

  @override
  String get reprocessSource => 'Reprocesar Fuente';

  @override
  String get reprocessingWarning =>
      'El reprocesamiento reemplazará las preguntas generadas existentes. ¿Continuar?';

  @override
  String get reprocessing => 'Reprocesando...';

  @override
  String get sourceDetail => 'Detalle de Fuente';

  @override
  String get status => 'Estado';

  @override
  String get subject => 'Materia';

  @override
  String get id => 'ID';

  @override
  String get uploaded => 'Subido';

  @override
  String get processingFailed => 'Procesamiento fallido';

  @override
  String get topicClassification => 'Clasificación de Tema';

  @override
  String get notYetClassified => 'Aún no clasificado';

  @override
  String get classifyNow => 'Clasificar Ahora';

  @override
  String get summarySection => 'Resumen';

  @override
  String get noSummaryAvailable => 'No hay resumen disponible';

  @override
  String get extractedText => 'Texto Extraído';

  @override
  String extractedTextCount(int count) {
    return 'Texto Extraído ($count)';
  }

  @override
  String get searchInText => 'Buscar en texto';

  @override
  String get noExtractedText => 'No hay texto extraído disponible';

  @override
  String get generatedQuestions => 'Preguntas Generadas';

  @override
  String generatedQuestionsCount(int count) {
    return 'Preguntas Generadas ($count)';
  }

  @override
  String get noQuestionsFromSource => 'No hay preguntas de esta fuente';

  @override
  String get difficulty => 'Dificultad';

  @override
  String get edit => 'Editar';

  @override
  String get aiGenerated => 'Generado por IA';

  @override
  String get manual => 'Manual';

  @override
  String get sources => 'Fuentes';

  @override
  String get viewSources => 'Ver Fuentes';

  @override
  String get noSourcesForSubject => 'No hay fuentes para esta materia';

  @override
  String get remainingWorkload => 'Carga de Trabajo Restante';

  @override
  String get explanation => 'Explicación';

  @override
  String sourcesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fuentes',
      one: '1 fuente',
    );
    return '$_temp0';
  }

  @override
  String get difficultyDistribution => 'Distribución de Dificultad';

  @override
  String get difficultyDistributionHint =>
      'Establezca el número de preguntas Fáciles, Medias y Difíciles. Deje todo en 0 para selección aleatoria equilibrada.';

  @override
  String get easyQuestions => 'Fácil';

  @override
  String get mediumQuestions => 'Media';

  @override
  String get hardQuestions => 'Difícil';

  @override
  String get totalSelected => 'Total Seleccionado';

  @override
  String get practiceAction => 'Practicar';

  @override
  String get viewDetailsAction => 'Ver Detalles';

  @override
  String mentorScheduleTopic(String topicTitle) {
    return 'Tema: $topicTitle';
  }

  @override
  String mentorContextLateNightWarning(int count) {
    return 'ADVERTENCIA: $count sesión(es) iniciada(s) después de las 10 PM (estudio nocturno detectado)';
  }

  @override
  String get avgTimePerQuestion => 'Tiempo prom./pregunta';

  @override
  String examResultsSrsImpact(int count) {
    return 'Los resultados afectarán la programación de repaso espaciado de $count preguntas.';
  }

  @override
  String get questionsAtAGlance => 'Preguntas de un vistazo';

  @override
  String get noExamHistory => 'No hay historial de exámenes disponible';

  @override
  String get examHistory => 'Historial de Exámenes';

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '${minutes}m ${seconds}s';
  }

  @override
  String get viewPastExamResults => 'Ver resultados de exámenes anteriores';

  @override
  String get mentorContextHeader => 'Contexto actual del estudiante:';

  @override
  String mentorContextTotalAttempts(int count) {
    return 'Intentos totales: $count';
  }

  @override
  String mentorContextCorrectAttempts(int count) {
    return 'Intentos correctos: $count';
  }

  @override
  String mentorContextAccuracy(String percent) {
    return 'Precisión: $percent%';
  }

  @override
  String mentorContextTopicsStudied(int count) {
    return 'Temas estudiados: $count';
  }

  @override
  String mentorContextWeeklyActivity(int count) {
    return 'Actividad semanal: $count intentos';
  }

  @override
  String mentorContextTotalStudyTime(String hours) {
    return 'Tiempo total de estudio: $hours horas';
  }

  @override
  String mentorContextPlanPhase(int currentDay, int totalDays) {
    return 'Plan existente: fase actual (día $currentDay de $totalDays)';
  }

  @override
  String mentorContextPlanAdherence(String percent) {
    return 'Adherencia al plan: $percent%';
  }

  @override
  String mentorContextLowAdherence(int count) {
    return 'Baja adherencia durante $count días consecutivos';
  }

  @override
  String mentorContextDaysSinceActivity(int count) {
    return 'Días desde la última actividad: $count';
  }

  @override
  String mentorContextWelcomeBack(int count) {
    return 'IMPORTANTE: El estudiante regresa después de una ausencia de $count días. Proporcione una cálida bienvenida y sugiera pasos específicos para ponerse al día.';
  }

  @override
  String mentorContextActiveRoadmaps(int count) {
    return 'Roadmaps activos: $count';
  }

  @override
  String mentorContextRoadmapProgress(String goal, int completed, int total) {
    return '$goal: $completed/$total hitos completados';
  }

  @override
  String mentorContextNextMilestone(String title, String dueDate) {
    return 'Próximo hito: \"$title\" vence $dueDate';
  }

  @override
  String mentorContextPendingActions(int count) {
    return 'Acciones pendientes que esperan decisión: $count';
  }

  @override
  String mentorContextPendingActionItem(String type, String topic) {
    return '$type: $topic';
  }

  @override
  String mentorContextUpcomingLessons(int count) {
    return 'Próximas lecciones (próximas $count):';
  }

  @override
  String mentorContextLessonItem(String title, String time, int duration) {
    return '\"$title\" a las $time (${duration}min)';
  }

  @override
  String get mentorContextWeakTopics => 'Temas débiles que necesitan atención:';

  @override
  String mentorContextWeakTopicItem(String topic, String accuracy) {
    return '$topic (precisión: $accuracy%)';
  }

  @override
  String mentorContextStudyTimeToday(int minutes) {
    return 'Tiempo de estudio de hoy: $minutes minutos';
  }

  @override
  String mentorContextCapExceeded(int cap, int today) {
    return 'ADVERTENCIA: Límite diario de estudio ($cap min) excedido por $today minutos';
  }

  @override
  String mentorContextCapRemaining(int cap, int remaining) {
    return 'Límite diario: $cap minutos ($remaining min restantes)';
  }

  @override
  String mentorContextStreak(int count) {
    return '¡Felicidades! Racha de $count días de estudio!';
  }

  @override
  String mentorContextStreakGood(int count) {
    return '$count días consecutivos de estudio - ¡buena consistencia!';
  }

  @override
  String mentorContextSessionsToday(int count) {
    return 'Sesiones hoy: $count';
  }

  @override
  String get createQuestion => 'Crear Pregunta';

  @override
  String get questionTextHint => 'Ingrese el texto de la pregunta';

  @override
  String get answerOptions => 'Opciones de Respuesta';

  @override
  String get addOption => 'Agregar Opción';

  @override
  String get correctAnswerLabel => 'Respuesta Correcta';

  @override
  String get selectCorrectAnswer => 'Seleccionar respuesta correcta';

  @override
  String get questionCreated => 'Pregunta creada exitosamente';

  @override
  String get manageQuestions => 'Gestionar Preguntas';

  @override
  String get backupContainsSensitiveData =>
      'Esta copia de seguridad contiene datos sensibles (clave API, configuración del modelo). Tenga cuidado al compartir este archivo.';

  @override
  String get excludeSensitiveData => 'Excluir datos sensibles';

  @override
  String get sensitiveDataWillBeExcluded =>
      'Los datos sensibles serán excluidos. Necesitará reingresar su clave API después de la restauración.';

  @override
  String get selectBoxesToRestore => 'Seleccionar secciones para restaurar';

  @override
  String get selectAll => 'Seleccionar Todo';

  @override
  String get deselectAll => 'Deseleccionar Todo';

  @override
  String get selectedBoxesWillBeOverwritten =>
      'Las secciones seleccionadas serán completamente sobrescritas.';

  @override
  String get autoBackup => 'Copia de Seguridad Automática';

  @override
  String get autoBackupDescription =>
      'Programar copias de seguridad automáticas';

  @override
  String get backupIntervalDaily => 'Diario';

  @override
  String get backupIntervalWeekly => 'Semanal';

  @override
  String get backupIntervalNever => 'Nunca';

  @override
  String get lastBackup => 'Última copia';

  @override
  String aiTaskFailedNotification(String feature) {
    return 'Tarea de IA fallida: $feature';
  }

  @override
  String aiTaskFailedBody(String feature, String error) {
    return 'La tarea \'$feature\' falló. $error';
  }

  @override
  String get questionBankLink => 'Banco de Preguntas';

  @override
  String get overwriteRestore => 'Sobrescribir todo';

  @override
  String get mergeRestore => 'Combinar (omitir existentes)';

  @override
  String get backupCompleted => 'Copia de seguridad completada automáticamente';

  @override
  String get viewInSettings => 'Abrir Configuración';

  @override
  String get phaseGreeting => 'Saludo';

  @override
  String get phaseTeaching => 'Enseñanza';

  @override
  String get phaseExercise => 'Ejercicio';

  @override
  String get phaseFeedback => 'Retroalimentación';

  @override
  String get phaseAdaptiveReview => 'Revisión Adaptativa';

  @override
  String get phaseClosing => 'Cierre';

  @override
  String examSessionTitle(String mode, String subject) {
    return '$mode – $subject';
  }

  @override
  String get signOutComplete => 'Cerrar sesión – Hecho';

  @override
  String importFailedWithError(String error) {
    return 'Importación fallida: $error';
  }

  @override
  String scheduleTimeLabel(String time) {
    return 'Hora: $time';
  }

  @override
  String scheduleDurationLabel(String duration) {
    return 'Duración: $duration';
  }

  @override
  String recordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros',
      one: '1 registro',
    );
    return '$_temp0';
  }

  @override
  String get couldNotEvaluateAnswer => 'No se pudo evaluar la respuesta.';

  @override
  String couldNotEvaluateAnswerWithError(String error) {
    return 'No se pudo evaluar la respuesta: $error';
  }

  @override
  String tutorImageAnalysisUserPrompt(String imageData) {
    return 'El estudiante ha enviado trabajo escrito a mano / una imagen. Analiza y proporciona retroalimentación, identificando errores y sugiriendo mejoras.\n\n$imageData';
  }

  @override
  String get tutorImageAnalysisSystemPrompt =>
      'El estudiante ha enviado este trabajo. Analiza y proporciona retroalimentación.';

  @override
  String dependenciesTitle(String topic) {
    return '$topic — Dependencias';
  }

  @override
  String get prerequisites => 'Requisitos previos';

  @override
  String get noTopicsForPrerequisites =>
      'No hay otros temas disponibles como requisitos previos.';

  @override
  String get noDescription => 'Sin descripción';

  @override
  String masteryThreshold(String percent) {
    return 'Umbral de Dominio: $percent%';
  }

  @override
  String get requiredTopic => 'Tema Requerido';

  @override
  String get requiredTopicOn => 'El estudiante debe dominar este tema';

  @override
  String get requiredTopicOff => 'Tema opcional — puede omitirse';

  @override
  String syllabusWeight(String weight) {
    return 'Peso del Temario: $weight';
  }

  @override
  String get parentTopic => 'Tema Padre';

  @override
  String get rootTopic => 'Ninguno (Tema Raíz)';

  @override
  String sortOrderValue(int order) {
    return 'Orden: $order';
  }

  @override
  String topicCreated(String title) {
    return 'Tema \"$title\" creado';
  }

  @override
  String topicCreateFailed(String error) {
    return 'Error al crear tema: $error';
  }

  @override
  String get editTopicTitle => 'Editar Tema';

  @override
  String topicUpdated(String title) {
    return 'Tema \"$title\" actualizado';
  }

  @override
  String topicUpdateFailed(String error) {
    return 'Error al actualizar tema: $error';
  }

  @override
  String get dependenciesUpdated => 'Dependencias actualizadas';

  @override
  String dependenciesUpdateFailed(String error) {
    return 'Error al actualizar dependencias: $error';
  }

  @override
  String get deleteTopicTitle => 'Eliminar Tema';

  @override
  String deleteTopicConfirm(String topic) {
    return '¿Eliminar \"$topic\"? Esto lo eliminará de todas las listas de dependencias.';
  }

  @override
  String get topicDeleted => 'Tema eliminado';

  @override
  String topicDeleteFailed(String error) {
    return 'Error al eliminar tema: $error';
  }

  @override
  String get topicTitleLabel => 'Título del Tema';

  @override
  String get topicTitleHint => 'p. ej., Estructura Atómica';

  @override
  String get topicDescriptionLabel => 'Descripción del Tema';

  @override
  String get topicDescriptionHint => 'Describa el alcance del tema';

  @override
  String get syllabusTextLabel => 'Texto del Plan de Estudios';

  @override
  String get syllabusTextHint => 'Puntos del plan de estudios cubiertos';

  @override
  String get addTopicTitle => 'Agregar Tema';

  @override
  String topicCountTemplate(int count) {
    return '$count temas';
  }

  @override
  String get dependenciesNav => 'Dependencias';

  @override
  String prerequisitesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count requisitos previos',
      one: '1 requisito previo',
    );
    return '$_temp0';
  }

  @override
  String downstreamCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dependientes',
      one: '1 dependiente',
    );
    return '$_temp0';
  }

  @override
  String get hasParent => 'Tiene padre';

  @override
  String get addTopicTooltip => 'Agregar Tema';

  @override
  String downstreamTopicWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count temas dependientes dependen',
      one: '1 tema dependiente depende',
    );
    return '⚠ $_temp0 de este tema y pueden necesitar actualización.';
  }

  @override
  String get prerequisitesNotMet => 'Prerrequisitos no cumplidos';

  @override
  String get practicePrerequisites => 'Practicar Prerrequisitos';

  @override
  String prerequisiteMasteryRequired(String topicNames) {
    return 'Este tema requiere dominio de: $topicNames. ¿Desea practicar esos primero?';
  }

  @override
  String get inlinePracticeSubtitle =>
      'Practique directamente en modo de enfoque — el temporizador sigue corriendo';

  @override
  String get fullPracticeSubtitle =>
      'Navegar a la pantalla de práctica completa';

  @override
  String get generateLessonFromContent => 'Generar lección desde este material';

  @override
  String get generateLessonFromContentHint =>
      'Crea una lección generada por IA con diapositivas, ejercicios y bloques de resumen';

  @override
  String subjectNoTopics(String subjectName) {
    return '$subjectName no tiene temas. Agregue temas primero o suba un programa de estudios.';
  }

  @override
  String get noActivityShort => '—';

  @override
  String courseNotFound(String courseName) {
    return 'Curso \'$courseName\' no encontrado. Créelo primero en la pestaña Temas, o seleccione de las materias existentes usando el modo multi-programa.';
  }

  @override
  String get planSubjectHint =>
      'Ingrese el nombre de una materia existente para basar el plan en su programa de estudios';

  @override
  String get chat => 'Chat';

  @override
  String get slides => 'Diapositivas';

  @override
  String get connectionHealth => 'Estado de la Conexión';

  @override
  String get notTested => 'No probado';

  @override
  String get messageFailedRetry => 'Mensaje fallido. Toca para reintentar.';

  @override
  String get share => 'Compartir';

  @override
  String backupShareText(String date) {
    return 'Copia de seguridad de StudyKing — $date';
  }

  @override
  String get backupNow => 'Hacer copia ahora';

  @override
  String get shareLastBackup => 'Compartir última copia';

  @override
  String get exportReports => 'Exportar informes';

  @override
  String get readAloud => 'Leer en voz alta';

  @override
  String get uploadFile => 'Subir archivo';

  @override
  String get fileAttached => 'Archivo adjunto';

  @override
  String get recordAudio => 'Grabar audio';

  @override
  String get recordingComplete => 'Grabación completa';

  @override
  String get startRecording => 'Iniciar grabación';

  @override
  String lessonSystemPrompt(String localeName) {
    return 'Eres una IA de planificación de lecciones. Genera contenido educativo en $localeName. Tu respuesta debe ser JSON válido.';
  }

  @override
  String lessonBuildPrompt(String topicTitle, String localeName) {
    return 'Genera un plan de lección estructurado para el tema: \"$topicTitle\". Incluye diapositivas (conceptos clave), ejemplos, ejercicios y un resumen. Responde en $localeName. Formatea tu respuesta como un arreglo JSON de bloques, cada uno con campos \"type\" (slide, text, example, exercise, quiz, summary) y \"content\".';
  }

  @override
  String lessonBuildPromptFromSource(
    String sourceContent,
    String topicTitle,
    String localeName,
  ) {
    return 'Basado en el siguiente material fuente, genera una lección estructurada:\n\n$sourceContent\n\nTema: $topicTitle\nGenera diapositivas, ejemplos, ejercicios y un resumen. Responde en $localeName como un arreglo JSON de bloques.';
  }

  @override
  String get mentorCheckIn => 'Control del Mentor';

  @override
  String get nextUp => 'Próximo';

  @override
  String get scheduledLesson => 'Lección programada';

  @override
  String upcomingLessonsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lecciones próximas',
      one: '1 lección próxima',
    );
    return '$_temp0';
  }

  @override
  String reviewsDueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count revisiones pendientes',
      one: '1 revisión pendiente',
    );
    return '$_temp0';
  }

  @override
  String get dueForReviewSubtitle =>
      'Pendiente de revisión por repaso espaciado';

  @override
  String weakTopicsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count temas débiles',
      one: '1 tema débil',
    );
    return '$_temp0';
  }

  @override
  String get practiceWeakAreas => 'Practicar áreas débiles';

  @override
  String lessonsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '~$count lecciones',
      one: '~$count lección',
    );
    return '$_temp0';
  }

  @override
  String topicsNeedAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count temas necesitan atención',
      one: '1 tema necesita atención',
    );
    return '$_temp0';
  }

  @override
  String get stopRecording => 'Detener grabación';

  @override
  String get incorrectAnswer => 'Respuesta incorrecta';

  @override
  String get loadingWithEllipsis => 'Cargando...';

  @override
  String get whileYouWereAway => '--- Mientras estabas ausente ---';

  @override
  String get endOfPendingMessages => '--- Fin de mensajes pendientes ---';

  @override
  String get lessonPractice => 'Práctica de Lección';

  @override
  String lessonPracticeWithTopic(String topic) {
    return 'Práctica de Lección: $topic';
  }

  @override
  String pageIndicator(int current, int total) {
    return '$current / $total';
  }

  @override
  String get mentorMessages => 'Mensajes del Mentor';

  @override
  String get readyToContinueLearning => '¿Listo para seguir aprendiendo?';

  @override
  String get graphCanvas => 'Lienzo de gráficos';

  @override
  String get drawYourGraphHere => 'Dibuja tu gráfico aquí';

  @override
  String strokesCountPoints(int strokes, int points) {
    return '$strokes trazos, $points puntos';
  }

  @override
  String get toolFreehand => 'Mano alzada';

  @override
  String get toolLine => 'Línea';

  @override
  String get toolRectangle => 'Rectángulo';

  @override
  String get toolCircle => 'Círculo';

  @override
  String get toolText => 'Texto';

  @override
  String get toolPlotPoint => 'Punto';

  @override
  String get toolEraser => 'Borrador';

  @override
  String get unableToDisplayEvaluation =>
      'No se puede mostrar el resultado de la evaluación';

  @override
  String get micPermissionDenied =>
      'Acceso al micrófono denegado. Actívalo en Ajustes para usar la entrada de voz.';

  @override
  String get focusTimerLabel => '(Enfoque)';

  @override
  String get voiceListeningHint => 'Escuchando. Hable ahora.';

  @override
  String get boldText => 'Texto en Negrita';

  @override
  String get boldTextDescription =>
      'Usar fuente en negrita para el texto en toda la aplicación';

  @override
  String get voiceInputNotAvailable => 'Entrada de voz no disponible';

  @override
  String get microphonePermissionRequired => 'Permiso de Micrófono Requerido';

  @override
  String get showOnboardingTour => 'Mostrar tour de introducción';

  @override
  String get saveOnly => 'Solo Guardar';

  @override
  String get proceedAnyway => 'Continuar de Todos Modos';

  @override
  String get modelCapabilityWarningTitle => 'Aviso de Capacidad del Modelo';

  @override
  String get modelCapabilityWarningBody =>
      'Es posible que su modelo seleccionado no admita el análisis de imágenes o audio. ¿Continuar de todos modos?';

  @override
  String processingElapsed(int seconds) {
    return 'Procesando... ${seconds}s transcurridos';
  }

  @override
  String progressStageLabel(int current, int total) {
    return 'Etapa $current de $total';
  }

  @override
  String get practiceAllQuestions => 'Practicar Todas las Preguntas';

  @override
  String get noQuestionsToPractice => 'Sin preguntas para practicar';

  @override
  String get questionsWithoutTopicWarning =>
      'Estas preguntas no están vinculadas a ningún tema. Use el clasificador de temas o edite el tema de la fuente para habilitar la práctica específica de temas.';

  @override
  String get keepOldQuestionsLabel => 'Conservar preguntas antiguas';

  @override
  String get keepOldQuestionsHint =>
      'Las preguntas antiguas se conservarán junto con las nuevas';

  @override
  String get postUploadGuidance =>
      '¡Ahora puede practicar las preguntas generadas en la pestaña de Práctica!';

  @override
  String get uploadInProgressTitle => 'Subida en Progreso';

  @override
  String get uploadInProgressBody =>
      'Hay una subida en progreso. ¿Cancelar y volver atrás?';

  @override
  String get selected => 'seleccionado(s)';

  @override
  String get syllabusUploadToggle => 'Subir como plan de estudios';

  @override
  String get syllabusUploadToggleHint =>
      'Marca esta carga como un plan de estudios para la generación estructurada de temas';

  @override
  String get backupProvider => 'Proveedor de Respaldo';

  @override
  String get backupProviderDescription =>
      'Proveedor de IA secundario opcional para conmutación por error';

  @override
  String get backupApiKey => 'Clave API de Respaldo';

  @override
  String get backupApiKeyDescription =>
      'Clave API para el proveedor de respaldo';

  @override
  String get backupBaseUrl => 'URL Base de Respaldo';

  @override
  String get backupModel => 'Modelo de Respaldo';

  @override
  String get backupModelHint => 'p. ej., gpt-4o-mini';

  @override
  String get backupModelDescription =>
      'ID del modelo para el proveedor de respaldo';

  @override
  String providerTimedOut(String providerName) {
    return '$providerName superó el tiempo de espera. Intente de nuevo.';
  }

  @override
  String providerConnectionFailed(String providerName) {
    return 'Conexión a $providerName fallida. Verifique su red y clave API.';
  }

  @override
  String get responseInterrupted => 'Respuesta interrumpida. Intente de nuevo.';
}
