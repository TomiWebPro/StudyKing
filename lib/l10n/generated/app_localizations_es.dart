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
      other: '${count}min',
      one: '1min',
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
  String get focusOnMistakes => 'Concéntrate en tus errores';

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
  String get noWeakAreasFound => 'No se encontraron áreas débiles. ¡Sigue así!';

  @override
  String get noWeakAreasQuestions =>
      'No hay preguntas disponibles para tus áreas débiles.';

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
  String get accuracy => 'Exactitud';

  @override
  String get practiceAgain => 'Practicar de Nuevo';

  @override
  String get allCaughtUp => '¡Todo al día!';

  @override
  String get noReviewsScheduled => 'No hay repasos programados.';

  @override
  String dueQuestionsCount(int count) {
    return '$count pendientes';
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
  String get learningGoalHint => 'ej., Exámenes Finales, Certificaciones';

  @override
  String get preferredStudyTime => 'Horario de Estudio Preferido';

  @override
  String get preferredStudyTimeHint => 'ej., Tarde (6-9 PM)';

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
  String get medium => 'Mediano';

  @override
  String get large => 'Grande';

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
    return '$count segundos';
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
    return '$count minutos';
  }

  @override
  String get studyAnalytics => 'Analíticas de Estudio';

  @override
  String get totalStudySessions => 'Sesiones de Estudio Totales';

  @override
  String sessionsCount(int count) {
    return '$count sesiones';
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
  String get ok => 'OK';

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
  String get signOutConfirmation => '¿Está seguro de que desea cerrar sesión?';

  @override
  String get sessionsLabel => 'Sesiones';

  @override
  String get questionsLabel => 'Preguntas';

  @override
  String get mySubjects => 'Mis Materias';

  @override
  String get addNewSubject => 'Agregar Nueva Materia';

  @override
  String get subjectName => 'Nombre de la Materia';

  @override
  String get subjectNameHint => 'ej., Física';

  @override
  String get subjectCodeOptional => 'Código de Materia (Opcional)';

  @override
  String get subjectCodeHint => 'ej., IB-FIS';

  @override
  String get themeColor => 'Color del Tema';

  @override
  String get subjectColor => 'Color de la Materia';

  @override
  String get examDateOptional => 'Fecha de Examen (Opcional)';

  @override
  String get selectDate => 'Seleccionar fecha';

  @override
  String get createSubject => 'Crear Materia';

  @override
  String get subjectCreatedSuccessfully => 'Materia creada exitosamente';

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
  String get teacherHint => 'ej., Dr. John Smith';

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
    return 'Practica preguntas de $subjectName';
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
  String get studySessionTracker => 'Rastreador de Sesiones de Estudio';

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
  String get renderedGraph => 'Gráfico Renderizado';

  @override
  String get noDataUploaded => 'No hay datos subidos';

  @override
  String get uploadOrPasteData => 'Sube o pega datos para visualizar';

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
    return 'Tipo de gráfico cambiado a $graphType';
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
      'Considere usar un Gráfico Circular para conjuntos pequeños de datos';

  @override
  String get considerUsingBarChart =>
      'Considere usar un Gráfico de Barras para conjuntos grandes de datos';

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
  String get graphTypeDetectionError =>
      'La detección del tipo de gráfico falló';

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
    return '$percent% Completado: $completed/$total preguntas generadas';
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
  String difficultyLabel(String level) {
    return 'Dificultad: $level';
  }

  @override
  String get easy => 'Fácil';

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
  String get clearAllDrawings => 'Borrar todos los dibujos';

  @override
  String get canvasIsEmpty => 'El lienzo está vacío';

  @override
  String drawingWithStrokes(int count, String plural) {
    return 'Dibujando con $count trazo$plural';
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
      'Dibuje su respuesta en el lienzo usando su dedo o lápiz';

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
    return '$count preguntas';
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
  String get noTopicsYetAddSome => 'No hay temas todavía? ¡agrega algunos!';

  @override
  String get noLessonsUsePlanner =>
      'No hay lecciones? ¡usa el Planificador para generar!';

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
    return '$count preguntas';
  }

  @override
  String minutesCountMetric(int count) {
    return '$count min';
  }

  @override
  String get atRiskTopics => 'Temas en Riesgo';

  @override
  String get noAtRiskTopics => 'Sin temas en riesgo. ¡Sigue así!';

  @override
  String accuracyLabel(String percent) {
    return 'Precisión: $percent';
  }

  @override
  String get readyToAdvance => 'Listo para Avanzar';

  @override
  String get keepPracticingToUnlock =>
      '¡Sigue practicando para desbloquear temas avanzados!';

  @override
  String get masteryOverview => 'Resumen de Dominio';

  @override
  String get totalTopicsLabel => 'Total de Temas';

  @override
  String get masteredLabel => 'Dominado';

  @override
  String get weakLabel => 'Débil';

  @override
  String avgAccuracyLabel(String percent) {
    return 'Precisión Prom.: $percent';
  }

  @override
  String avgReadinessLabel(String percent) {
    return 'Disposición Prom.: $percent';
  }

  @override
  String courseSessionLabel(String course, int number) {
    return '$course - Sesión $number';
  }

  @override
  String get quickGuideWelcomeMessage =>
      '¡Hola! Soy la Guía Rápida de StudyKing. ¡Pregúntame lo que sea sobre tus estudios!';

  @override
  String get suggestedPromptExplain => 'Explica la fotosíntesis';

  @override
  String get suggestedPromptQuiz => 'Examíname de historia';

  @override
  String get suggestedPromptMath => 'Ayuda con problemas de mates';

  @override
  String get quickGuideHelpContent =>
      'Guía Rápida es tu asistente de estudio con IA. Puedes:\n\n• Hacer preguntas sobre cualquier materia\n• Solicitar explicaciones de conceptos\n• Obtener ayuda con problemas de práctica\n\n¡Solo escribe tu pregunta y presiona enviar!';

  @override
  String semanticsYouSaid(String message) {
    return 'Tú dijiste: $message';
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
      '¡Claro! Puedo ayudar a explicar conceptos. ¿Qué tema te gustaría que explique?';

  @override
  String get fallbackQuizResponse =>
      '¡Puedo ayudar con preguntas! Pregunta lo que quieras y haré lo mejor posible.';

  @override
  String get fallbackMathResponse =>
      '¡Estaré encantado de ayudar con matemáticas! ¿Qué problema o tema específico te gustaría trabajar?';

  @override
  String get fallbackGeneralResponse =>
      '¡Esa es una pregunta interesante! Déjame ayudarte a entenderla mejor.';

  @override
  String get aboutApplicationName => 'StudyKing';

  @override
  String get aboutVersion => 'v0.1.0';

  @override
  String get aboutLegalese => '© 2026 StudyKing.';

  @override
  String get unknownModelId => 'unknown-model';

  @override
  String get unknownProviderName => 'Desconocido';

  @override
  String get examDateOptionalLabel => 'Fecha de Examen (Opcional):';

  @override
  String get lessonFallbackTitle => 'Lección';

  @override
  String errorWithMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get questionTypeDefault => 'Pregunta';

  @override
  String get durationSeparator => ' ';
}
