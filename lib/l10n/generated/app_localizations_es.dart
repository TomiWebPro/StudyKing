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
  String get yourStudySchedule => 'Su Horario de Estudio';

  @override
  String topicLabel(int number) {
    return 'Tema $number';
  }

  @override
  String sessionDurationMinutes(int minutes) {
    return 'Sesión de $minutes min';
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
  String get accuracy => 'Precisión';

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
  String get learningGoalHint => 'p. ej., Exámenes Finales, Certificaciones';

  @override
  String get preferredStudyTime => 'Horario de Estudio Preferido';

  @override
  String get preferredStudyTimeHint => 'p. ej., Tarde (6-9 PM)';

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
  String get retry => 'Reintentar';

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
  String get uploadOrPasteData => 'Cargue o pegue datos para visualizar';

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
  String get difficultyMedium => 'Medio';

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
  String get instrumentation => 'Instrumentación';

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
    return '$count intentos';
  }

  @override
  String get weakAreasAccuracy => 'Áreas por mejorar (Precisión < 60%)';

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
    return '$count activas';
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
    return 'Tokens: $count (\$$cost)';
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
    return 'Ha tenido $count días de bajo cumplimiento del plan. ¿Desea ajustar su plan de estudio?';
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
      'El tiempo de lección terminó. Haga clic en \'Finalizar Lección\' para terminar.';

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
    return 'Disposición Prom.: $percent';
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
  String get readiness => 'Disposición';

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
  String get labelJson => 'JSON';

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
    return '$pace% ritmo';
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
  String get roadmapGoalHint => 'ej., Quiero aprender Física IB en 180 días';

  @override
  String get generateRoadmap => 'Generar Roadmap';

  @override
  String get myRoadmaps => 'Mis Roadmaps';

  @override
  String get milestones => 'Hitos';

  @override
  String get milestone => 'Hito';

  @override
  String get targetCompletion => 'Finalización Prevista';

  @override
  String get noRoadmapsYet => 'Aún no hay roadmaps';

  @override
  String get roadmapOverview => 'Resumen del Roadmap';

  @override
  String get timeline => 'Cronología';

  @override
  String completionOfValue(double value) {
    return '$value% Completado';
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
    return '¡Los $count pasos identificados correctamente!';
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
  String get focusMode => 'Modo de Enfoque';

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
  String get breakTime => 'Descanso';

  @override
  String sessionCompleted(int minutes) {
    return 'Sesión completada: ${minutes}m';
  }

  @override
  String get focus => 'Enfoque';

  @override
  String focusForMinutes(int minutes) {
    return 'Enfóquese por $minutes minutos';
  }

  @override
  String get focusTime => 'Tiempo de Enfoque';

  @override
  String get timerRemaining => 'restante';

  @override
  String get timerPaused => 'PAUSADO';

  @override
  String get timerDone => 'TERMINADO';

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
  String get badgeDailyScholarDesc => '¡Estudió constantemente hoy!';

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
  String notifBodyRevision(int days, String topicName) {
    return 'Han pasado $days días desde que practicó \"$topicName\".';
  }

  @override
  String get notifTitleTakeBreak => 'Tome un Descanso';

  @override
  String notifBodyOverwork(String hours) {
    return 'Ha estudiado $hours horas hoy. ¡Recuerde descansar!';
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
  String notifBodyLessonReminder(String lessonTitle, String time) {
    return 'Su lección \"$lessonTitle\" comienza a las $time.';
  }

  @override
  String get notifTitleTopicsNeedAttention => 'Temas que Requieren Atención';

  @override
  String notifBodyLowMastery(String topics) {
    return 'Bajo dominio detectado en: $topics';
  }

  @override
  String get notifTitleBadgeUnlocked => '¡Insignia Desbloqueada!';

  @override
  String notifBodyBadgeUnlocked(String badgeName, String badgeDescription) {
    return '¡Obtuvo la insignia \"$badgeName\": $badgeDescription';
  }

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
    return 'Tiene $count tema(s) que necesitan mejorar. Concéntrese en fortalecer estas áreas.';
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
    return 'Bloquea $count tema(s) dependiente(s)';
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
    return '¿Ha tenido $days días consecutivos de bajo cumplimiento. Le gustaría regenerar su plan con objetivos ajustados?';
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
    return '+$minutes min';
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
    return '$count tokens';
  }

  @override
  String usageRecordFormat(String date, String cost, String costPerToken) {
    return '$date: $cost, costo/token: $costPerToken';
  }

  @override
  String usageSummary(String totalCost, String totalTokens, String avgCost) {
    return 'Uso: $totalCost sobre $totalTokens tokens, promedio: $avgCost por cada 1k tokens';
  }
}
