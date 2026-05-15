import 'package:flutter/material.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/dashboard/presentation/dashboard_screen.dart';
import 'package:studyking/features/dashboard/presentation/models/dashboard_models.dart';
import 'package:studyking/features/ingestion/presentation/upload_screen.dart';
import 'package:studyking/features/mentor/presentation/mentor_screen.dart';
import 'package:studyking/features/lessons/presentation/lesson_detail_screen.dart';
import 'package:studyking/features/lessons/presentation/lesson_list_screen.dart';
import 'package:studyking/features/planner/presentation/planner_screen.dart';
import 'package:studyking/features/practice/presentation/practice_session_screen.dart';
import 'package:studyking/features/quickguide/presentation/quick_guide_screen.dart';
import 'package:studyking/features/sessions/presentation/session_history_screen.dart';
import 'package:studyking/features/sessions/presentation/session_tracker_screen.dart';
import 'package:studyking/features/settings/presentation/api_config_screen.dart';
import 'package:studyking/features/settings/presentation/profile_screen.dart';
import 'package:studyking/features/settings/presentation/settings_screen.dart';
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
}

class SubjectDetailArgs {
  final String subjectId;
  final String subjectName;
  final String? subjectDescription;
  final String? subjectSyllabus;
  final String? subjectCode;
  final String? subjectTeacher;
  final String subjectColor;
  final String? subjectExamDate;
  final List<String> topicIds;

  const SubjectDetailArgs({
    required this.subjectId,
    required this.subjectName,
    this.subjectDescription,
    this.subjectSyllabus,
    this.subjectCode,
    this.subjectTeacher,
    required this.subjectColor,
    this.subjectExamDate,
    this.topicIds = const [],
  });
}

class PracticeSessionArgs {
  final String subjectId;
  final String? topicId;
  final int? questionCount;
  final bool isSpacedRepetition;

  const PracticeSessionArgs({
    required this.subjectId,
    this.topicId,
    this.questionCount = 10,
    this.isSpacedRepetition = false,
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
  final String subjectId;

  const LessonListArgs({
    required this.topicId,
    required this.topicTitle,
    this.subjectId = '',
  });
}

class TutorArgs {
  final String topicId;
  final String topicTitle;
  final String subjectId;
  final int durationMinutes;

  const TutorArgs({
    required this.topicId,
    required this.topicTitle,
    required this.subjectId,
    this.durationMinutes = 45,
  });
}

Route<dynamic>? onGenerateRoute(RouteSettings routeSettings) {
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
        UploadScreen(preselectedSubjectId: preselectedSubjectId),
        routeSettings,
      );
    case AppRoutes.subjectSelection:
      return _materialPageRoute(const SubjectSelectionScreen(), routeSettings);
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
          studentId: StudentIdService().getStudentId(),
        ),
        routeSettings,
      );
    case AppRoutes.subjectDetail:
      final args = routeSettings.arguments;
      if (args is SubjectDetailArgs) {
        return _materialPageRoute(
          SubjectDetailScreen(args: args),
          routeSettings,
        );
      }
      return null;
    case AppRoutes.practiceSession:
      final args = routeSettings.arguments;
      if (args is PracticeSessionArgs) {
        return _materialPageRoute(
          PracticeSessionScreen(args: args),
          routeSettings,
        );
      }
      return null;
    case AppRoutes.lessonList:
      final args = routeSettings.arguments;
      if (args is LessonListArgs) {
        return _materialPageRoute(
          LessonListScreen(args: args),
          routeSettings,
        );
      }
      return null;
    case AppRoutes.lessonDetail:
      final args = routeSettings.arguments;
      if (args is LessonDetailArgs) {
        return _materialPageRoute(
          LessonDetailScreen(args: args),
          routeSettings,
        );
      }
      return null;
    case AppRoutes.tutor:
      final args = routeSettings.arguments;
      if (args is TutorArgs) {
        return _materialPageRoute(
          TutorScreen(
            topicId: args.topicId,
            topicTitle: args.topicTitle,
            subjectId: args.subjectId,
            durationMinutes: args.durationMinutes,
          ),
          routeSettings,
        );
      }
      return null;
    case AppRoutes.llmTasks:
      return _materialPageRoute(
        const LlmTaskManagerScreen(),
        routeSettings,
      );
    case AppRoutes.focusMode:
      return _materialPageRoute(
        const FocusTimerScreen(),
        routeSettings,
      );
    default:
      return null;
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
    transitionDuration: const Duration(milliseconds: 200),
  );
}
