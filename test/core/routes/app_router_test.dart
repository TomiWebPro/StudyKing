import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/routes/app_router.dart';

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
    test('llmTasks', () => expect(AppRoutes.llmTasks, '/llm-tasks'));
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
      );
      expect(args.subjectId, 's1');
      expect(args.topicId, 't1');
      expect(args.questionCount, 20);
      expect(args.isSpacedRepetition, true);
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

    group('unknown route', () {
      test('returns null for unknown route name', () {
        expect(
          onGenerateRoute(const RouteSettings(name: '/unknown')),
          isNull,
        );
      });

      test('returns null for empty route name', () {
        expect(
          onGenerateRoute(const RouteSettings(name: '')),
          isNull,
        );
      });

      test('returns null for null route name', () {
        expect(
          onGenerateRoute(const RouteSettings(name: null)),
          isNull,
        );
      });
    });

    group('dashboard', () {
      test('returns route with Map args containing studentId', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.dashboard,
          arguments: <String, dynamic>{'studentId': 'student-123'},
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.dashboard);
      });

      test('returns route with Map args containing all keys', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.dashboard,
          arguments: <String, dynamic>{
            'studentId': 'student-123',
            'masteryService': null,
          },
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.dashboard);
      });

      test('returns route with empty Map args', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.dashboard,
          arguments: <String, dynamic>{},
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

      test('returns route with non-Map args using defaults', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.dashboard,
          arguments: 'invalid',
        ));
        expect(route, isNotNull);
        expect(route!.settings.name, AppRoutes.dashboard);
      });

      test('returns route with int args using defaults', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.dashboard,
          arguments: 42,
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

      test('returns null without args', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.subjectDetail,
        ));
        expect(route, isNull);
      });

      test('returns null with null args', () {
        final route = onGenerateRoute(const RouteSettings(
          name: AppRoutes.subjectDetail,
          arguments: null,
        ));
        expect(route, isNull);
      });

      test('returns null with string args', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.subjectDetail,
          arguments: 'wrong type',
        ));
        expect(route, isNull);
      });

      test('returns null with Map args instead of SubjectDetailArgs', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.subjectDetail,
          arguments: <String, dynamic>{'subjectId': 's1'},
        ));
        expect(route, isNull);
      });

      test('returns null with int args', () {
        final route = onGenerateRoute(RouteSettings(
          name: AppRoutes.subjectDetail,
          arguments: 123,
        ));
        expect(route, isNull);
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

      test('returns null without args', () {
        expect(
          onGenerateRoute(const RouteSettings(name: AppRoutes.practiceSession)),
          isNull,
        );
      });

      test('returns null with null args', () {
        expect(
          onGenerateRoute(const RouteSettings(
            name: AppRoutes.practiceSession,
            arguments: null,
          )),
          isNull,
        );
      });

      test('returns null with string args', () {
        expect(
          onGenerateRoute(RouteSettings(
            name: AppRoutes.practiceSession,
            arguments: 'wrong type',
          )),
          isNull,
        );
      });

      test('returns null with Map args instead of PracticeSessionArgs', () {
        expect(
          onGenerateRoute(RouteSettings(
            name: AppRoutes.practiceSession,
            arguments: <String, dynamic>{'subjectId': 's1'},
          )),
          isNull,
        );
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

      test('returns null without args', () {
        expect(
          onGenerateRoute(const RouteSettings(name: AppRoutes.tutor)),
          isNull,
        );
      });

      test('returns null with null args', () {
        expect(
          onGenerateRoute(const RouteSettings(
            name: AppRoutes.tutor,
            arguments: null,
          )),
          isNull,
        );
      });

      test('returns null with string args', () {
        expect(
          onGenerateRoute(RouteSettings(
            name: AppRoutes.tutor,
            arguments: 'wrong type',
          )),
          isNull,
        );
      });

      test('returns null with Map args instead of TutorArgs', () {
        expect(
          onGenerateRoute(RouteSettings(
            name: AppRoutes.tutor,
            arguments: <String, dynamic>{'topicId': 't1'},
          )),
          isNull,
        );
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
      final args = <String, dynamic>{'key': 'value'};
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
  });

  group('route settings consistency', () {
    test('all generated routes have matching settings name', () {
      for (final routeName in appRoutesAll) {
        final route = onGenerateRoute(RouteSettings(name: routeName));
        if (route != null) {
          expect(route.settings.name, routeName);
        }
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
  AppRoutes.llmTasks,
];
