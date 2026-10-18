import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/mentor/services/tools/add_subject_to_plan_tool.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

import 'test_helpers.dart';

/// Unit tests for [AddSubjectToPlanTool], mirroring the SwitchSyllabusFocusTool
/// callback + recording-stub pattern. The recording callback delegates to the
/// hand-written [FakePlannerService] so the test literally exercises
/// `PlannerService.addSubjectToPlan` with the SyllabusGoal the tool built.
void main() {
  setUpAll(() async {
    await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('AddSubjectToPlanTool', () {
    // Shared fake that records every addSubjectToPlan invocation.
    final fake = FakePlannerService(sampleLearningPlan(studentId: 'add-student'));

    AddSubjectToPlanTool buildTool() {
      fake.recordedAddSubjectGoals.clear();
      fake.addSubjectToPlanShouldFail = false;
      return AddSubjectToPlanTool(
        onAddSubject: ({required SyllabusGoal newGoal}) async {
          // Mirrors the production wiring (load existing plan -> addSubjectToPlan)
          // but the test supplies the existing plan directly.
          return fake.addSubjectToPlan(
            newGoal: newGoal,
            existingPlan: sampleLearningPlan(studentId: 'add-student'),
          );
        },
      );
    }

    test('tool name is add_subject_to_plan', () {
      final tool = buildTool();
      expect(tool.name, 'add_subject_to_plan');
    });

    test('description explains adding a new subject to an existing plan', () {
      final tool = buildTool();
      expect(tool.description, contains('existing'));
      expect(tool.description, contains('subject'));
    });

    test('parameters include subjectId (required) and optional fields', () {
      final tool = buildTool();
      final params = tool.parameters;
      expect(params['type'], 'object');
      expect(params['properties'], containsPair('subjectId', isA<Map>()));
      expect(params['properties'], containsPair('subjectTitle', isA<Map>()));
      expect(params['properties'], containsPair('targetDays', isA<Map>()));
      expect(params['properties'],
          containsPair('targetHoursPerDay', isA<Map>()));
      expect(params['properties'], containsPair('syllabusCode', isA<Map>()));
      expect(params['required'], contains('subjectId'));
    });

    test('builds a SyllabusGoal and calls addSubjectToPlan via the callback',
        () async {
      final tool = buildTool();

      final result = await tool.execute({
        'subjectId': 'biology',
        'subjectTitle': 'Biology',
        'targetDays': 90,
        'targetHoursPerDay': 2,
        'syllabusCode': 'IB-0610',
      });

      expect(result['success'], isTrue);
      expect(result['subjectId'], 'biology');
      expect(result['subjectTitle'], 'Biology');
      expect(result['planId'], 'add-student');
      expect(result['totalDays'], 2);
      expect(result['message'], contains('Biology'));

      // The fake PlannerService recorded the exact goal handed to
      // addSubjectToPlan.
      expect(fake.recordedAddSubjectGoals, hasLength(1));
      final goal = fake.recordedAddSubjectGoals.first;
      expect(goal.subjectId, 'biology');
      expect(goal.subjectTitle, 'Biology');
      expect(goal.targetDays, 90);
      expect(goal.targetHoursPerDay, 2);
      expect(goal.syllabusCode, 'IB-0610');
    });

    test('applies defaults for targetDays and targetHoursPerDay when omitted',
        () async {
      final tool = buildTool();

      final result = await tool.execute({
        'subjectId': 'biology',
        'subjectTitle': 'Biology',
      });

      expect(result['success'], isTrue);
      expect(fake.recordedAddSubjectGoals, hasLength(1));
      expect(fake.recordedAddSubjectGoals.first.targetDays, 30);
      expect(fake.recordedAddSubjectGoals.first.targetHoursPerDay, 1);
    });

    test('tolerates string-encoded integers from the LLM', () async {
      final tool = buildTool();

      final result = await tool.execute({
        'subjectId': 'math-hl',
        'targetDays': '90',
        'targetHoursPerDay': '2',
      });

      expect(result['success'], isTrue);
      expect(fake.recordedAddSubjectGoals.first.targetDays, 90);
      expect(fake.recordedAddSubjectGoals.first.targetHoursPerDay, 2);
    });

    test('tolerates whitespace and case in subjectId via .normalized',
        () async {
      final tool = buildTool();

      final result = await tool.execute({'subjectId': '  Biology-HL  '});

      expect(result['success'], isTrue);
      expect(result['subjectId'], 'biology-hl');
      expect(fake.recordedAddSubjectGoals.first.subjectId, 'biology-hl');
    });

    test('returns failure when subjectId is empty', () async {
      final tool = buildTool();

      final result = await tool.execute({'subjectId': ''});

      expect(result['success'], isFalse);
      expect(result['error'], contains('subjectId'));
      expect(fake.recordedAddSubjectGoals, isEmpty);
    });

    test('returns failure when subjectId is missing', () async {
      final tool = buildTool();

      final result = await tool.execute({'subjectTitle': 'Biology'});

      expect(result['success'], isFalse);
      expect(result['error'], contains('subjectId'));
      expect(fake.recordedAddSubjectGoals, isEmpty);
    });

    test('returns failure when targetDays is non-positive', () async {
      final tool = buildTool();

      final result =
          await tool.execute({'subjectId': 'bio', 'targetDays': 0});

      expect(result['success'], isFalse);
      expect(result['error'], contains('targetDays'));
      expect(fake.recordedAddSubjectGoals, isEmpty);
    });

    test('returns failure when targetHoursPerDay is non-positive', () async {
      final tool = buildTool();

      final result = await tool.execute({
        'subjectId': 'bio',
        'targetHoursPerDay': 0,
      });

      expect(result['success'], isFalse);
      expect(result['error'], contains('targetHoursPerDay'));
      expect(fake.recordedAddSubjectGoals, isEmpty);
    });

    test('reports failure when addSubjectToPlan callback fails', () async {
      final tool = buildTool();
      fake.addSubjectToPlanShouldFail = true;

      final result = await tool.execute({
        'subjectId': 'biology',
        'subjectTitle': 'Biology',
      });

      expect(result['success'], isFalse);
      expect(result['error'], contains('addSubjectToPlan failed'));
      // The goal reached the callback (addSubjectToPlan) before it failed.
      expect(fake.recordedAddSubjectGoals, hasLength(1));
    });
  });
}
