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
  String drawingWithStrokes(int count, String plural) {
    return 'Drawing with $count stroke$plural';
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
  String get teachingMode => 'AI Tutor';

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
  String get retry => 'Retry';

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
    return '$daysCount days ago';
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
}
