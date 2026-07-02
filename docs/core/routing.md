# Routing & Navigation

## Route System

StudyKing uses named routes with a central `onGenerateRoute` function defined in `lib/core/routes/app_router.dart`.

### Route Definitions

All routes are defined as constants in `AppRoutes`:

```dart
class AppRoutes {
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String apiConfig = '/api-config';
  static const String quickGuide = '/quick-guide';
  static const String mentor = '/mentor';
  static const String dashboard = '/dashboard';
  static const String upload = '/upload';
  static const String subjectSelection = '/subject-selection';
  static const String subjectDetail = '/subject-detail';
  static const String practiceSession = '/practice-session';
  static const String sessionTracker = '/session-tracker';
  static const String sessionHistory = '/session-history';
  static const String tutor = '/tutor';
  static const String planner = '/planner';
  static const String lessonDetail = '/lesson-detail';
  static const String lessonList = '/lesson-list';
  static const String llmTasks = '/llm-tasks';
  static const String focusMode = '/focus-mode';
  static const String examSession = '/exam-session';
  static const String contentLibrary = '/content-library';
  static const String sourceDetail = '/source-detail';
  static const String questionBank = '/question-bank';
  static const String topicList = '/topic-list';
  static const String topicDetail = '/topic-detail';
}
```

### Navigation Arguments

Routes that require parameters use typed argument classes:

| Route | Args Class | Key Fields |
|---|---|---|
| `/practice-session` | `PracticeSessionArgs` | `subjectId`, `topicId?`, `sourceId?`, `questionCount`, `isSpacedRepetition`, `orderedQuestionIds?` |
| `/exam-session` | `ExamSessionArgs` | `subjectId`, `subjectName` |
| `/tutor` | `TutorArgs` | `topicId`, `topicTitle`, `subjectId`, `durationMinutes`, `scheduledSessionId?` |
| `/lesson-detail` | `LessonDetailArgs` | `lessonId`, `topicId`, `topicTitle`, `subjectId?` |
| `/lesson-list` | `LessonListArgs` | `topicId`, `topicTitle`, `subjectId?` |
| `/dashboard` | `DashboardArgs` | `studentId` |
| `/focus-mode` | `FocusTimerScreenArgs` | `preselectedSubjectId?`, `preselectedTopicId?`, `defaultDurationMinutes?` |
| `/topic-detail` | `TopicDetailArgs` | `topicId`, `studentId` |

### Navigation

```dart
// Simple route
Navigator.pushNamed(context, AppRoutes.settings);

// With arguments
Navigator.pushNamed(
  context,
  AppRoutes.tutor,
  arguments: TutorArgs(
    topicId: topic.id,
    topicTitle: topic.title,
    subjectId: subject.id,
    durationMinutes: 45,
  ),
);
```

## Tab Navigation

The main screen (`MainScreen` in `lib/main.dart`) uses a tab-based layout with six tabs:

| Index | Tab | Screen | Icon |
|---|---|---|---|
| 0 | Dashboard | `DashboardScreen` | `dashboard_outlined` |
| 1 | Subjects | `SubjectListScreen` | `school_outlined` |
| 2 | Practice | `PracticeScreen` | `play_arrow_outlined` |
| 3 | Mentor | `MentorScreen` | `auto_awesome_outlined` |
| 4 | Focus | `FocusTimerScreen` | `menu_book_outlined` |
| 5 | Settings | `SettingsScreen` | `settings_outlined` |

Each tab has its own `Navigator` (via `TabNavigator`) to maintain independent navigation stacks. On wide screens, a `NavigationRail` is used; on narrow screens, a `NavigationBar` at the bottom.

## Animations

All route transitions use a **FadeTransition** with a duration defined in `Timeouts.routeTransition`.

## Error Routing

If a route is called with invalid or missing arguments, the app navigates to `NotFoundScreen`. Unknown routes also fall through to `NotFoundScreen`.
