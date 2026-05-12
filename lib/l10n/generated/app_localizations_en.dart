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
    return '$count random questions';
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
  String get noWeakAreasFound => 'No weak areas found. Keep up the great work!';

  @override
  String get noWeakAreasQuestions => 'No questions available for your weak areas.';

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
  String get deleteAccountWarning => 'Deleting your account will permanently remove all study data';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirmation => 'Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your study data.';

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
  String get medium => 'Medium';

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
    return '$count sessions';
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
  String get modelRequestTimedOut => 'Model request timed out. Please try again.';

  @override
  String get unableToLoadModelsTryAgain => 'Unable to load models. Please try again.';

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
  String get deleteSubjectConfirmation => 'Are you sure you want to delete this subject? This will also delete all associated lessons and questions.';

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
  String get startLearningByCreatingTopics => 'Start learning by creating topics and questions';

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
  String get fileUploadImplemented => 'File upload functionality would be implemented here.';

  @override
  String get graphValidation => 'Graph Validation';

  @override
  String typeLabel(String graphType) {
    return 'Type: $graphType';
  }

  @override
  String get considerUsingPieChart => 'Consider using Pie Chart for small datasets';

  @override
  String get considerUsingBarChart => 'Consider using Bar Chart for larger datasets';

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
  String get questionTypeNotSupported => 'This question type is not yet supported in this view.';

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
  String get drawYourAnswer => 'Draw your answer on the canvas using your finger or stylus';

  @override
  String get apiConfiguration => 'API Configuration';

  @override
  String get configureApiKeys => 'Configure API Keys';

  @override
  String get configureApiKeysDescription => 'Enter your OpenRouter API credentials below. These are used to power the AI features.';

  @override
  String get openRouterApiKey => 'OpenRouter API Key';

  @override
  String get apiBaseUrl => 'API Base URL';

  @override
  String get apiKeyHint => 'sk-or-v1-...';

  @override
  String get apiBaseUrlHint => 'https://openrouter.ai/api/v1';

  @override
  String get apiKeyDescription => 'Required for LLM content generation. Get your key from https://openrouter.ai/keys';

  @override
  String get apiBaseUrlDescription => 'The endpoint URL for the AI service';

  @override
  String get saveApiKeys => 'Save API Keys';

  @override
  String get apiKeyCannotBeEmpty => 'API key cannot be empty';

  @override
  String get apiKeysSavedSuccessfully => 'API keys saved successfully';

  @override
  String get unableToSaveApiConfig => 'Unable to save API configuration. Please try again.';

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
  String get noSessionsFoundForFilters => 'No sessions found for selected filters';

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
  String get deleteSessionConfirmation => 'Are you sure you want to delete this session?';

  @override
  String get noQuestions => 'No questions';

  @override
  String questionsCountLabel(int count) {
    return '$count questions';
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
  String errorSavingSubject(String error) {
    return 'Error saving subject: $error';
  }

  @override
  String failedToSaveSession(String error) {
    return 'Failed to save session: $error';
  }
}
