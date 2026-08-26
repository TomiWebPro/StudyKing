import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/providers/service_providers.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/practice/presentation/widgets/weak_areas_sheet.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class FakeMasteryGraphService extends MasteryGraphService {
  static final Logger _logger = const Logger('FakeMasteryGraphService');
  final List<MasteryState> weakTopics;

  FakeMasteryGraphService({this.weakTopics = const []});

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    _logger.w('FakeMasteryGraphService.getWeakTopics called for $studentId');
    return Result.success(weakTopics);
  }
}

class FakeStudentIdService extends StudentIdService {
  @override
  Result<String> getStudentId() => Result.success('test-student');
}

Widget _buildTestApp(Widget child, FakeMasteryGraphService masteryService) {
  return ProviderScope(
    overrides: [
      studentIdServiceProvider.overrideWithValue(FakeStudentIdService()),
      masteryGraphServiceProvider.overrideWithValue(masteryService),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

Subject _subject({required String id, required List<String> topicIds}) =>
    Subject(id: id, name: id, topicIds: topicIds, createdAt: DateTime(2020));

MasteryState _weakTopic(String topicId) => MasteryState(
      studentId: 'test-student',
      topicId: topicId,
      lastAttempt: DateTime(2020),
      lastUpdated: DateTime(2020),
    );

void main() {
  group('WeakAreasSheet', () {
    testWidgets('shows only subjects with weak topics and a count badge',
        (tester) async {
      final weakSubject = _subject(
        id: 'Mathematics',
        topicIds: ['t1', 't2'],
      );
      final strongSubject = _subject(
        id: 'Physics',
        topicIds: ['t3'],
      );

      await tester.pumpWidget(_buildTestApp(
        WeakAreasSheet(
          subjects: [weakSubject, strongSubject],
          onSubjectSelected: (_) {},
        ),
        FakeMasteryGraphService(
          weakTopics: [_weakTopic('t1')],
        ),
      ));
      // Allow the async weak-topics fetch to resolve.
      await tester.pumpAndSettle();

      // Only the weak subject is shown: Physics (no weak topics) is filtered out.
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Physics'), findsNothing);

      // The weak-topic count annotation is present.
      expect(find.text('1 weak topic'), findsWidgets);
    });

    testWidgets('calls onSubjectSelected with the weak subject', (tester) async {
      Subject? selected;
      final weakSubject = _subject(
        id: 'Mathematics',
        topicIds: ['t1', 't2'],
      );

      await tester.pumpWidget(_buildTestApp(
        WeakAreasSheet(
          subjects: [weakSubject],
          onSubjectSelected: (s) => selected = s,
        ),
        FakeMasteryGraphService(weakTopics: [_weakTopic('t1')]),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mathematics'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.id, 'Mathematics');
    });

    testWidgets('shows noWeakAreasFound empty state when no weak topics exist',
        (tester) async {
      final subjects = [
        _subject(id: 'Mathematics', topicIds: ['t1']),
        _subject(id: 'Physics', topicIds: ['t2']),
      ];

      await tester.pumpWidget(_buildTestApp(
        WeakAreasSheet(
          subjects: subjects,
          onSubjectSelected: (_) {},
        ),
        FakeMasteryGraphService(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Mathematics'), findsNothing);
      expect(find.text('Physics'), findsNothing);
      expect(find.text('No weak areas found. Keep up the great work!'),
          findsOneWidget);
    });

    testWidgets('static show displays the weak-areas filtered sheet',
        (tester) async {
      final weakSubject = _subject(
        id: 'Mathematics',
        topicIds: ['t1'],
      );
      final strongSubject = _subject(
        id: 'Physics',
        topicIds: ['t2'],
      );
      Subject? selected;

      await tester.pumpWidget(_buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              WeakAreasSheet.show(
                context,
                subjects: [weakSubject, strongSubject],
                onSubjectSelected: (s) => selected = s,
              );
            },
            child: const Text('Show Sheet'),
          ),
        ),
        FakeMasteryGraphService(weakTopics: [_weakTopic('t1')]),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Physics'), findsNothing);

      await tester.tap(find.text('Mathematics'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.id, 'Mathematics');
    });
  });
}
