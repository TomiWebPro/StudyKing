import 'package:flutter/material.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/widgets/not_found_screen.dart';
import 'package:studyking/features/dashboard/presentation/dashboard_screen.dart';
import 'package:studyking/features/dashboard/presentation/screens/topic_detail_screen.dart';

import 'package:studyking/features/ingestion/presentation/upload_screen.dart';
import 'package:studyking/features/ingestion/presentation/content_library_screen.dart';
import 'package:studyking/features/ingestion/presentation/source_detail_screen.dart';
import 'package:studyking/features/mentor/presentation/mentor_screen.dart';
import 'package:studyking/features/lessons/presentation/lesson_detail_screen.dart';
import 'package:studyking/features/lessons/presentation/lesson_list_screen.dart';
import 'package:studyking/features/lessons/presentation/topic_list_screen.dart';
import 'package:studyking/features/planner/presentation/planner_screen.dart';
import 'package:studyking/features/practice/presentation/screens/practice_session_screen.dart';
import 'package:studyking/features/practice/presentation/screens/exam_session_screen.dart';
import 'package:studyking/features/questions/presentation/question_bank_screen.dart';
import 'package:studyking/features/quickguide/presentation/quick_guide_screen.dart';
import 'package:studyking/features/sessions/presentation/session_history_screen.dart';
import 'package:studyking/features/sessions/presentation/session_tracker_screen.dart';
import 'package:studyking/features/settings/presentation/api_config_screen.dart';
import 'package:studyking/features/settings/presentation/profile_screen.dart';
import 'package:studyking/features/settings/presentation/settings_screen.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/features/subjects/presentation/subject_detail_screen.dart';
import 'package:studyking/features/subjects/presentation/subject_selection_screen.dart';
import 'package:studyking/features/teaching/presentation/tutor_screen.dart';
import 'package:studyking/features/llm_tasks/presentation/llm_task_manager_screen.dart';
import 'package:studyking/features/focus_mode/presentation/focus_timer_screen.dart';

class AppRoutes {
  AppRoutes._();

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

class PracticeSessionArgs {
  final String subjectId;
  final String? topicId;
  final String? sourceId;
  final int? questionCount;
  final bool isSpacedRepetition;
  final List<String>? orderedQuestionIds;

  const PracticeSessionArgs({
    required this.subjectId,
    this.topicId,
    this.sourceId,
    this.questionCount = 10,
    this.isSpacedRepetition = false,
    this.orderedQuestionIds,
  });
}

class ExamSessionArgs {
  final String subjectId;
  final String subjectName;

  const ExamSessionArgs({
    required this.subjectId,
    required this.subjectName,
  });
}

class LessonDetailArgs {
  final String lessonId;
  final String topicId;
  final String topicTitle;
  final String? subjectId;

  const LessonDetailArgs({
    required this.lessonId,
    required this.topicId,
    required this.topicTitle,
    this.subjectId,
  });
}

class LessonListArgs {
  final String topicId;
  final String topicTitle;
  final String? subjectId;

  const LessonListArgs({
    required this.topicId,
    required this.topicTitle,
    this.subjectId,
  });
}

class DashboardArgs {
  final String studentId;

  const DashboardArgs({required this.studentId});
}

class TutorArgs {
  final String topicId;
  final String topicTitle;
  final String subjectId;
  final int durationMinutes;
  final String? scheduledSessionId;

  const TutorArgs({
    required this.topicId,
    required this.topicTitle,
    required this.subjectId,
    this.durationMinutes = 45,
    this.scheduledSessionId,
  });
}

class FocusTimerScreenArgs {
  final String? preselectedSubjectId;
  final String? preselectedTopicId;
  final int? defaultDurationMinutes;

