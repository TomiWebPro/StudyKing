// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'StudyKing';

  @override
  String get subjects => 'Subjects';

  @override
  String get practice => 'Practice';

  @override
  String get settings => 'Settings';

  @override
  String get studyPlanner => 'Study Planner';

  @override
  String get createStudyPlan => 'Create Study Plan';

  @override
  String get courseSubject => 'Course/Subject';

  @override
  String get courseHint => 'e.g., IB Physics';

  @override
  String get days => 'Days';

  @override
  String get hoursPerDay => 'Hours/Day';

  @override
  String get generatePlan => 'Generate Plan';

  @override
  String get generating => 'Generating...';

  @override
  String get yourStudySchedule => 'Your Study Schedule';

  @override
  String topicLabel(int number) {
    return 'Topic $number';
  }

  @override
  String sessionDurationMinutes(int minutes) {
    return '$minutes min session';
  }

  @override
  String get fillAllFieldsCorrectly => 'Please fill in all fields correctly';

  @override
  String generatedPlanOverDays(String course, int days, int totalHours) {
    return 'Generated plan for $course over $days days ($totalHours total hours)';
  }

  @override
  String overDaysPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: 'no days',
    );
    return 'over $_temp0';
  }

  @override
  String totalHoursPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count total hours',
      one: '1 total hour',
    );
    return '$_temp0';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get unknown => 'Unknown';

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
  String get practiceMode => 'Practice Mode';

  @override
  String get practiceOptions => 'Practice Options';

  @override
  String get noSubjects => 'No Subjects';

  @override
  String get noPracticeSessionsYet => 'No Practice Sessions Yet';

  @override
  String get addSubjectsAndQuestionsToStartPracticing =>
      'Add subjects and questions to start practicing';

  @override
  String get addSubjectsFromSubjectsTab => 'Add subjects from the Subjects tab';

  @override
  String get addSubject => 'Add Subject';

  @override
  String get practiceModes => 'Practice Modes';

  @override
  String get quickPractice => 'Quick Practice';

  @override
  String randomQuestions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count random questions',
      one: '1 random question',
    );
    return '$_temp0';
  }

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get spacedRepetition => 'Spaced Repetition';

  @override
  String get topicFocus => 'Topic Focus';

  @override
  String get practiceSpecificTopics => 'Practice specific topics';

  @override
  String get weakAreas => 'Weak Areas';

  @override
  String get focusOnMistakes => 'Focus on mistakes';

  @override
  String get yourSubjects => 'Your Subjects';

  @override
  String get readyForPractice => 'Ready for practice';

  @override
  String get practiceAvailable => 'Practice available';

  @override
  String get selectSubject => 'Select Subject';

  @override
  String get practiceModeTitle => 'Practice Mode';

  @override
  String get autoSelect => 'Auto Select';

  @override
  String get aiPicksOptimalQuestions => 'AI picks optimal questions';

  @override
  String get chooseSubject => 'Choose Subject';

  @override
  String get noCode => 'No code';

  @override
  String get topicSelectionComingSoon => 'Topic selection coming soon!';

  @override
  String get noWeakAreasFound => 'No weak areas found. Keep up the great work!';

  @override
  String get noWeakAreasQuestions =>
      'No questions available for your weak areas.';

  @override
  String get noQuestionsAvailable => 'No Questions Available';

  @override
  String get noQuestionsForSelectedSubject =>
      'There are no questions for the selected subject/topic. Start creating questions!';

  @override
  String get time => 'Time';

  @override
  String get score => 'Score';

  @override
  String get correct => 'Correct';

  @override
  String get yourAnswer => 'Your Answer';

  @override
  String yourAnswerCharacters(int count) {
    return 'Your Answer ($count characters)';
  }

  @override
  String get submitAnswer => 'Submit Answer';

  @override
  String get correctFeedback => 'Correct!';

  @override
  String get incorrectFeedback => 'Incorrect';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get sessionResults => 'Session Results';

  @override
  String get practiceComplete => 'Practice Complete!';

  @override
  String get totalQuestions => 'Total Questions';

  @override
  String get correctAnswers => 'Correct Answers';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get examConfiguration => 'Exam Configuration';

  @override
  String get startExam => 'Start Exam';

  @override
  String get examDuration => 'Exam Duration';

  @override
  String get numberOfQuestions => 'Number of Questions';

  @override
  String get incorrectLabel => 'Incorrect';

  @override
  String get skippedLabel => 'Skipped';

  @override
  String get examAutoSubmitted => 'Exam was auto-submitted when time ran out.';

  @override
  String get topicBreakdown => 'Topic Breakdown';

  @override
  String startingPractice(String mode) {
    return 'Starting $mode...';
  }

  @override
  String get backToPractice => 'Back to Practice';

  @override
  String get swipeToDelete => 'Swipe to delete';

  @override
  String get valueMustBePositive => 'Value must be positive';

  @override
  String get correctExceedsQuestions =>
      'Correct answers cannot exceed total questions';

  @override
  String get practiceAgain => 'Practice Again';

  @override
  String get allCaughtUp => 'All caught up!';

  @override
  String get noReviewsScheduled => 'No reviews scheduled.';

  @override
  String dueQuestionsCount(int count) {
    return '$count due';
  }

  @override
  String get reviewDueQuestions => 'Review due questions';

  @override
  String get selectTopic => 'Select Topic';

  @override
  String get noTopicsAvailable => 'No topics available';

  @override
  String get questionsDueForReview => 'questions due for review';

  @override
  String get spacedRepetitionMode => 'Spaced Repetition';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorPurple => 'Purple';

  @override
  String get colorPink => 'Pink';

  @override
  String get colorCyan => 'Cyan';

  @override
  String get colorAmber => 'Amber';

  @override
  String get colorDeepOrange => 'Deep Orange';

  @override
  String get colorBlueGrey => 'Blue Grey';

  @override
  String get profile => 'Profile';

  @override
  String get nameIsRequired => 'Name is required';

  @override
  String get studentIdMustBeNumeric => 'Student ID must be numeric';

  @override
  String get profileSavedSuccessfully => 'Profile saved successfully';

  @override
  String errorSavingProfile(String error) {
    return 'Error saving profile: $error';
  }

  @override
  String get chooseAvatar => 'Choose Avatar';

  @override
  String get cancel => 'Cancel';

  @override
  String selectAvatar(String iconKey) {
    return 'Select avatar $iconKey';
  }

  @override
  String get fullName => 'Full Name';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get studentIdOptional => 'Student ID (Optional)';

  @override
  String get yourStudentIdNumber => 'Your student ID number';

  @override
  String get learningGoal => 'Learning Goal';

  @override
  String get learningGoalHint => 'e.g., Final Exams, Certifications';

  @override
  String get preferredStudyTime => 'Preferred Study Time';

  @override
  String get preferredStudyTimeHint => 'e.g., Evening (6-9 PM)';

  @override
  String get accountInformation => 'Account Information';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Spanish';

  @override
  String get notifications => 'Notifications';

  @override
  String get deleteAccountWarning =>
      'Deleting your account will permanently remove all study data';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirmation =>
      'Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your study data.';

  @override
  String get save => 'Save';

  @override
  String get userManagement => 'User Management';

  @override
  String get currentUser => 'Current User';

  @override
  String get manageYourProfile => 'Manage your profile';

  @override
  String get quickAccess => 'Quick Access';

  @override
  String get quickGuide => 'Quick Guide';

  @override
  String get aiPoweredStudyAssistant => 'AI-powered study assistant';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get fontSize => 'Font Size';

  @override
  String get small => 'Small';

  @override
  String get fontSizeMedium => 'Medium';

  @override
  String get large => 'Large';

  @override
  String get extraLarge => 'Extra Large';

  @override
  String get aiConfiguration => 'AI Configuration';

  @override
  String get apiKeys => 'API Keys';

  @override
  String get configured => 'Configured';

  @override
  String get notConfigured => 'Not configured';

  @override
  String get aiModel => 'AI Model';

  @override
  String get selectModelFromApi => 'Select a model from API';

  @override
  String get requestTimeout => 'Request Timeout';

  @override
  String secondsValue(int count) {
    return '$count seconds';
  }

  @override
  String get studyPreferences => 'Study Preferences';

  @override
  String get studyReminders => 'Study Reminders';

  @override
  String get enableNotificationAlerts => 'Enable notification alerts';

  @override
  String get sessionDuration => 'Session Duration';

  @override
  String minutesValue(int count) {
    return '$count minutes';
  }

  @override
  String get studyAnalytics => 'Study Analytics';

  @override
  String get totalStudySessions => 'Total Study Sessions';

  @override
  String sessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String get totalStudyTime => 'Total Study Time';

  @override
  String get aboutSection => 'About';

  @override
  String get aboutStudyKing => 'About StudyKing';

  @override
  String get versionInfo => 'Version 0.1.0';

  @override
  String get signOut => 'Sign Out';

  @override
  String get apiKeyRequired => 'API Key Required';

  @override
  String get pleaseConfigureApiKey => 'Please configure your API key first.';

  @override
  String get ok => 'OK';

  @override
  String get unableToLoadModels => 'Unable to load models right now.';

  @override
  String get searchModels => 'Search models';

  @override
  String get modelRequestTimedOut =>
      'Model request timed out. Please try again.';

  @override
  String get unableToLoadModelsTryAgain =>
      'Unable to load models. Please try again.';

  @override
  String get retry => 'Retry';

  @override
  String get signOutConfirmation => 'Are you sure you want to sign out?';

  @override
  String get sessionsLabel => 'Sessions';

  @override
  String get questionsLabel => 'Questions';

  @override
  String get mySubjects => 'My Subjects';

  @override
  String get addNewSubject => 'Add New Subject';

  @override
  String get subjectName => 'Subject Name';

  @override
  String get subjectNameHint => 'e.g., Physics';

  @override
  String get subjectCodeOptional => 'Subject Code (Optional)';

  @override
  String get subjectCodeHint => 'e.g., IB-PHYS';

  @override
  String get themeColor => 'Theme Color';

  @override
  String get subjectColor => 'Subject Color';

  @override
  String get examDateOptional => 'Exam Date (Optional)';

  @override
  String get selectDate => 'Select date';

  @override
  String get createSubject => 'Create Subject';

  @override
  String get subjectCreatedSuccessfully => 'Subject created successfully';

  @override
  String errorCreatingSubject(String error) {
    return 'Error creating subject: $error';
  }

  @override
  String get pleaseEnterSubjectName => 'Please enter a subject name';

  @override
  String get descriptionOptional => 'Description (Optional)';

  @override
  String get descriptionHint => 'Brief description of the subject';

  @override
  String get teacherOptional => 'Teacher (Optional)';

  @override
  String get teacherHint => 'e.g., Dr. John Smith';

  @override
  String get syllabusScopeOptional => 'Syllabus/Scope (Optional)';

  @override
  String get syllabusHint => 'Brief overview of the syllabus';

  @override
  String get teacherNameHint => 'Enter teacher name';

  @override
  String get syllabusDescriptionHint => 'Enter syllabus description';

  @override
  String get noSubjectsYet => 'No subjects yet';

  @override
  String get addFirstSubject => 'Add your first subject to begin studying';

  @override
  String get practiceSessions => 'Practice sessions';

  @override
  String get startPractice => 'Start Practice';

  @override
  String get noPracticeHistory => 'No practice history';

  @override
  String get viewAllSessions => 'View All Sessions';

  @override
  String get editSubject => 'Edit Subject';

  @override
  String get deleteSubject => 'Delete Subject';

  @override
  String get deleteSubjectConfirmation =>
      'Are you sure you want to delete this subject? This will also delete all associated lessons and questions.';

  @override
  String get sessionDetails => 'Session Details';

  @override
  String get close => 'Close';

  @override
  String get date => 'Date';

  @override
  String get duration => 'Duration';

  @override
  String get questions => 'Questions';

  @override
  String get lessonsTab => 'Lessons';

  @override
  String get practiceTab => 'Practice';

  @override
  String get historyTab => 'History';

  @override
  String get statsTab => 'Stats';

  @override
  String get noLessonsYet => 'No lessons yet';

  @override
  String get startLearningByCreatingTopics =>
      'Start learning by creating topics and questions';

  @override
  String get addTopic => 'Add Topic';

  @override
  String get lesson => 'Lesson';

  @override
  String questionsCount(int count) {
    return 'Questions: $count';
  }

  @override
  String practiceQuestionsFrom(String subjectName) {
    return 'Practice questions from $subjectName';
  }

  @override
  String get practiceProgress => 'Practice Progress';

  @override
  String get overallScore => 'Overall Score';

  @override
  String get keepPracticing => 'Keep practicing to improve your score!';

  @override
  String sessionNumber(int number) {
    return 'Session $number';
  }

  @override
  String get selectFormat => 'Select question format:';

  @override
  String get studySessionTracker => 'Study Session Tracker';

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String get sessionComplete => 'Session Complete';

  @override
  String get howManyQuestions => 'How many questions did you answer?';

  @override
  String get questionsAnswered => 'Questions Answered';

  @override
  String get skip => 'Skip';

  @override
  String get graphRenderer => 'Graph Renderer';

  @override
  String get refreshGraph => 'Refresh graph';

  @override
  String get validateGraphType => 'Validate graph type';

  @override
  String get uploadData => 'Upload Data';

  @override
  String get uploadDataFile => 'Upload Data File';

  @override
  String get orPasteDataDirectly => 'Or paste data directly:';

  @override
  String get pasteDataHint => 'Paste comma-separated data...';

  @override
  String get graphTypeDetection => 'Graph Type Detection';

  @override
  String get autoDetectFromData => 'Auto-detect from data:';

  @override
  String get lineGraph => 'Line Graph';

  @override
  String get barChart => 'Bar Chart';

  @override
  String get scatterPlot => 'Scatter Plot';

  @override
  String get pieChart => 'Pie Chart';

  @override
  String get llmValidation => 'LLM Validation';

  @override
  String get useLlmToValidateGraph => 'Use LLM to validate graph:';

  @override
  String get describeWhatYouSee => 'Describe what you see in the graph...';

  @override
  String get validateWithLlm => 'Validate with LLM';

  @override
  String get validating => 'Validating...';

  @override
  String get renderedGraph => 'Rendered Graph';

  @override
  String get noDataUploaded => 'No data uploaded';

  @override
  String get uploadOrPasteData => 'Upload or paste data to visualize';

  @override
  String get selectGraphType => 'Select a graph type to visualize';

  @override
  String graphVisualization(String graphType) {
    return '$graphType Visualization';
  }

  @override
  String dataPointsCount(int count) {
    return 'Data points: $count';
  }

  @override
  String graphTypeSetTo(String graphType) {
    return 'Graph type set to $graphType';
  }

  @override
  String get uploadDataFileDialog => 'Upload Data File';

  @override
  String get fileUploadImplemented =>
      'File upload functionality would be implemented here.';

  @override
  String get graphValidation => 'Graph Validation';

  @override
  String typeLabel(String graphType) {
    return 'Type: $graphType';
  }

  @override
  String get considerUsingPieChart =>
      'Consider using Pie Chart for small datasets';

  @override
  String get considerUsingBarChart =>
      'Consider using Bar Chart for larger datasets';

  @override
  String get graphTypeMatchesData => 'Graph type matches data structure';

  @override
  String get graphRefreshed => 'Graph refreshed';

  @override
  String get pleaseSelectGraphType => 'Please select a graph type first';

  @override
  String get validationComplete => 'Validation complete';

  @override
  String validationFailed(String error) {
    return 'Validation failed: $error';
  }

  @override
  String get graphTypeDetectionError => 'Graph type detection failed';

  @override
  String get imageCaptured =>
      'Image captured. You can add notes in the content field above.';

  @override
  String cameraError(String error) {
    return 'Camera error: $error';
  }

  @override
  String get lessonScheduler => 'Lesson Scheduler';

  @override
  String get upcomingLessons => 'Upcoming Lessons';

  @override
  String get selectSubjectLabel => 'Select Subject';

  @override
  String get generateQuestionTypes => 'Generate Question Types';

  @override
  String get lessonProgress => 'Lesson Progress';

  @override
  String percentComplete(int percent, int completed, int total) {
    return '$percent% Complete: $completed/$total questions generated';
  }

  @override
  String get scheduleLesson => 'Schedule Lesson';

  @override
  String get selectCalendarDate => 'Select calendar date for lesson';

  @override
  String get done => 'Done';

  @override
  String get createNewLesson => 'Create New Lesson';

  @override
  String get editExistingLesson => 'Edit Existing Lesson';

  @override
  String get mcq => 'MCQ';

  @override
  String get inputLabel => 'Input';

  @override
  String get graphLabel => 'Graph';

  @override
  String get quickGuideHelp => 'Quick Guide help';

  @override
  String get help => 'Help';

  @override
  String get quickGuideIsThinking => 'Quick Guide is thinking...';

  @override
  String get suggestedPrompts => 'Suggested prompts';

  @override
  String get askAnything => 'Ask anything...';

  @override
  String get sendMessage => 'Send message';

  @override
  String get messageInputHint => 'Type your question here';

  @override
  String get quickGuideHelpTitle => 'Quick Guide Help';

  @override
  String get gotIt => 'Got it';

  @override
  String get addAnswerBeforeSubmitting => 'Add an answer before submitting.';

  @override
  String get nextQuestion => 'Next Question';

  @override
  String get typeYourAnswerHere => 'Type your answer here...';

  @override
  String get writeYourEssayAnswer => 'Write your essay answer...';

  @override
  String get questionTypeNotSupported =>
      'This question type is not yet supported in this view.';

  @override
  String get multipleChoice => 'Multiple Choice';

  @override
  String get multipleSelect => 'Multiple Select';

  @override
  String get textAnswer => 'Text Answer';

  @override
  String get math => 'Math';

  @override
  String get essay => 'Essay';

  @override
  String get diagram => 'Diagram';

  @override
  String get graphQuestion => 'Graph';

  @override
  String get stepByStep => 'Step-by-Step';

  @override
  String difficultyLabel(String level) {
    return 'Difficulty: $level';
  }

  @override
  String get easy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get hard => 'Hard';

  @override
  String get selectAsAnswer => 'Select as answer';

  @override
  String get selectedRightOption => 'Selected right option';

  @override
  String get tryAgain => 'Try again';

  @override
  String get drawHere => 'Draw here...';

  @override
  String get undoLastStroke => 'Undo last stroke';

  @override
  String get clearAllDrawings => 'Clear all drawings';

  @override
  String get canvasIsEmpty => 'Canvas is empty';

  @override
  String drawingWithStrokes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Drawing with $count strokes',
      one: 'Drawing with 1 stroke',
    );
    return '$_temp0';
  }

  @override
  String get saveDrawing => 'Save Drawing';

  @override
  String get drawingSaved => 'Drawing saved.';

  @override
  String get failedToSaveDrawing => 'Failed to save drawing. Retry.';

  @override
  String get drawingCanvas => 'Drawing canvas';

  @override
  String get drawYourAnswer =>
      'Draw your answer on the canvas using your finger or stylus';

  @override
  String get apiConfiguration => 'API Configuration';

  @override
  String get configureApiKeys => 'Configure API Keys';

  @override
  String get configureApiKeysDescription =>
      'Enter your OpenRouter API credentials below. These are used to power the AI features.';

  @override
  String get openRouterApiKey => 'OpenRouter API Key';

  @override
  String get apiBaseUrl => 'API Base URL';

  @override
  String get apiKeyHint => 'sk-or-v1-...';

  @override
  String get apiBaseUrlHint => 'https://openrouter.ai/api/v1';

  @override
  String get apiKeyDescription =>
      'Required for LLM content generation. Get your key from https://openrouter.ai/keys';

  @override
  String get apiBaseUrlDescription => 'The endpoint URL for the AI service';

  @override
  String get saveApiKeys => 'Save API Keys';

  @override
  String get apiKeyCannotBeEmpty => 'API key cannot be empty';

  @override
  String get apiKeysSavedSuccessfully => 'API keys saved successfully';

  @override
  String get unableToSaveApiConfig =>
      'Unable to save API configuration. Please try again.';

  @override
  String get currentSession => 'Current Session';

  @override
  String get noActiveSession => 'No Active Session';

  @override
  String get tapStartToBegin => 'Tap start to begin tracking';

  @override
  String get recentSessions => 'Recent Sessions';

  @override
  String ofLabel(int count1, int count2) {
    return '$count1 of $count2';
  }

  @override
  String get viewAll => 'View All';

  @override
  String get noSessionsYet => 'No sessions yet';

  @override
  String get startYourFirstSession => 'Start your first session!';

  @override
  String get filterByDate => 'Filter by Date';

  @override
  String get filterBySubject => 'Filter by Subject';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get clearFilterLabel => 'Clear';

  @override
  String get totalTime => 'Total Time';

  @override
  String get average => 'Average';

  @override
  String get noSessionsFoundForFilters =>
      'No sessions found for selected filters';

  @override
  String get tryAdjustingFilters => 'Try adjusting your filters';

  @override
  String get startStudyingToTrack => 'Start studying to track your progress';

  @override
  String get sessionDeleted => 'Session deleted';

  @override
  String get undo => 'Undo';

  @override
  String failedToDeleteSession(String error) {
    return 'Failed to delete session: $error';
  }

  @override
  String get deleteSession => 'Delete Session';

  @override
  String get deleteSessionConfirmation =>
      'Are you sure you want to delete this session?';

  @override
  String get noQuestions => 'No questions';

  @override
  String questionsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '1 question',
    );
    return '$_temp0';
  }

  @override
  String correctOf(int correct, int total) {
    return 'Correct: $correct/$total';
  }

  @override
  String get selectDateToFilter => 'Select a date to filter sessions';

  @override
  String get filterBySubjectTitle => 'Filter by Subject';

  @override
  String get sessionHistory => 'Session History';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get studyDashboard => 'Study Dashboard';

  @override
  String get studyTime => 'Study Time';

  @override
  String get planAdherence => 'Plan Adherence';

  @override
  String get masteryOverview => 'Mastery Overview';

  @override
  String get topicPerformance => 'Topic Performance';

  @override
  String get achievements => 'Achievements';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get instrumentation => 'Instrumentation';

  @override
  String get overall => 'Overall';

  @override
  String get thisWeek => 'This Week';

  @override
  String get totalTopics => 'Total Topics';

  @override
  String get mastered => 'Mastered';

  @override
  String get topics => 'Topics';

  @override
  String get practiceAllWeakAreas => 'Practice All Weak Areas';

  @override
  String get practiceThisTopic => 'Practice this topic';

  @override
  String get noTopicDataYet =>
      'No topic data yet. Start studying to see your progress!';

  @override
  String get masteryLevelNovice => 'Novice';

  @override
  String get masteryLevelBrowsing => 'Browsing';

  @override
  String get masteryLevelDeveloping => 'Developing';

  @override
  String get masteryLevelProficient => 'Proficient';

  @override
  String get masteryLevelExpert => 'Expert';

  @override
  String progressCsvGenerated(int length) {
    return 'Progress CSV generated ($length chars)';
  }

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get instrumentationDataExported => 'Instrumentation data exported';

  @override
  String attemptsCount(int count) {
    return '$count attempts';
  }

  @override
  String get weakAreasAccuracy => 'Weak Areas (Accuracy < 60%)';

  @override
  String get uploadContent => 'Upload Content';

  @override
  String get addStudyMaterials => 'Add study materials to your library';

  @override
  String get titleRequired => 'Title *';

  @override
  String get titleHint => 'e.g. Chapter 5 Notes';

  @override
  String get subjectOptional => 'Subject (optional)';

  @override
  String get none => 'None';

  @override
  String get pasteText => 'Paste Text';

  @override
  String get urlLink => 'URL / Link';

  @override
  String get urlRequired => 'URL *';

  @override
  String get urlHint => 'https://example.com/notes';

  @override
  String get contentRequired => 'Content *';

  @override
  String get contentHint => 'Paste your study material here...';

  @override
  String get uploading => 'Uploading...';

  @override
  String get fillRequiredFields => 'Please fill in all required fields.';

  @override
  String get contentUploadedSuccessfully => 'Content uploaded successfully!';

  @override
  String uploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get planSummary => 'Plan Summary';

  @override
  String get total => 'Total';

  @override
  String get newTopics => 'new';

  @override
  String get reviewTopics => 'review';

  @override
  String get coverage => 'Coverage';

  @override
  String focusLabel(String areas) {
    return 'Focus: $areas';
  }

  @override
  String get studyDay => 'Study Day';

  @override
  String get rest => 'Rest';

  @override
  String get startTutoring => 'Start tutoring';

  @override
  String questionsAndMinutes(int questions, int minutes) {
    return '${questions}Q · ${minutes}min';
  }

  @override
  String topicQuestionsAndMinutes(int questions, int minutes) {
    return '${questions}Q · ${minutes}min';
  }

  @override
  String get failedToGeneratePlan => 'Failed to generate plan';

  @override
  String get llmTaskManager => 'LLM Task Manager';

  @override
  String activeCount(int count) {
    return '$count active';
  }

  @override
  String get noLlmTasksYet => 'No LLM tasks yet';

  @override
  String modelLabel(String modelId) {
    return 'Model: $modelId';
  }

  @override
  String startedLabel(String time) {
    return 'Started: $time';
  }

  @override
  String endedLabel(String time) {
    return 'Ended: $time';
  }

  @override
  String tokensAndCost(int count, String cost) {
    return 'Tokens: $count (\$$cost)';
  }

  @override
  String get cancelTask => 'Cancel';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get testing => 'Testing...';

  @override
  String connectionSuccessful(int latency) {
    return 'Connection successful! Latency: ${latency}ms';
  }

  @override
  String connectionFailed(String error) {
    return 'Connection failed: $error';
  }

  @override
  String sessionHistoryCsvGenerated(int length) {
    return 'Session history CSV generated ($length chars)';
  }

  @override
  String dailyPlanTarget(int questions, int minutes) {
    return 'Today: ${questions}Q, ${minutes}min';
  }

  @override
  String get noPlanForToday => 'No plan for today';

  @override
  String planAdjustmentSuggested(int count) {
    return 'You\'ve had $count days of low plan adherence. Would you like to adjust your study plan?';
  }

  @override
  String get adjustPlan => 'Adjust Plan';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get voiceInput => 'Voice Input';

  @override
  String get captureImage => 'Capture Image';

  @override
  String get camera => 'Camera';

  @override
  String errorSavingSubject(String error) {
    return 'Error saving subject: $error';
  }

  @override
  String failedToSaveSession(String error) {
    return 'Failed to save session: $error';
  }

  @override
  String get avgSession => 'Avg Session';

  @override
  String get totalSessionsLabel => 'Total Sessions';

  @override
  String get currentStreakLabel => 'Current Streak';

  @override
  String get sessionsByDayOfWeek => 'Sessions by Day of Week';

  @override
  String get performanceMetrics => 'Performance Metrics';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get noTopicsYetAddSome => 'No topics yet - add some!';

  @override
  String get noLessonsUsePlanner => 'No lessons - use Planner to generate!';

  @override
  String get mentor => 'Mentor';

  @override
  String get startAiTutoring => 'Start AI Tutoring';

  @override
  String get endLesson => 'End Lesson';

  @override
  String get typeYourMessage => 'Type your message...';

  @override
  String get send => 'Send';

  @override
  String get progressReport => 'Progress Report';

  @override
  String get askMentorAnything => 'Ask your mentor anything...';

  @override
  String get mentorGreeting => 'AI Mentor';

  @override
  String get mentorSubtitle => 'Your personal AI academic assistant';

  @override
  String get startingLesson => 'Starting your lesson...';

  @override
  String get lessonTimeEnded =>
      'Lesson time has ended. Click \'End Lesson\' to finish.';

  @override
  String get lessonComplete => 'Lesson Complete';

  @override
  String get errorOccurred => 'An error occurred. Please try again.';

  @override
  String get inProgress => 'In Progress';

  @override
  String get completed => 'Completed';

  @override
  String get notStarted => 'Not Started';

  @override
  String blocksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count blocks',
      one: '1 block',
    );
    return '$_temp0';
  }

  @override
  String get blockTypeExplanation => 'Explanation';

  @override
  String get blockTypeExample => 'Example';

  @override
  String get blockTypeExercise => 'Exercise';

  @override
  String get blockTypeSlide => 'Slide';

  @override
  String get blockTypeQuiz => 'Quiz';

  @override
  String get blockTypeSummary => 'Summary';

  @override
  String practiceModeType(String mode, String type) {
    return '$mode - $type';
  }

  @override
  String get examMode => 'Exam Mode';

  @override
  String get examModeDescription => 'Timed exam simulation';

  @override
  String get sourcePractice => 'Source Practice';

  @override
  String get sourcePracticeDescription => 'Practice by source';

  @override
  String get noSourcesAvailable => 'No sources available';

  @override
  String get howConfident => 'How confident are you?';

  @override
  String get confidenceRatingOf => 'of';

  @override
  String get notConfidentAtAll => 'Not confident at all';

  @override
  String get slightlyConfident => 'Slightly confident';

  @override
  String get moderatelyConfident => 'Moderately confident';

  @override
  String get quiteConfident => 'Quite confident';

  @override
  String get veryConfident => 'Very confident';

  @override
  String get reviewMistakes => 'Review Mistakes';

  @override
  String reviewMistakesDescription(int count) {
    return 'Review $count mistakes from this session';
  }

  @override
  String get noMistakesToReview => 'No mistakes to review';

  @override
  String get redoIncorrectQuestions => 'Redo Incorrect Questions';

  @override
  String get noAnswerProvided => 'No answer provided';

  @override
  String get correctAnswer => 'Correct Answer';

  @override
  String get practiceBySource => 'Practice by Source';

  @override
  String get practiceBySourceDescription =>
      'Select a source to practice questions from';

  @override
  String fallbackOption(int number) {
    return 'Option $number';
  }

  @override
  String get drawingSubmitted => 'Drawing submitted';

  @override
  String unsupportedQuestionType(String type) {
    return 'Unsupported question type: $type';
  }

  @override
  String get todaysPlan => 'Today\'s Plan';

  @override
  String get noStudyPlanToday => 'No study plan for today';

  @override
  String questionsCountMetric(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '1 question',
    );
    return '$_temp0';
  }

  @override
  String questionsAbbreviation(int count) {
    return '${count}Q';
  }

  @override
  String minutesCountMetric(int count) {
    return '$count min';
  }

  @override
  String get atRiskTopics => 'At Risk Topics';

  @override
  String get noAtRiskTopics => 'No at-risk topics. Keep up the good work!';

  @override
  String accuracyLabel(String percent) {
    return 'Accuracy: $percent';
  }

  @override
  String get readyToAdvance => 'Ready to Advance';

  @override
  String get keepPracticingToUnlock =>
      'Keep practicing to unlock advanced topics!';

  @override
  String get totalTopicsLabel => 'Total Topics';

  @override
  String get masteredLabel => 'Mastered';

  @override
  String get weakLabel => 'Weak';

  @override
  String avgAccuracyLabel(String percent) {
    return 'Avg Accuracy: $percent';
  }

  @override
  String avgReadinessLabel(String percent) {
    return 'Avg Readiness: $percent';
  }

  @override
  String courseSessionLabel(String course, int number) {
    return '$course - Session $number';
  }

  @override
  String get quickGuideWelcomeMessage =>
      'Hello! I\'m StudyKing\'s Quick Guide. Ask me anything about your studies!';

  @override
  String get suggestedPromptExplain => 'Explain photosynthesis';

  @override
  String get suggestedPromptQuiz => 'Quiz me on history';

  @override
  String get suggestedPromptMath => 'Help with math problems';

  @override
  String get quickGuideHelpContent =>
      'Quick Guide is your AI study assistant. You can:\n\n• Ask questions about any subject\n• Request explanations for concepts\n• Get help with practice problems\n\nJust type your question and tap send!';

  @override
  String semanticsYouSaid(String message) {
    return 'You said: $message';
  }

  @override
  String semanticsQuickGuideSaid(String message) {
    return 'Quick Guide said: $message';
  }

  @override
  String semanticsSendPrompt(String prompt) {
    return 'Send prompt: $prompt';
  }

  @override
  String get semanticsMessageInput => 'Message input for Quick Guide';

  @override
  String get fallbackExplainResponse =>
      'Sure! I can help explain concepts. What topic would you like me to explain?';

  @override
  String get fallbackQuizResponse =>
      'I can help with questions! Ask away and I\'ll do my best.';

  @override
  String get fallbackMathResponse =>
      'I\'d be happy to help with math! What specific problem or topic would you like to work on?';

  @override
  String get fallbackGeneralResponse =>
      'That\'s an interesting question! Let me help you understand it better.';

  @override
  String get quickGuideSystemPrompt =>
      'You are StudyKing Quick Guide, a helpful AI study assistant. Provide concise, educational answers. Help with explanations, quiz questions, and math problems. Respond conversationally.';

  @override
  String get aboutApplicationName => 'StudyKing';

  @override
  String get aboutVersion => 'v0.1.0';

  @override
  String get aboutLegalese => '© 2026 StudyKing.';

  @override
  String get unknownModelId => 'unknown-model';

  @override
  String get unknownProviderName => 'Unknown';

  @override
  String get examDateOptionalLabel => 'Exam Date (Optional):';

  @override
  String get lessonFallbackTitle => 'Lesson';

  @override
  String errorWithMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get questionTypeDefault => 'Question';

  @override
  String get durationSeparator => ' ';

  @override
  String get accessibility => 'Accessibility';

  @override
  String get highContrastMode => 'High Contrast Mode';

  @override
  String get highContrastDescription =>
      'Increase contrast for better visibility';

  @override
  String get largeTouchTargets => 'Large Touch Targets';

  @override
  String get largeTouchTargetsDescription => 'Increase tap target sizes';

  @override
  String get reduceMotion => 'Reduce Motion';

  @override
  String get reduceMotionDescription => 'Reduce or disable motion animations';

  @override
  String get errorNetworkConnection =>
      'Unable to connect to the server. Please check your internet connection and try again.';

  @override
  String get errorApiKeyMissing =>
      'API key is required. Please configure it in Settings.';

  @override
  String get errorInvalidApiKey =>
      'Invalid API key. Please check your credentials in Settings.';

  @override
  String get errorApiRateLimit =>
      'Too many requests. Please wait a moment and try again.';

  @override
  String get errorApiNotFound => 'The requested resource was not found.';

  @override
  String get errorApiInternalServer =>
      'The server encountered an error. Please try again later.';

  @override
  String get errorDatabase => 'A database error occurred. Please try again.';

  @override
  String get errorPdfParse =>
      'Unable to parse the PDF file. Please ensure it is a valid PDF.';

  @override
  String get errorContentGeneration =>
      'Failed to generate content. Please try again.';

  @override
  String get errorLlmUnavailable =>
      'The AI service is temporarily unavailable. Please try again.';

  @override
  String get errorApiAuth =>
      'Authentication failed. Please check your API credentials.';

  @override
  String get errorUnexpected =>
      'An unexpected error occurred. Please try again.';

  @override
  String get retryConnection => 'Retry Connection';

  @override
  String get retryAfterWait => 'Retry After Wait';

  @override
  String get weeklyActivity => 'Weekly Activity';

  @override
  String get topicsLabel => 'Topics';

  @override
  String get readiness => 'Readiness';

  @override
  String get overallMastery => 'Overall Mastery';

  @override
  String get avgTime => 'Avg Time';

  @override
  String get badges => 'Badges';

  @override
  String get sessionHistoryExport => 'Session History';

  @override
  String get progressExportedCsv => 'Progress exported to CSV';

  @override
  String get sessionHistoryExportedCsv => 'Session history exported to CSV';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get sessionHistoryExportedPdf => 'Session history exported to PDF';

  @override
  String get labelJson => 'JSON';

  @override
  String get failedToStartPractice => 'Failed to start practice session';

  @override
  String get aiTutor => 'AI Tutor';

  @override
  String get interactiveConversationalLessons =>
      'Interactive conversational lessons';

  @override
  String get personalStudyAssistantPlanner =>
      'Personal study assistant & planner';

  @override
  String get chooseStudyMode => 'Choose a study mode';

  @override
  String get clearConversation => 'Clear conversation';

  @override
  String get senderYou => 'You';

  @override
  String get senderTutor => 'Tutor';

  @override
  String get senderSystem => 'System';

  @override
  String remainingMinLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min remaining',
      one: '1 min remaining',
    );
    return '$_temp0';
  }

  @override
  String correctCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count correct',
      one: '1 correct',
    );
    return '$_temp0';
  }

  @override
  String get mentorWelcomeBody =>
      'I can help with:\n• Scheduling and rescheduling lessons\n• Reviewing your study progress\n• Planning long-term study goals\n• Motivation and encouragement\n• Deciding what to study next\n\nHow can I help you today?';

  @override
  String readyToLearnAbout(String topic) {
    return 'I\'m ready to learn about $topic. Please teach me!';
  }

  @override
  String correctCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count correct',
      one: '1 correct',
    );
    return '$_temp0';
  }

  @override
  String paceLabel(int pace) {
    return '$pace% pace';
  }

  @override
  String get errorWithResponse =>
      'Sorry, I encountered an error. Please try again.';

  @override
  String get mentorRejectionResponse =>
      'No problem! I won\'t make any changes. Let me know if you need anything else.';

  @override
  String get mentorNoLessonsScheduled =>
      'You don\'t have any lessons scheduled yet. Would you like me to help you create a study plan? I can help you set up regular study sessions for your subjects.';

  @override
  String get mentorUpcomingLessonsHeader => 'Here are your upcoming lessons:\n';

  @override
  String mentorLessonEntry(String topic, String date, int duration) {
    return '• $topic on $date ($duration min)\n';
  }

  @override
  String get mentorReschedulePrompt =>
      '\nWould you like to reschedule any of these?';

  @override
  String mentorRecentSessionOnDate(String date) {
    return 'Your most recent study session was on $date. Would you like to schedule a new lesson?';
  }

  @override
  String get mentorNotStarted =>
      'It looks like you haven\'t started yet. Would you like me to help you schedule your first lesson?';

  @override
  String get mentorScheduleError =>
      'I had trouble looking up your schedule. Please try again later.';

  @override
  String get mentorProgressError =>
      'I had trouble generating your progress report. Please try again later.';

  @override
  String get mentorNotStartedStudying =>
      'You haven\'t started studying yet! Would you like me to help you create a study plan to get started?';

  @override
  String get mentorToday => 'today';

  @override
  String mentorDaysAgo(int daysCount) {
    String _temp0 = intl.Intl.pluralLogic(
      daysCount,
      locale: localeName,
      other: '$daysCount days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String mentorInactiveDays(int daysCount) {
    return 'I noticed you haven\'t studied in $daysCount days. Would you like to schedule a study session to get back on track? Consistency is key to making progress!';
  }

  @override
  String mentorGreatJobStayingActive(String daysAgo) {
    return 'Great job staying active! Your last study session was $daysAgo. Keep up the good work!';
  }

  @override
  String get mentorWelcomeStart =>
      'Welcome! Let\'s get started with your studies. Would you like to schedule a lesson?';

  @override
  String get mentorActivityCheckError =>
      'I had trouble checking your activity. How can I help you today?';

  @override
  String mentorRescheduledConfirmation(String topic) {
    return 'I\'ve noted the change. Your lesson \"$topic\" has been rescheduled. Is there anything else I can help with?';
  }

  @override
  String get mentorNewSessionAdded =>
      'Great! I\'ve added a new study session to your schedule. You can check your planner for details.';

  @override
  String get mentorChangesDone =>
      'Done! The changes have been made to your schedule.';

  @override
  String get mentorAccuracy => 'Accuracy';

  @override
  String get mentorBadges => 'Badges';

  @override
  String get mentorRecommendationsSection => 'Recommendations';

  @override
  String get mentorProgressReportTitle => '📊 **Your Study Progress Report**\n';

  @override
  String mentorOverallAccuracy(String accuracy, String correct, String total) {
    return '**Overall Accuracy:** $accuracy% ($correct/$total correct)';
  }

  @override
  String mentorTotalStudyTime(String hours) {
    return '**Total Study Time:** $hours hours';
  }

  @override
  String mentorWeeklyActivity(String attempts) {
    return '**Weekly Activity:** $attempts attempts';
  }

  @override
  String mentorCompletedLessons(String count) {
    return '**Completed Lessons:** $count';
  }

  @override
  String mentorTopicsStudied(String count) {
    return '**Topics Studied:** $count';
  }

  @override
  String get mentorAreasNeedingAttention => '\n**Areas needing attention:**';

  @override
  String mentorTopicAccuracyEntry(String topic, int accuracy) {
    return '• $topic (accuracy: $accuracy%)';
  }

  @override
  String get mentorBadgesEarned => '\n**Badges earned:**';

  @override
  String mentorBadgeEntry(String name, String description) {
    return '• $name: $description';
  }

  @override
  String get mentorRecommendations => '\n**Recommendations:**';

  @override
  String mentorRecommendationEntry(String message) {
    return '• $message';
  }

  @override
  String get mentorProgressReportError =>
      'Unable to generate progress report. Please try again later.';

  @override
  String get mentorNoSubjects =>
      'You haven\'t added any subjects yet. Would you like help setting up your first subject?';

  @override
  String get mentorDoingWell =>
      'You\'re doing well! Would you like to review your progress, schedule a new lesson, or practice some questions?';

  @override
  String get roadmaps => 'Roadmaps';

  @override
  String get createRoadmap => 'Create Roadmap';

  @override
  String get roadmapGoal => 'Learning Goal';

  @override
  String get roadmapGoalHint => 'e.g., I want to learn IB Physics in 180 days';

  @override
  String get generateRoadmap => 'Generate Roadmap';

  @override
  String get myRoadmaps => 'My Roadmaps';

  @override
  String get milestones => 'Milestones';

  @override
  String get milestone => 'Milestone';

  @override
  String milestoneShort(int order) {
    return 'M$order';
  }

  @override
  String get targetCompletion => 'Target Completion';

  @override
  String get noRoadmapsYet => 'No roadmaps yet';

  @override
  String get roadmapOverview => 'Roadmap Overview';

  @override
  String get timeline => 'Timeline';

  @override
  String completionOfValue(double value) {
    return '$value% Complete';
  }

  @override
  String milestoneOfWithDeadline(String title, String deadline) {
    return '$title - Due $deadline';
  }

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get notificationPreferences => 'Notification Preferences';

  @override
  String get dailyReminders => 'Daily Reminders';

  @override
  String get revisionReminders => 'Revision Reminders';

  @override
  String get overworkAlerts => 'Overwork Alerts';

  @override
  String get planAdjustmentNotifications => 'Plan Adjustment Alerts';

  @override
  String get quietHours => 'Quiet Hours';

  @override
  String get quietHoursStart => 'Quiet Hours Start';

  @override
  String get quietHoursEnd => 'Quiet Hours End';

  @override
  String get exportComprehensiveReport => 'Export Full Progress Report';

  @override
  String get comprehensiveCsv => 'Full Progress CSV';

  @override
  String get comprehensivePdf => 'Full Progress PDF';

  @override
  String get comprehensiveJson => 'Full Progress JSON';

  @override
  String get comprehensiveReportExported =>
      'Comprehensive progress report exported';

  @override
  String get activeRoadmaps => 'Active Roadmaps';

  @override
  String get completedRoadmaps => 'Completed Roadmaps';

  @override
  String get progressBySubject => 'Progress by Subject';

  @override
  String weekNumber(int number) {
    return 'Week $number';
  }

  @override
  String milestoneForWeek(int number) {
    return 'Milestone for week $number';
  }

  @override
  String get markschemeUnavailable => 'No markscheme available';

  @override
  String get answerTooShort =>
      'Answer is too short. Please provide more details.';

  @override
  String get goodResponseLength => 'Good response length.';

  @override
  String get answerTooShortForCredit => 'Answer too short for full credit.';

  @override
  String get noDrawingDetected => 'No drawing detected. Please draw something.';

  @override
  String get invalidDrawingData => 'Invalid drawing data. Please redraw.';

  @override
  String get allStepsIdentified => 'All required steps identified.';

  @override
  String get specialHandlingRequired =>
      'This question type requires special handling.';

  @override
  String get someAnswersIncorrect => 'Some answers are incorrect';

  @override
  String correctAnswerIs(String answer) {
    return 'The correct answer is: $answer';
  }

  @override
  String allStepsFormat(int count) {
    return 'All $count steps identified correctly!';
  }

  @override
  String partialStepsFormat(int matched, int total, String missing) {
    return 'Identified $matched of $total steps. Missing: $missing';
  }

  @override
  String noStepsFormat(String steps) {
    return 'No required steps found in your answer. Key steps to include: $steps';
  }

  @override
  String get allRequiredStepsMissing => 'Some required steps missing';

  @override
  String get focusMode => 'Focus Mode';

  @override
  String get newFocusSession => 'New Focus Session';

  @override
  String get refreshStats => 'Refresh stats';

  @override
  String errorStartingSession(String error) {
    return 'Error starting session: $error';
  }

  @override
  String get dailyLimitReached => 'Daily Limit Reached';

  @override
  String get dailyLimitReachedBody =>
      'You\'ve reached your daily study limit — well done! Take a rest and come back tomorrow.';

  @override
  String get breakTime => 'Break Time!';

  @override
  String sessionCompleted(int minutes) {
    return 'Session completed: ${minutes}m';
  }

  @override
  String get focus => 'Focus';

  @override
  String focusForMinutes(int minutes) {
    return 'Focus for $minutes minutes';
  }

  @override
  String get focusTime => 'Focus Time';

  @override
  String get timerRemaining => 'remaining';

  @override
  String get timerPaused => 'PAUSED';

  @override
  String get timerDone => 'DONE!';

  @override
  String get resume => 'Resume';

  @override
  String get pause => 'Pause';

  @override
  String get markComplete => 'Mark Complete';

  @override
  String get csvOverallStats => 'OVERALL STATS';

  @override
  String get csvTopicMastery => 'TOPIC MASTERY';

  @override
  String get csvAllAttempts => 'ALL ATTEMPTS';

  @override
  String get csvWeeklyTrend => 'WEEKLY TREND';

  @override
  String get csvBadges => 'BADGES';

  @override
  String get csvColTotalAttempts => 'Total Attempts';

  @override
  String get csvColCorrect => 'Correct';

  @override
  String get csvColAccuracy => 'Accuracy (%)';

  @override
  String get csvColAvgTime => 'Avg Time (s)';

  @override
  String get csvColTotalHours => 'Total Hours';

  @override
  String get csvColWeeklyActivity => 'Weekly Activity';

  @override
  String get csvColDailyActivity => 'Daily Activity';

  @override
  String get csvColTopicsStudied => 'Topics Studied';

  @override
  String get csvColTopicId => 'Topic ID';

  @override
  String get csvColMasteryLevel => 'Mastery Level';

  @override
  String get csvColLastPracticed => 'Last Practiced';

  @override
  String get csvColReviewUrgency => 'Review Urgency';

  @override
  String get csvColQuestionId => 'Question ID';

  @override
  String get csvColSubjectId => 'Subject ID';

  @override
  String get csvColTime => 'Time (s)';

  @override
  String get csvColTimestamp => 'Timestamp';

  @override
  String get csvColWeek => 'Week';

  @override
  String get csvColAttempts => 'Attempts';

  @override
  String get csvColImprovement => 'Improvement';

  @override
  String get csvColBadgeName => 'Badge Name';

  @override
  String get csvColBadgeDescription => 'Description';

  @override
  String get csvColDateUnlocked => 'Date Unlocked';

  @override
  String get pdfProgressReport => 'StudyKing Progress Report';

  @override
  String pdfGenerated(String date) {
    return 'Generated: $date';
  }

  @override
  String pdfStudentId(String id) {
    return 'Student ID: $id';
  }

  @override
  String get pdfOverallStatistics => 'Overall Statistics';

  @override
  String get pdfMetric => 'Metric';

  @override
  String get pdfValue => 'Value';

  @override
  String get pdfTopicMasteryBreakdown => 'Topic Mastery Breakdown';

  @override
  String get pdfTableAttempts => 'Attempts';

  @override
  String get pdfTableLevel => 'Level';

  @override
  String get pdfTableTopic => 'Topic';

  @override
  String get pdfBadgesEarned => 'Badges Earned';

  @override
  String get pdfRecentActivitySummary => 'Recent Activity Summary';

  @override
  String get pdfNoMasteryData => 'No mastery data available yet.';

  @override
  String get pdfNoBadges => 'No badges earned yet. Keep studying!';

  @override
  String pdfTotalAttemptsRecorded(int count) {
    return 'Total attempts recorded: $count';
  }

  @override
  String pdfDateRange(String start, String end) {
    return 'Date range: $start to $end';
  }

  @override
  String pdfCorrectFraction(int correct, int total) {
    return 'Correct: $correct/$total';
  }

  @override
  String get gettingStarted => 'Getting Started';

  @override
  String get gettingStartedDesc =>
      'Complete these steps to get the most out of StudyKing';

  @override
  String get addSubjectDesc =>
      'Create your first subject to organize your study material';

  @override
  String get uploadMaterial => 'Upload Study Material';

  @override
  String get uploadMaterialDesc =>
      'Upload PDFs, notes, and question banks to get started';

  @override
  String get takePracticeQuiz => 'Take Your First Practice Quiz';

  @override
  String get takePracticeQuizDesc =>
      'Test your knowledge with adaptive practice questions';

  @override
  String get scheduleAiTutor => 'Schedule an AI Tutor Session';

  @override
  String get scheduleAiTutorDesc =>
      'Get personalized one-on-one tutoring with AI';

  @override
  String get fileSaved => 'File saved successfully';

  @override
  String get fileShared => 'File shared successfully';

  @override
  String get noBadgesYet => 'No achievements yet. Keep studying!';

  @override
  String get noOptionsAvailable => 'No options available';

  @override
  String get subjectProgress => 'Subject Progress';

  @override
  String get pendingActions => 'Pending Actions';

  @override
  String get scheduledLessons => 'Scheduled Lessons';

  @override
  String get regeneratePlan => 'Regenerate Plan';

  @override
  String get viewAllLessons => 'View All Lessons';

  @override
  String get change => 'Change';

  @override
  String get scheduling => 'Scheduling...';

  @override
  String get accept => 'Accept';

  @override
  String get scheduleALesson => 'Schedule a lesson';

  @override
  String get rescheduleLesson => 'Reschedule lesson';

  @override
  String get planAdjustmentTitle => 'Plan adjustment suggested';

  @override
  String get actionNeeded => 'Action needed';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get openPlanner => 'Open Planner';

  @override
  String get studyPlanOverview => 'Study Plan Overview';

  @override
  String moreLessonsCount(int count) {
    return '$count more...';
  }

  @override
  String get badgeFirstStepName => 'First Step';

  @override
  String get badgeFirstStepDesc => 'Answered your first question!';

  @override
  String get badgeAccuracyGoldName => 'Accuracy Gold';

  @override
  String get badgeAccuracyGoldDesc => 'Achieved 90%+ accuracy!';

  @override
  String get badgeDailyScholarName => 'Daily Scholar';

  @override
  String get badgeDailyScholarDesc => 'Studied consistently today!';

  @override
  String get badgeDedicatedLearnerName => 'Dedicated Learner';

  @override
  String get badgeDedicatedLearnerDesc => 'Studied 10+ hours total!';

  @override
  String get badgeWeeklyWarriorName => 'Weekly Warrior';

  @override
  String get badgeWeeklyWarriorDesc => 'Active for a full week!';

  @override
  String get notifChannelGeneral => 'StudyKing Notifications';

  @override
  String get notifChannelGeneralDesc => 'General StudyKing notifications';

  @override
  String get notifChannelRevision => 'Revision Reminders';

  @override
  String get notifChannelWellbeing => 'Wellbeing Alerts';

  @override
  String get notifChannelPlanning => 'Planning Suggestions';

  @override
  String get notifChannelLessons => 'Lesson Notifications';

  @override
  String get notifChannelMastery => 'Mastery Alerts';

  @override
  String get notifChannelBadges => 'Badge Notifications';

  @override
  String get notifChannelDailyReminder => 'Daily Study Reminders';

  @override
  String get notifChannelDailyReminderDesc => 'Daily reminders to study';

  @override
  String get notifTitleTimeToReview => 'Time to Review!';

  @override
  String notifBodyRevision(int days, String topicName) {
    return 'It\'s been $days days since you practiced \"$topicName\".';
  }

  @override
  String get notifTitleTakeBreak => 'Take a Break';

  @override
  String notifBodyOverwork(String hours) {
    return 'You\'ve studied $hours hours today. Remember to rest!';
  }

  @override
  String get notifTitlePlanAdjustment => 'Plan Adjustment';

  @override
  String notifBodyPlanAdjustment(int days) {
    return 'You\'ve had $days days of low adherence. Shall we adjust your plan?';
  }

  @override
  String get notifTitleUpcomingLesson => 'Upcoming Lesson';

  @override
  String notifBodyLessonReminder(String lessonTitle, String time) {
    return 'Your lesson \"$lessonTitle\" starts at $time.';
  }

  @override
  String get notifTitleTopicsNeedAttention => 'Topics Need Attention';

  @override
  String notifBodyLowMastery(String topics) {
    return 'Low mastery detected in: $topics';
  }

  @override
  String get notifTitleBadgeUnlocked => 'Badge Unlocked!';

  @override
  String notifBodyBadgeUnlocked(String badgeName, String badgeDescription) {
    return 'You earned the \"$badgeName\" badge: $badgeDescription';
  }

  @override
  String get recommendAccuracyBelow60 =>
      'Your overall accuracy is below 60%. Focus on reviewing fundamental concepts.';

  @override
  String get recommendReviewBasics => 'Review basic topics before advancing';

  @override
  String get recommendAccuracyExcellent =>
      'Excellent progress! Ready for advanced topics.';

  @override
  String get recommendChallengingQuestions =>
      'Try challenging practice questions';

  @override
  String get recommendConsistency =>
      'You studied less than 1 hour total. Consistency is key!';

  @override
  String get recommendSetDailyGoal => 'Set a daily study goal of 30 minutes';

  @override
  String get recommendNoActivity =>
      'No study activity this week. Get back on track!';

  @override
  String get recommendQuickReview =>
      'Start with a quick 15-minute review session';

  @override
  String recommendWeakTopics(int count) {
    return 'You have $count topic(s) that need improvement. Focus on strengthening these areas.';
  }

  @override
  String get recommendAiTutor => 'Review weak topics with the AI tutor';

  @override
  String nudgeOverwork(String hours) {
    return 'You have studied $hours hours today. Consider taking a break!';
  }

  @override
  String nudgeRevision(int days, String topic) {
    return 'It has been $days days since you practiced \"$topic\". Time for a review!';
  }

  @override
  String nudgePlanAdjustment(int days) {
    return 'You have had $days days of low plan adherence. Would you like to adjust your study plan?';
  }

  @override
  String get planReasonRequiredDependent => 'Required for dependent topics';

  @override
  String get planReasonWeakPerformance => 'Weak performance';

  @override
  String get planReasonHighForgettingRisk => 'High forgetting risk';

  @override
  String get planReasonNewSyllabusTopic => 'New syllabus topic';

  @override
  String get planReasonPartOfGoal => 'Part of syllabus goal';

  @override
  String get planFocusGeneralReview => 'General review';

  @override
  String get planFocusWeakAreas => 'Focus on weak areas';

  @override
  String get planFocusPracticeReview => 'Practice and review';

  @override
  String get planFocusRestAndReview => 'Rest and review';

  @override
  String get adapSuggestionFundamentals => 'Review basic concepts first';

  @override
  String get adapSuggestionMorePractice =>
      'More practice questions recommended';

  @override
  String get adapSuggestionAdvancedTopics => 'Ready for advanced topics';

  @override
  String get badgeCenturyClubName => 'Century Club';

  @override
  String get badgeCenturyClubDesc => 'Answered 100+ questions!';

  @override
  String nudgeWeeklyDigest(
    int weeklyActivity,
    int accuracy,
    String totalHours,
    int weakCount,
    int badgeCount,
  ) {
    return 'Weekly Digest: $weeklyActivity questions answered, $accuracy% accuracy, $totalHours hours studied, $weakCount weak areas, $badgeCount badges earned.';
  }

  @override
  String notificationTimeToReviewBody(int days, String topic) {
    return 'It\'s been $days days since you practiced \"$topic\".';
  }

  @override
  String notificationUpcomingLessonBody(String lesson, String time) {
    return 'Your lesson \"$lesson\" starts at $time';
  }

  @override
  String notificationBadgeUnlockedBody(String badge, String description) {
    return 'You earned the \"$badge\" badge: $description';
  }

  @override
  String get notifChannelRevisionDesc =>
      'Reminders to review topics that need practice';

  @override
  String get notifChannelWellbeingDesc =>
      'Alerts about study-life balance and overwork';

  @override
  String get notifChannelPlanningDesc =>
      'Suggestions about study plan adjustments';

  @override
  String get notifChannelLessonsDesc => 'Notifications about upcoming lessons';

  @override
  String get notifChannelMasteryDesc =>
      'Alerts about low topic mastery and weak areas';

  @override
  String get notifChannelBadgesDesc =>
      'Notifications about earned badges and achievements';

  @override
  String get planAccuracyLow =>
      'Accuracy is below 60% — needs focused practice';

  @override
  String get planReviewOverdue => 'Review is overdue — forgetting risk is high';

  @override
  String get planStreakLow => 'Streak is low — consistency needed';

  @override
  String get planPrerequisite =>
      'Prerequisite for upcoming topics — must master first';

  @override
  String planBlocksDownstream(int count) {
    return 'Blocks $count downstream topic(s)';
  }

  @override
  String get planRequiredForDependent => 'Required for dependent topics';

  @override
  String get planWeakPerformance => 'Weak performance';

  @override
  String get planHighForgettingRisk => 'High forgetting risk';

  @override
  String get planNewSyllabusTopic => 'New syllabus topic';

  @override
  String get planPartOfSyllabusGoal => 'Part of syllabus goal';

  @override
  String get planHighMastery => 'High mastery — ready to advance';

  @override
  String get planGoodProgress => 'Good progress — maintain consistency';

  @override
  String get planDeveloping => 'Developing — needs more practice';

  @override
  String get planAtRisk => 'At risk — review overdue';

  @override
  String get planNeedsAttention => 'Needs attention — focus on fundamentals';

  @override
  String get planRestAndReview => 'Rest and review';

  @override
  String get planGeneralReview => 'General review';

  @override
  String get planPracticeAndReview => 'Practice and review';

  @override
  String adherenceLowDaysAdjust(int days) {
    return 'You have had $days consecutive days of low adherence. Consider adjusting your study plan or discussing with your mentor.';
  }

  @override
  String adherenceLowDaysRegenerate(int days) {
    return 'You have had $days consecutive days of low adherence. Would you like to regenerate your plan with adjusted targets?';
  }

  @override
  String get shareSessionsText => 'Study Sessions';

  @override
  String get summary => 'Summary';

  @override
  String get noLimit => 'No limit';

  @override
  String get focusTimerDescription => 'Start a focused study session';

  @override
  String get dailyStudyCap => 'Daily Study Cap';

  @override
  String get tokenUsageSummary => 'Token Usage Summary';

  @override
  String get totalTokens => 'Total Tokens';

  @override
  String get totalCost => 'Total Cost';

  @override
  String get failed => 'Failed';

  @override
  String get subjectIdHint => 'e.g. sub_physics';

  @override
  String adherenceLowToday(int actualMinutes, int plannedMinutes) {
    return 'You studied $actualMinutes min today vs $plannedMinutes min planned. Consider redistributing the remaining workload.';
  }

  @override
  String adherencePartialToday(int actualMinutes, int plannedMinutes) {
    return 'You studied $actualMinutes min today vs $plannedMinutes min planned. Try to catch up with the remaining topics.';
  }

  @override
  String adherenceExceededToday(int actualMinutes, int plannedMinutes) {
    return 'Great work! You studied $actualMinutes min vs $plannedMinutes min planned.';
  }

  @override
  String overtimeLabel(int minutes) {
    return '+${minutes}m';
  }

  @override
  String get correctAnswerKeywords =>
      'correct,right,yes,got it,understood,i see,that makes sense,true,exactly';

  @override
  String get incorrectAnswerKeywords =>
      'wrong,incorrect,not sure,confused,don\'t know,don\'t understand,no,mistake,error';

  @override
  String get exerciseKeywords =>
      'exercise,practice,question,quiz,problem,test me,challenge,example';

  @override
  String get timeConflict => 'Time conflict with existing scheduled lesson';

  @override
  String get planGeneratedSuccessfully => 'Plan generated successfully';

  @override
  String get syllabusPlanGenerated =>
      'Syllabus-based plan generated successfully';

  @override
  String get failedToGenerateSyllabusPlan => 'Failed to generate syllabus plan';

  @override
  String get failedToCreateRoadmap => 'Failed to create roadmap';

  @override
  String get failedToUpdateMilestone => 'Failed to update milestone';

  @override
  String get actionAccepted => 'Action accepted';

  @override
  String get failedToExecuteAction =>
      'Failed to execute action — missing parameters';

  @override
  String get failedToAcceptAction => 'Failed to accept action';

  @override
  String get failedToDismissAction => 'Failed to dismiss action';

  @override
  String get lessonScheduled => 'Lesson scheduled';

  @override
  String get failedToScheduleLesson => 'Failed to schedule lesson';

  @override
  String get planRegeneratedFromAdherence =>
      'Plan regenerated based on your adherence';

  @override
  String get failedToRegeneratePlan => 'Failed to regenerate plan';

  @override
  String get missedWorkloadRedistributed =>
      'Missed workload redistributed over next 3 days';

  @override
  String get failedToRedistributeWorkload => 'Failed to redistribute workload';

  @override
  String get progressOverview => 'Progress Overview';

  @override
  String get todaysProgress => 'Today\'s Progress';

  @override
  String get weekly => 'Weekly';

  @override
  String get actual => 'Actual';

  @override
  String get planned => 'Planned';

  @override
  String get noStudyPlanYet => 'No study plan yet';

  @override
  String get calendar => 'Calendar';

  @override
  String get redistribute => 'Redistribute';

  @override
  String topicCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count topics',
      one: '1 topic',
    );
    return '$_temp0';
  }

  @override
  String syllabusTopics(int count) {
    return 'Topics: $count syllabus topics';
  }

  @override
  String get masteryRequirement => 'Mastery >= 80% on all milestone topics';

  @override
  String noTopicsFoundForSubject(String subjectId) {
    return 'No topics found for subject $subjectId';
  }

  @override
  String failedToResolveSyllabus(String error) {
    return 'Failed to resolve syllabus: $error';
  }

  @override
  String failedToGetQuestionsForTopic(String error) {
    return 'Failed to get questions for topic: $error';
  }

  @override
  String failedToGetQuestionsForTopics(String error) {
    return 'Failed to get questions for topics: $error';
  }

  @override
  String filePickerError(String error) {
    return 'File picker error: $error';
  }

  @override
  String get urlFetchSuccess => 'URL content fetched successfully';

  @override
  String urlFetchFailed(String error) {
    return 'Failed to fetch URL: $error';
  }

  @override
  String urlFetchError(String error) {
    return 'URL fetch error: $error';
  }

  @override
  String get file => 'File';

  @override
  String get fetchAndScrape => 'Fetch & Scrape';

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
    return '$date: $cost, cost/tk: $costPerToken';
  }

  @override
  String usageSummary(String totalCost, String totalTokens, String avgCost) {
    return 'Usage: $totalCost over $totalTokens tokens, avg: $avgCost per 1k tokens';
  }

  @override
  String get tapToExpand => 'Tap to expand';

  @override
  String get tapToCollapse => 'Tap to collapse';

  @override
  String get sendHint => 'Press Enter to send, Ctrl+Enter for new line';

  @override
  String get shareProgressReport => 'StudyKing Progress Report';

  @override
  String get shareSessionHistory => 'StudyKing Session History';

  @override
  String get shareInstrumentationData => 'StudyKing Instrumentation Data';

  @override
  String get instrumentationDashboard => '=== Instrumentation Dashboard ===';

  @override
  String instrumentationGenerated(String date) {
    return 'Generated: $date';
  }

  @override
  String get instrumentationPlanAdherence => '--- Plan Adherence ---';

  @override
  String get instrumentationMasteryImprovement => '--- Mastery Improvement ---';

  @override
  String get partialLabel => 'Partial';

  @override
  String get localeEn => 'English';

  @override
  String get localeEs => 'Spanish';
}
