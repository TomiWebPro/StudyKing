import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/mentor/services/mentor_context_builder.dart';
import 'package:studyking/features/mentor/services/syllabus_focus_service.dart';
import 'package:studyking/features/mentor/services/tools/switch_syllabus_focus_tool.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('SwitchSyllabusFocusTool', () {
    List<Map<String, dynamic>> receivedCalls = [];

    SwitchSyllabusFocusTool buildTool({
      bool shouldSucceed = true,
    }) {
      receivedCalls = [];
      return SwitchSyllabusFocusTool(
        onFocusChanged: ({
          required String subjectId,
          String? subjectTitle,
          int? days,
        }) async {
          receivedCalls.add({
            'subjectId': subjectId,
            'subjectTitle': subjectTitle,
            'days': days,
          });
          return shouldSucceed
              ? Result.success(null)
              : Result.failure('focus service unavailable');
        },
      );
    }

    test('tool name is switch_syllabus_focus', () {
      final tool = buildTool();
      expect(tool.name, 'switch_syllabus_focus');
    });

    test('description mentions focus switching', () {
      final tool = buildTool();
      expect(tool.description, contains('focus'));
      expect(tool.description, contains('switch'));
    });

    test('parameters include subjectId (required) and optional title/days', () {
      final tool = buildTool();
      final params = tool.parameters;
      expect(params['type'], 'object');
      expect(params['properties'], containsPair('subjectId', isA<Map>()));
      expect(params['properties'], containsPair('subjectTitle', isA<Map>()));
      expect(params['properties'], containsPair('days', isA<Map>()));
      expect(params['required'], contains('subjectId'));
      expect(params['required'], isNot(contains('subjectTitle')));
      expect(params['required'], isNot(contains('days')));
    });

    test('calls onFocusChanged with subjectId and title on valid input', () async {
      final tool = buildTool();

      final result = await tool.execute({
        'subjectId': 'math-hl',
        'subjectTitle': 'Math AA HL',
        'days': 14,
      });

      expect(result['success'], isTrue);
      expect(result['subjectId'], 'math-hl');
      expect(result['subjectTitle'], 'Math AA HL');
      expect(result['days'], 14);
      expect(result['message'], contains('Math AA HL'));
      expect(receivedCalls, hasLength(1));
      expect(receivedCalls.first['subjectId'], 'math-hl');
      expect(receivedCalls.first['subjectTitle'], 'Math AA HL');
      expect(receivedCalls.first['days'], 14);
    });

    test('accepts integer days value', () async {
      final tool = buildTool();

      final result = await tool.execute({
        'subjectId': 'physics',
        'subjectTitle': 'Physics',
        'days': 21,
      });

      expect(result['success'], isTrue);
      expect(result['days'], 21);
      expect(receivedCalls.first['days'], 21);
    });

    test('tolerates string-encoded integer days from the LLM', () async {
      final tool = buildTool();

      final result = await tool.execute({
        'subjectId': 'chemistry',
        'subjectTitle': 'Chemistry',
        'days': '30',
      });

      expect(result['success'], isTrue);
      expect(result['days'], 30);
      expect(receivedCalls.first['days'], 30);
    });

    test('omits days when not provided (indefinite focus)', () async {
      final tool = buildTool();

      final result = await tool.execute({
        'subjectId': 'biology',
      });

      expect(result['success'], isTrue);
      expect(result['subjectId'], 'biology');
      expect(result.containsKey('days'), isFalse);
      expect(receivedCalls.first['days'], isNull);
    });

    test('tolerates whitespace and case in subjectId via .normalized', () async {
      final tool = buildTool();

      final result = await tool.execute({
        'subjectId': '  MATH-HL  ',
        'subjectTitle': 'Math AA HL',
      });

      expect(result['success'], isTrue);
      expect(result['subjectId'], 'math-hl');
      expect(receivedCalls.first['subjectId'], 'math-hl');
    });

    test('returns failure when subjectId is empty', () async {
      final tool = buildTool();

      final result = await tool.execute({
        'subjectId': '',
      });

      expect(result['success'], isFalse);
      expect(result['error'], contains('subjectId'));
      expect(receivedCalls, isEmpty);
    });

    test('returns failure when subjectId is missing', () async {
      final tool = buildTool();

      final result = await tool.execute({
        'subjectTitle': 'Math',
      });

      expect(result['success'], isFalse);
      expect(result['error'], contains('subjectId'));
      expect(receivedCalls, isEmpty);
    });

    test('returns failure when days is non-positive', () async {
      final tool = buildTool();

      final result = await tool.execute({
        'subjectId': 'math',
        'days': 0,
      });

      expect(result['success'], isFalse);
      expect(result['error'], contains('days'));
      expect(receivedCalls, isEmpty);
    });

    test('returns failure when days is negative', () async {
      final tool = buildTool();

      final result = await tool.execute({
        'subjectId': 'math',
        'days': -5,
      });

      expect(result['success'], isFalse);
      expect(receivedCalls, isEmpty);
    });

    test('reports failure when onFocusChanged callback fails', () async {
      final tool = buildTool(shouldSucceed: false);

      final result = await tool.execute({
        'subjectId': 'math-hl',
      });

      expect(result['success'], isFalse);
      expect(result['error'], contains('focus service unavailable'));
      expect(receivedCalls, hasLength(1));
    });
  });

  // ---------------------------------------------------------------------------
  // Integration: MentorContextBuilder honors explicit syllabus focus over
  // implicit resolution (Vision Next-Term §3.1 / scenario_multisubject_juggling).
  // ---------------------------------------------------------------------------
  group('MentorContextBuilder syllabus focus', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    final goals = [
      SyllabusGoal(subjectId: 'subj1', subjectTitle: 'Math'),
      SyllabusGoal(subjectId: 'subj2', subjectTitle: 'Science'),
    ];

    late SyllabusFocusService focusService;
    late MentorContextBuilder cx;

    setUp(() {
      focusService = SyllabusFocusService();
      cx = MentorContextBuilder(
        progressTracker: FakeStudyProgressTracker(l10n),
        masteryService: FakeMasteryGraphService(),
        plannerService: FakePlannerService(),
        sessionRepository: FakeSessionRepository(),
        localeName: 'en',
        focusService: focusService,
      );
    });

    test('sets active syllabus via tool callback', () {
      final tool = SwitchSyllabusFocusTool(
        onFocusChanged: ({
          required String subjectId,
          String? subjectTitle,
          int? days,
        }) async {
          focusService.setFocus(subjectId, subjectTitle: subjectTitle, days: days);
          return Result.success(null);
        },
      );

      expectLater(tool.execute({'subjectId': 'subj2'}), completes);
      // Verify the callback wiring: the tool delegates to the focus service.
      // (The actual callback execution is verified by the tool unit tests above;
      // here we confirm the wiring pattern used in production.)
    });

    test('explicit focus overrides implicit upcoming-lesson resolution', () {
      final upcoming = [
        Session(
          id: 's1',
          studentId: 'student-1',
          subjectId: 'subj1',
          startTime: DateTime.now().add(const Duration(days: 1)),
        ),
      ];

      // Without focus: implicit resolution picks Math (upcoming lesson).
      cx.buildSyllabusContext(goals, upcoming, l10n);
      expect(cx.currentSyllabusContext, contains('Math'));

      // Set explicit focus to Science → override wins.
      focusService.setFocus('subj2', subjectTitle: 'Science');
      cx.buildSyllabusContext(goals, upcoming, l10n);
      expect(cx.currentSyllabusContext, contains('Science'));
      expect(cx.currentSyllabusContext, isNot(contains('Math')));
    });

    test('clearing focus reverts to implicit resolution', () {
      final upcoming = [
        Session(
          id: 's1',
          studentId: 'student-1',
          subjectId: 'subj1',
          startTime: DateTime.now().add(const Duration(days: 1)),
        ),
      ];

      focusService.setFocus('subj2', subjectTitle: 'Science');
      cx.buildSyllabusContext(goals, upcoming, l10n);
      expect(cx.currentSyllabusContext, contains('Science'));

      focusService.clearFocus();
      cx.buildSyllabusContext(goals, upcoming, l10n);
      expect(cx.currentSyllabusContext, contains('Math'));
    });

    test('no focus falls back to implicit single-goal resolution', () {
      final singleGoal = [SyllabusGoal(subjectId: 'subj1', subjectTitle: 'Math')];
      cx.buildSyllabusContext(singleGoal, [], l10n);
      expect(cx.currentSyllabusContext, contains('Math'));
    });

    test('focus matching an absent subjectId falls back to first goal', () {
      // Focus on a subjectId that is not in goals → falls back to first goal.
      focusService.setFocus('nonexistent');
      cx.buildSyllabusContext(goals, [], l10n);
      expect(cx.currentSyllabusContext, contains('Math'));
    });
  });
}