  const FocusTimerScreenArgs({
    this.preselectedSubjectId,
    this.preselectedTopicId,
    this.defaultDurationMinutes,
  });
}

Route<dynamic>? onGenerateRoute(RouteSettings routeSettings, [StudentIdService? studentIdService]) {
  final service = studentIdService ?? StudentIdService();
  switch (routeSettings.name) {
    case AppRoutes.settings:
      return _materialPageRoute(const SettingsScreen(), routeSettings);
    case AppRoutes.profile:
      return _materialPageRoute(const ProfileScreen(), routeSettings);
    case AppRoutes.apiConfig:
      return _materialPageRoute(const ApiConfigScreen(), routeSettings);
    case AppRoutes.quickGuide:
      return _materialPageRoute(const QuickGuideScreen(), routeSettings);
    case AppRoutes.mentor:
      return _materialPageRoute(const MentorScreen(), routeSettings);
    case AppRoutes.upload:
      final preselectedSubjectId = routeSettings.arguments as String?;
      return _materialPageRoute(
        UploadScreen(
          preselectedSubjectId: preselectedSubjectId,
          fixedStudentId: service.getStudentId(),
        ),
        routeSettings,
      );
    case AppRoutes.subjectSelection:
      final subject = routeSettings.arguments;
      return _materialPageRoute(
        SubjectSelectionScreen(
          editingSubject: subject is Subject ? subject : null,
        ),
        routeSettings,
      );
    case AppRoutes.sessionTracker:
      return _materialPageRoute(const SessionTrackerScreen(), routeSettings);
    case AppRoutes.sessionHistory:
      return _materialPageRoute(const SessionHistoryScreen(), routeSettings);
    case AppRoutes.planner:
      return _materialPageRoute(const PlannerScreen(), routeSettings);
    case AppRoutes.dashboard:
      final args = routeSettings.arguments;
      if (args is DashboardArgs) {
        return _materialPageRoute(
          DashboardScreen(studentId: args.studentId),
          routeSettings,
        );
      }
      return _materialPageRoute(
        DashboardScreen(
          studentId: service.getStudentId(),
        ),
        routeSettings,
      );
    case AppRoutes.subjectDetail:
      final args = routeSettings.arguments;
      if (args is Subject) {
        return _materialPageRoute(
          SubjectDetailScreen(subject: args),
          routeSettings,
        );
      }
      return _errorRoute(routeSettings);
    case AppRoutes.practiceSession:
      final args = routeSettings.arguments;
      if (args is PracticeSessionArgs) {
        return _materialPageRoute(
          PracticeSessionScreen(args: args),
          routeSettings,
        );
      }
      return _errorRoute(routeSettings);
    case AppRoutes.lessonList:
      final args = routeSettings.arguments;
      if (args is LessonListArgs) {
        return _materialPageRoute(
          LessonListScreen(args: args),
          routeSettings,
        );
      }
      return _errorRoute(routeSettings);
    case AppRoutes.lessonDetail:
      final args = routeSettings.arguments;
      if (args is LessonDetailArgs) {
        return _materialPageRoute(
          LessonDetailScreen(args: args),
          routeSettings,
        );
      }
      return _errorRoute(routeSettings);
    case AppRoutes.tutor:
      final args = routeSettings.arguments;
      if (args is TutorArgs) {
        return _materialPageRoute(
          TutorScreen(
            topicId: args.topicId,
            topicTitle: args.topicTitle,
            subjectId: args.subjectId,
            durationMinutes: args.durationMinutes,
            scheduledSessionId: args.scheduledSessionId,
          ),
          routeSettings,
        );
      }
      return _errorRoute(routeSettings);
    case AppRoutes.llmTasks:
      return _materialPageRoute(
        const LlmTaskManagerScreen(),
        routeSettings,
      );
    case AppRoutes.examSession:
      final args = routeSettings.arguments;
      if (args is ExamSessionArgs) {
        return _materialPageRoute(
          ExamSessionScreen(
            subjectId: args.subjectId,
            subjectName: args.subjectName,
          ),
          routeSettings,
        );
      }
      return _errorRoute(routeSettings);
    case AppRoutes.focusMode:
      final args = routeSettings.arguments;
      if (args is FocusTimerScreenArgs) {
        return _materialPageRoute(
          FocusTimerScreen(
            preselectedSubjectId: args.preselectedSubjectId,
            preselectedTopicId: args.preselectedTopicId,
            defaultDurationMinutes: args.defaultDurationMinutes,
          ),
          routeSettings,
        );
      }
      return _materialPageRoute(
        const FocusTimerScreen(),
        routeSettings,
      );
    case AppRoutes.contentLibrary:
      final subjectId = routeSettings.arguments as String?;
      return _materialPageRoute(
        ContentLibraryScreen(preselectedSubjectId: subjectId),
        routeSettings,
      );
    case AppRoutes.sourceDetail:
      final sourceId = routeSettings.arguments as String?;
      if (sourceId != null) {
        return _materialPageRoute(
          SourceDetailScreen(sourceId: sourceId),
          routeSettings,
        );
      }
      return _errorRoute(routeSettings);
    case AppRoutes.questionBank:
      final initialQuestionId = routeSettings.arguments as String?;
      return _materialPageRoute(
        QuestionBankScreen(initialQuestionId: initialQuestionId),
        routeSettings,
      );
    case AppRoutes.topicList:
      return _materialPageRoute(const TopicListScreen(), routeSettings);
    case AppRoutes.topicDetail:
      final args = routeSettings.arguments;
      if (args is TopicDetailArgs) {
        return _materialPageRoute(
          TopicDetailScreen(
            topicId: args.topicId,
            studentId: args.studentId,
          ),
          routeSettings,
        );
      }
      return _errorRoute(routeSettings);
    default:
      return _materialPageRoute(const NotFoundScreen(), routeSettings);
  }
}

PageRouteBuilder<dynamic> _materialPageRoute(Widget page, RouteSettings settings) {
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    transitionDuration: Timeouts.routeTransition,
  );
}

PageRouteBuilder<dynamic> _errorRoute(RouteSettings routeSettings) {
  return PageRouteBuilder(
    settings: routeSettings,
    pageBuilder: (context, animation, secondaryAnimation) => const NotFoundScreen(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    transitionDuration: Timeouts.routeTransition,
  );
}
