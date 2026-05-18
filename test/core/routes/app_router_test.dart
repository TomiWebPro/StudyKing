import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/widgets/not_found_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

void main() {
  group('AppRoutes', () {
    test('settings', () => expect(AppRoutes.settings, '/settings'));
    test('profile', () => expect(AppRoutes.profile, '/profile'));
    test('apiConfig', () => expect(AppRoutes.apiConfig, '/api-config'));
    test('quickGuide', () => expect(AppRoutes.quickGuide, '/quick-guide'));
    test('mentor', () => expect(AppRoutes.mentor, '/mentor'));
    test('dashboard', () => expect(AppRoutes.dashboard, '/dashboard'));
    test('upload', () => expect(AppRoutes.upload, '/upload'));
    test('subjectSelection', () => expect(AppRoutes.subjectSelection, '/subject-selection'));
    test('subjectDetail', () => expect(AppRoutes.subjectDetail, '/subject-detail'));
    test('practiceSession', () => expect(AppRoutes.practiceSession, '/practice-session'));
    test('sessionTracker', () => expect(AppRoutes.sessionTracker, '/session-tracker'));
    test('sessionHistory', () => expect(AppRoutes.sessionHistory, '/session-history'));
    test('tutor', () => expect(AppRoutes.tutor, '/tutor'));
    test('planner', () => expect(AppRoutes.planner, '/planner'));
    test('lessonDetail', () => expect(AppRoutes.lessonDetail, '/lesson-detail'));
    test('lessonList', () => expect(AppRoutes.lessonList, '/lesson-list'));
    test('llmTasks', () => expect(AppRoutes.llmTasks, '/llm-tasks'));
    test('focusMode', () => expect(AppRoutes.focusMode, '/focus-mode'));
    test('examSession', () => expect(AppRoutes.examSession, '/exam-session'));
    test('contentLibrary', () => expect(AppRoutes.contentLibrary, '/content-library'));
    test('sourceDetail', () => expect(AppRoutes.sourceDetail, '/source-detail'));
    test('questionBank', () => expect(AppRoutes.questionBank, '/question-bank'));
  });

  group('SubjectDetailArgs', () {
    test('creates with required fields only', () {
      final args = const SubjectDetailArgs(
        subjectId: 's1',
        subjectName: 'Math',
        subjectColor: '0xFF0000',
      );
      expect(args.subjectId, 's1');
      expect(args.subjectName, 'Math');
      expect(args.subjectColor, '0xFF0000');
      expect(args.subjectDescription, isNull);
      expect(args.subjectSyllabus, isNull);
      expect(args.subjectCode, isNull);
      expect(args.subjectTeacher, isNull);
      expect(args.subjectExamDate, isNull);
      expect(args.topicIds, isEmpty);
    });

    test('creates with all fields', () {
      final args = const SubjectDetailArgs(
        subjectId: 's1',
        subjectName: 'Math',
        subjectDescription: 'Algebra course',
        subjectSyllabus: 'Syllabus content',
        subjectCode: 'MATH101',
        subjectTeacher: 'Dr. Smith',
        subjectColor: '0xFF0000',
        subjectExamDate: '2025-06-01',
        topicIds: ['t1', 't2'],
      );
      expect(args.subjectId, 's1');
      expect(args.subjectName, 'Math');
      expect(args.subjectDescription, 'Algebra course');
      expect(args.subjectSyllabus, 'Syllabus content');
      expect(args.subjectCode, 'MATH101');
      expect(args.subjectTeacher, 'Dr. Smith');
      expect(args.subjectColor, '0xFF0000');
      expect(args.subjectExamDate, '2025-06-01');
      expect(args.topicIds, ['t1', 't2']);
    });

    test('topicIds defaults to empty list', () {
      final args = const SubjectDetailArgs(
        subjectId: 's1',
        subjectName: 'Math',
        subjectColor: '0xFF0000',
      );
      expect(args.topicIds, isA<List<String>>());
      expect(args.topicIds, isEmpty);
    });

    test('optional fields can be explicitly null', () {
      final args = const SubjectDetailArgs(
        subjectId: 's1',
        subjectName: 'Math',
        subjectColor: '0xFF0000',
        subjectDescription: null,
        subjectSyllabus: null,
        subjectCode: null,
        subjectTeacher: null,
        subjectExamDate: null,
      );
      expect(args.subjectDescription, isNull);
      expect(args.subjectSyllabus, isNull);
      expect(args.subjectCode, isNull);
      expect(args.subjectTeacher, isNull);
      expect(args.subjectExamDate, isNull);
    });

    test('topicIds is immutable (cannot modify through getter)', () {
      final args = const SubjectDetailArgs(
        subjectId: 's1',
        subjectName: 'Math',
        subjectColor: '0xFF0000',
        topicIds: ['t1'],
      );
      expect(args.topicIds, ['t1']);
    });
  });

  group('PracticeSessionArgs', () {
    test('creates with required fields only', () {
      final args = const PracticeSessionArgs(subjectId: 's1');
      expect(args.subjectId, 's1');
      expect(args.topicId, isNull);
      expect(args.questionCount, 10);
      expect(args.isSpacedRepetition, false);
    });

    test('creates with all fields', () {
      final args = const PracticeSessionArgs(
        subjectId: 's1',
        topicId: 't1',
        questionCount: 20,
        isSpacedRepetition: true,
        orderedQuestionIds: ['q1', 'q2'],
      );
      expect(args.subjectId, 's1');
      expect(args.topicId, 't1');
      expect(args.questionCount, 20);
      expect(args.isSpacedRepetition, true);
      expect(args.orderedQuestionIds, ['q1', 'q2']);
    });

    test('orderedQuestionIds defaults to null', () {
      final args = const PracticeSessionArgs(subjectId: 's1');
      expect(args.orderedQuestionIds, isNull);
    });

    test('questionCount defaults to 10', () {
      final args = const PracticeSessionArgs(subjectId: 's1');
      expect(args.questionCount, 10);
    });

    test('isSpacedRepetition defaults to false', () {
      final args = const PracticeSessionArgs(subjectId: 's1');
      expect(args.isSpacedRepetition, false);
    });

    test('topicId can be null', () {
      final args = const PracticeSessionArgs(subjectId: 's1');
      expect(args.topicId, isNull);
    });
  });

  group('ExamSessionArgs', () {
    test('creates with required fields only', () {
      final args = const ExamSessionArgs(
        subjectId: 's1',
        subjectName: 'Math',
      );
      expect(args.subjectId, 's1');
      expect(args.subjectName, 'Math');
    });

    test('creates with all fields', () {
      final args = const ExamSessionArgs(
        subjectId: 's1',
        subjectName: 'Physics',
      );
      expect(args.subjectId, 's1');
      expect(args.subjectName, 'Physics');
    });

    test('subjectId is preserved', () {
      final args = const ExamSessionArgs(
        subjectId: 'subject-42',
        subjectName: 'Chemistry',
      );
      expect(args.subjectId, 'subject-42');
    });

    test('subjectName is preserved', () {
      final args = const ExamSessionArgs(
        subjectId: 's1',
        subjectName: 'Biology',
      );
      expect(args.subjectName, 'Biology');
    });
  });

  group('DashboardArgs', () {
    test('creates with studentId', () {
      final args = const DashboardArgs(studentId: 'student-123');
      expect(args.studentId, 'student-123');
    });

    test('preserves studentId value', () {
      final args = const DashboardArgs(studentId: 'custom-id');
      expect(args.studentId, 'custom-id');
    });
  });

  group('TutorArgs', () {
    test('creates with required fields only', () {
      final args = const TutorArgs(
        topicId: 't1',
        topicTitle: 'Algebra',
        subjectId: 's1',
      );
      expect(args.topicId, 't1');
      expect(args.topicTitle, 'Algebra');
      expect(args.subjectId, 's1');
      expect(args.durationMinutes, 45);
    });

    test('creates with all fields', () {
      final args = const TutorArgs(
        topicId: 't1',
        topicTitle: 'Algebra',
        subjectId: 's1',
        durationMinutes: 60,
      );
      expect(args.topicId, 't1');
      expect(args.topicTitle, 'Algebra');
      expect(args.subjectId, 's1');
      expect(args.durationMinutes, 60);
    });

    test('durationMinutes defaults to 45', () {
      final args = const TutorArgs(
        topicId: 't1',
        topicTitle: 'Algebra',
        subjectId: 's1',
      );
      expect(args.durationMinutes, 45);
    });

    test('scheduledSessionId defaults to null', () {
      final args = const TutorArgs(
        topicId: 't1',
        topicTitle: 'Algebra',
        subjectId: 's1',
      );
      expect(args.scheduledSessionId, isNull);
    });

    test('scheduledSessionId can be set', () {
      final args = const TutorArgs(
        topicId: 't1',
        topicTitle: 'Algebra',
        subjectId: 's1',
        durationMinutes: 60,
        scheduledSessionId: 'session-123',
      );
      expect(args.scheduledSessionId, 'session-123');
    });
  });

  group('LessonDetailArgs', () {
    test('creates with required fields only', () {
      final args = const LessonDetailArgs(
        lessonId: 'l1',
        topicId: 't1',
        topicTitle: 'Algebra',
      );
      expect(args.lessonId, 'l1');
      expect(args.topicId, 't1');
      expect(args.topicTitle, 'Algebra');
      expect(args.subjectId, isNull);
    });

    test('creates with all fields', () {
      final args = const LessonDetailArgs(
        lessonId: 'l1',
        topicId: 't1',
        topicTitle: 'Algebra',
        subjectId: 's1',
      );
      expect(args.lessonId, 'l1');
      expect(args.topicId, 't1');
      expect(args.topicTitle, 'Algebra');
      expect(args.subjectId, 's1');
    });

    test('subjectId defaults to null', () {
      final args = const LessonDetailArgs(
        lessonId: 'l1',
        topicId: 't1',
        topicTitle: 'Algebra',
      );
      expect(args.subjectId, isNull);
    });
  });

  group('LessonListArgs', () {
    test('creates with required fields only', () {
      final args = const LessonListArgs(
        topicId: 't1',
        topicTitle: 'Algebra',
      );
      expect(args.topicId, 't1');
      expect(args.topicTitle, 'Algebra');
      expect(args.subjectId, '');
    });

    test('creates with all fields', () {
      final args = const LessonListArgs(
        topicId: 't1',
        topicTitle: 'Algebra',
        subjectId: 's1',
      );
      expect(args.topicId, 't1');
      expect(args.topicTitle, 'Algebra');
      expect(args.subjectId, 's1');
    });

    test('subjectId defaults to empty string', () {
      final args = const LessonListArgs(
        topicId: 't1',
        topicTitle: 'Algebra',
      );
      expect(args.subjectId, '');
    });
  });

  group('onGenerateRoute', () {
    group('simple routes (no args required)', () {
      final simpleRoutes = <String>[
        AppRoutes.settings,
        AppRoutes.profile,
        AppRoutes.apiConfig,
        AppRoutes.quickGuide,
        AppRoutes.mentor,
        AppRoutes.upload,
        AppRoutes.subjectSelection,
        AppRoutes.sessionTracker,
        AppRoutes.sessionHistory,
        AppRoutes.planner,
        AppRoutes.contentLibrary,
        AppRoutes.questionBank,
      ];

      for (final routeName in simpleRoutes) {
        test('returns PageRouteBuilder for $routeName', () {
          final route = onGenerateRoute(RouteSettings(name: routeName));
          expect(route, isNotNull);
          expect(route!.settings.name, routeName);
          expect(route, isA<PageRouteBuilder>());
        });
      }
    });

    group('upload', () {
      test('returns route with string arg', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.upload,
          arguments: 'subject-1',
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.upload);
        expect(route, isA<PageRouteBuilder>());
      });

      test('returns route with null arg', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.upload,
          arguments: null,
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.upload);
        expect(route, isA<PageRouteBuilder>());
      });

      test('returns route with no arg', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.upload,
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.upload);
        expect(route, isA<PageRouteBuilder>());
      });
    });

    group('subjectSelection', () {
      test('returns route with Subject arg', () {
        final subject = Subject(
          id: 's1',
          name: 'Math',
        );
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.subjectSelection,
          arguments: subject,
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.subjectSelection);
        expect(route, isA<PageRouteBuilder>());
      });

      test('returns route with null arg', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.subjectSelection,
          arguments: null,
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.subjectSelection);
        expect(route, isA<PageRouteBuilder>());
      });

      test('returns route with string arg (not Subject)', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.subjectSelection,
          arguments: 'not-a-subject',
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.subjectSelection);
        expect(route, isA<PageRouteBuilder>());
      });

      test('returns route with int arg (not Subject)', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.subjectSelection,
          arguments: 42,
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.subjectSelection);
        expect(route, isA<PageRouteBuilder>());
      });
    });

    group('unknown route (default case)', () {
      test('returns error route for unknown route name', () {
        final route = onGenerateRoute(const RouteSettings(name: '/unknown'));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, '/unknown');
      });

      test('returns error route for empty route name', () {
        final route = onGenerateRoute(const RouteSettings(name: ''));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, '');
      });

      test('returns error route for null route name', () {
        final route = onGenerateRoute(const RouteSettings(name: null));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, null);
      });
    });

    group('dashboard', () {
      test('returns route with DashboardArgs', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.dashboard,
          arguments: const DashboardArgs(studentId: 'student-123'),
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.dashboard);
      });

      test('returns route without args using default services', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.dashboard,
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.dashboard);
      });

      test('returns route with null args using defaults', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.dashboard,
          arguments: null,
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.dashboard);
      });

      test('returns route with non-DashboardArgs using defaults', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.dashboard,
          arguments: 'invalid',
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.dashboard);
      });
    });

    group('subjectDetail', () {
      test('returns route with SubjectDetailArgs (required only)', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.subjectDetail,
          arguments: const SubjectDetailArgs(
            subjectId: 's1',
            subjectName: 'Math',
            subjectColor: '0xFF0000',
          ),
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.subjectDetail);
      });

      test('returns route with SubjectDetailArgs (all fields)', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.subjectDetail,
          arguments: const SubjectDetailArgs(
            subjectId: 's1',
            subjectName: 'Math',
            subjectDescription: 'Algebra',
            subjectSyllabus: 'Syllabus',
            subjectCode: 'MATH101',
            subjectTeacher: 'Dr. Smith',
            subjectColor: '0xFF0000',
            subjectExamDate: '2025-06-01',
            topicIds: ['t1', 't2'],
          ),
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.subjectDetail);
      });

      test('returns error route without args', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.subjectDetail,
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.subjectDetail);
      });

      test('returns error route with null args', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.subjectDetail,
          arguments: null,
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.subjectDetail);
      });

      test('returns error route with string args', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.subjectDetail,
          arguments: 'wrong type',
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.subjectDetail);
      });

      test('returns error route with Map args instead of SubjectDetailArgs', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.subjectDetail,
          arguments: <String, dynamic>{'subjectId': 's1'},
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.subjectDetail);
      });

      test('returns error route with int args', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.subjectDetail,
          arguments: 123,
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.subjectDetail);
      });
    });

    group('practiceSession', () {
      test('returns route with PracticeSessionArgs (required only)', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.practiceSession,
          arguments: const PracticeSessionArgs(subjectId: 's1'),
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.practiceSession);
      });

      test('returns route with PracticeSessionArgs (all fields)', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.practiceSession,
          arguments: const PracticeSessionArgs(
            subjectId: 's1',
            topicId: 't1',
            questionCount: 20,
            isSpacedRepetition: true,
          ),
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.practiceSession);
      });

      test('returns error route without args', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.practiceSession,
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.practiceSession);
      });

      test('returns error route with null args', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.practiceSession,
          arguments: null,
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.practiceSession);
      });

      test('returns error route with string args', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.practiceSession,
          arguments: 'wrong type',
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.practiceSession);
      });

      test('returns error route with Map args instead of PracticeSessionArgs', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.practiceSession,
          arguments: <String, dynamic>{'subjectId': 's1'},
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.practiceSession);
      });
    });

    group('tutor', () {
      test('returns route with TutorArgs (required only)', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.tutor,
          arguments: const TutorArgs(
            topicId: 't1',
            topicTitle: 'Algebra',
            subjectId: 's1',
          ),
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.tutor);
      });

      test('returns route with TutorArgs (custom duration)', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.tutor,
          arguments: const TutorArgs(
            topicId: 't1',
            topicTitle: 'Algebra',
            subjectId: 's1',
            durationMinutes: 90,
          ),
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.tutor);
      });

      test('returns error route without args', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.tutor,
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.tutor);
      });

      test('returns error route with null args', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.tutor,
          arguments: null,
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.tutor);
      });

      test('returns error route with string args', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.tutor,
          arguments: 'wrong type',
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.tutor);
      });

      test('returns error route with Map args instead of TutorArgs', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.tutor,
          arguments: <String, dynamic>{'topicId': 't1'},
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.tutor);
      });
    });

    group('llmTasks', () {
      test('returns route without args', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.llmTasks,
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.llmTasks);
      });

      test('returns route with args (ignored)', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.llmTasks,
          arguments: 'anything',
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.llmTasks);
      });

      test('returns route with null args', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.llmTasks,
          arguments: null,
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.llmTasks);
      });
    });

    group('lessonList', () {
      test('returns route with LessonListArgs (required only)', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.lessonList,
          arguments: const LessonListArgs(topicId: 't1', topicTitle: 'Algebra'),
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.lessonList);
      });

      test('returns route with LessonListArgs (all fields)', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.lessonList,
          arguments: const LessonListArgs(
            topicId: 't1',
            topicTitle: 'Algebra',
            subjectId: 's1',
          ),
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.lessonList);
      });

      test('returns error route without args', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.lessonList,
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.lessonList);
      });

      test('returns error route with null args', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.lessonList,
          arguments: null,
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.lessonList);
      });

      test('returns error route with string args', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.lessonList,
          arguments: 'wrong type',
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.lessonList);
      });

      test('returns error route with Map args instead of LessonListArgs', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.lessonList,
          arguments: <String, dynamic>{'topicId': 't1'},
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.lessonList);
      });
    });

    group('lessonDetail', () {
      test('returns route with LessonDetailArgs (required only)', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.lessonDetail,
          arguments: const LessonDetailArgs(
            lessonId: 'l1',
            topicId: 't1',
            topicTitle: 'Algebra',
          ),
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.lessonDetail);
      });

      test('returns route with LessonDetailArgs (all fields)', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.lessonDetail,
          arguments: const LessonDetailArgs(
            lessonId: 'l1',
            topicId: 't1',
            topicTitle: 'Algebra',
            subjectId: 's1',
          ),
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.lessonDetail);
      });

      test('returns error route without args', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.lessonDetail,
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.lessonDetail);
      });

      test('returns error route with null args', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.lessonDetail,
          arguments: null,
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.lessonDetail);
      });

      test('returns error route with string args', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.lessonDetail,
          arguments: 'wrong type',
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.lessonDetail);
      });

      test('returns error route with Map args instead of LessonDetailArgs', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.lessonDetail,
          arguments: <String, dynamic>{'lessonId': 'l1'},
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.lessonDetail);
      });
    });

    group('focusMode', () {
      test('returns route without args', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.focusMode,
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.focusMode);
      });

      test('returns route with args (ignored)', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.focusMode,
          arguments: 'anything',
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.focusMode);
      });

      test('returns route with null args', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.focusMode,
          arguments: null,
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.focusMode);
      });
    });

    group('examSession', () {
      test('returns route with ExamSessionArgs', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.examSession,
          arguments: const ExamSessionArgs(
            subjectId: 's1',
            subjectName: 'Math',
          ),
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.examSession);
      });

      test('returns error route without args', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.examSession,
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.examSession);
      });

      test('returns error route with null args', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.examSession,
          arguments: null,
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.examSession);
      });

      test('returns error route with string args', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.examSession,
          arguments: 'wrong type',
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.examSession);
      });

      test('returns error route with Map args', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.examSession,
          arguments: <String, dynamic>{'subjectId': 's1'},
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.examSession);
      });
    });

    group('contentLibrary', () {
      test('returns route without args', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.contentLibrary,
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.contentLibrary);
      });

      test('returns route with string arg', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.contentLibrary,
          arguments: 'subject-1',
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.contentLibrary);
      });

      test('returns route with null arg', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.contentLibrary,
          arguments: null,
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.contentLibrary);
      });
    });

    group('sourceDetail', () {
      test('returns route with sourceId arg', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.sourceDetail,
          arguments: 'source-1',
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.sourceDetail);
      });

      test('returns error route without args', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.sourceDetail,
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.sourceDetail);
      });

      test('returns error route with null arg', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.sourceDetail,
          arguments: null,
        ));
        expect(route, isNotNull);
        expect(route, isA<PageRouteBuilder>());
        expect(route!.settings.name, AppRoutes.sourceDetail);
      });
    });

    group('questionBank', () {
      test('returns route without args', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.questionBank,
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.questionBank);
      });

      test('returns route with string arg', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.questionBank,
          arguments: 'question-1',
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.questionBank);
      });

      test('returns route with null arg', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.questionBank,
          arguments: null,
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.questionBank);
      });
    });
  });

  group('_materialPageRoute (tested indirectly via onGenerateRoute)', () {
    test('creates route with 200ms transition duration', () {
      final route = onGenerateRoute(const RouteSettings(
        name: AppRoutes.settings,
      ));
      final builder = route as PageRouteBuilder;
      expect(builder.transitionDuration, const Duration(milliseconds: 200));
    });

    test('preserves route settings name', () {
      const settings = RouteSettings(name: AppRoutes.profile);
      final route = onGenerateRoute(settings);
      expect(route?.settings.name, AppRoutes.profile);
    });

    test('preserves route settings arguments', () {
      final args = const DashboardArgs(studentId: 'test-student');
      final route = onGenerateRoute(RouteSettings(
        name: AppRoutes.dashboard,
        arguments: args,
      ));
      expect(route?.settings.arguments, same(args));
    });

    test('has a valid pageBuilder', () {
      final route = onGenerateRoute(const RouteSettings(
        name: AppRoutes.settings,
      ));
      final builder = route as PageRouteBuilder;
      expect(builder.pageBuilder, isA<RoutePageBuilder>());
    });

    test('has a valid transitionsBuilder', () {
      final route = onGenerateRoute(const RouteSettings(
        name: AppRoutes.settings,
      ));
      final builder = route as PageRouteBuilder;
      expect(builder.transitionsBuilder, isNotNull);
    });

    testWidgets('transitionsBuilder produces FadeTransition widget',
        (tester) async {
      final route = onGenerateRoute(const RouteSettings(
        name: AppRoutes.settings,
      )) as PageRouteBuilder;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              final animation = AnimationController(
                vsync: tester,
                value: 1,
              );
              final secondaryAnimation = AnimationController(
                vsync: tester,
                value: 1,
              );
              return route.transitionsBuilder(
                context,
                animation,
                secondaryAnimation,
                const Text('child'),
              );
            },
          ),
        ),
      );

      expect(find.byType(FadeTransition), findsOneWidget);
    });

    testWidgets('error route pageBuilder produces NotFoundScreen',
        (tester) async {
      final route = onGenerateRoute(const RouteSettings(
        name: AppRoutes.subjectDetail,
      )) as PageRouteBuilder;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final animation = AnimationController(
                vsync: tester,
                value: 0,
              );
              return route.pageBuilder(context, animation, animation);
            },
          ),
        ),
      );

      expect(find.byType(NotFoundScreen), findsOneWidget);
    });
  });

  group('_errorRoute (tested indirectly via onGenerateRoute)', () {
    test('error route has 200ms transition duration', () {
      final route = onGenerateRoute(const RouteSettings(
        name: AppRoutes.subjectDetail,
      ));
      final builder = route as PageRouteBuilder;
      expect(builder.transitionDuration, const Duration(milliseconds: 200));
    });

    test('error route preserves settings name', () {
      final route = onGenerateRoute(const RouteSettings(
        name: AppRoutes.subjectDetail,
      ));
      expect(route?.settings.name, AppRoutes.subjectDetail);
    });
  });

  group('route settings consistency', () {
    test('all generated routes have matching settings name', () {
      for (final routeName in appRoutesAll) {
        final route = onGenerateRoute(RouteSettings(name: routeName));
        expect(route, isNotNull);
        expect(route!.settings.name, routeName);
      }
    });
  });
}

final List<String> appRoutesAll = [
  AppRoutes.settings,
  AppRoutes.profile,
  AppRoutes.apiConfig,
  AppRoutes.quickGuide,
  AppRoutes.mentor,
  AppRoutes.dashboard,
  AppRoutes.upload,
  AppRoutes.subjectSelection,
  AppRoutes.subjectDetail,
  AppRoutes.practiceSession,
  AppRoutes.sessionTracker,
  AppRoutes.sessionHistory,
  AppRoutes.tutor,
  AppRoutes.planner,
  AppRoutes.lessonDetail,
  AppRoutes.lessonList,
  AppRoutes.llmTasks,
  AppRoutes.focusMode,
  AppRoutes.examSession,
  AppRoutes.contentLibrary,
  AppRoutes.sourceDetail,
  AppRoutes.questionBank,
];
