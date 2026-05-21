import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/data/models/lesson_plan_model.dart';

void main() {
  group('LessonSection', () {
    test('creates section with valid params', () {
      final section = LessonSection(
        title: 'Introduction',
        durationMinutes: 10,
        type: LessonSectionType.explanation,
      );
      expect(section.title, 'Introduction');
      expect(section.durationMinutes, 10);
      expect(section.type, LessonSectionType.explanation);
    });

    test('serializes to JSON and back', () {
      final section = LessonSection(
        title: 'Practice',
        durationMinutes: 15,
        type: LessonSectionType.exercise,
      );
      final json = section.toJson();
      final restored = LessonSection.fromJson(json);
      expect(restored.title, section.title);
      expect(restored.durationMinutes, section.durationMinutes);
      expect(restored.type, section.type);
    });

    test('fromJson handles missing fields with defaults', () {
      final section = LessonSection.fromJson({});
      expect(section.title, '');
      expect(section.durationMinutes, 10);
      expect(section.type, LessonSectionType.explanation);
    });

    test('fromJson handles invalid type name with default', () {
      final section = LessonSection.fromJson({
        'title': 'Test',
        'duration': 20,
        'type': 'invalid_type_name',
      });
      expect(section.type, LessonSectionType.explanation);
    });

    test('supports all LessonSectionType values', () {
      for (final type in LessonSectionType.values) {
        final section = LessonSection(
          title: 'Section ${type.name}',
          durationMinutes: 10,
          type: type,
        );
        final json = section.toJson();
        final restored = LessonSection.fromJson(json);
        expect(restored.title, section.title);
        expect(restored.durationMinutes, section.durationMinutes);
        expect(restored.type, type);
      }
    });
  });

  group('LessonPlan', () {
    test('creates from valid JSON', () {
      final json = '''
      {
        "goals": ["Understand X", "Apply Y"],
        "sections": [
          {"title": "Intro", "duration": 10, "type": "explanation"},
          {"title": "Practice", "duration": 20, "type": "exercise"}
        ],
        "checkpoints": ["Check A", "Check B"],
        "estimatedDifficulty": 3
      }
      ''';
      final plan = LessonPlan.fromJson(json);
      expect(plan, isNotNull);
      expect(plan!.goals.length, 2);
      expect(plan.sections.length, 2);
      expect(plan.checkpoints.length, 2);
      expect(plan.estimatedDifficulty, 3);
      expect(plan.totalDurationMinutes, 30);
    });

    test('returns null for JSON with empty goals', () {
      final json = '''
      {
        "goals": [],
        "sections": [
          {"title": "Intro", "duration": 10, "type": "explanation"}
        ],
        "checkpoints": [],
        "estimatedDifficulty": 2
      }
      ''';
      expect(LessonPlan.fromJson(json), isNull);
    });

    test('returns null for JSON with null goals', () {
      final json = '''
      {
        "sections": [
          {"title": "Intro", "duration": 10, "type": "explanation"}
        ],
        "checkpoints": [],
        "estimatedDifficulty": 2
      }
      ''';
      expect(LessonPlan.fromJson(json), isNull);
    });

    test('returns null for JSON with empty sections', () {
      final json = '''
      {
        "goals": ["Goal 1"],
        "sections": [],
        "checkpoints": [],
        "estimatedDifficulty": 2
      }
      ''';
      expect(LessonPlan.fromJson(json), isNull);
    });

    test('returns null for JSON with null sections', () {
      final json = '''
      {
        "goals": ["Goal 1"],
        "checkpoints": [],
        "estimatedDifficulty": 2
      }
      ''';
      expect(LessonPlan.fromJson(json), isNull);
    });

    test('returns null for JSON with zero-duration section', () {
      final json = '''
      {
        "goals": ["Goal 1"],
        "sections": [
          {"title": "Intro", "duration": 0, "type": "explanation"}
        ],
        "checkpoints": [],
        "estimatedDifficulty": 2
      }
      ''';
      expect(LessonPlan.fromJson(json), isNull);
    });

    test('returns null for JSON with negative-duration section', () {
      final json = '''
      {
        "goals": ["Goal 1"],
        "sections": [
          {"title": "Intro", "duration": -5, "type": "explanation"}
        ],
        "checkpoints": [],
        "estimatedDifficulty": 2
      }
      ''';
      expect(LessonPlan.fromJson(json), isNull);
    });

    test('returns null for malformed JSON', () {
      expect(LessonPlan.fromJson('not json'), isNull);
    });

    test('returns null for JSON that is not a map', () {
      expect(LessonPlan.fromJson('"just a string"'), isNull);
      expect(LessonPlan.fromJson('42'), isNull);
    });

    test('defaultPlan generates valid plan with 45 min', () {
      final plan = LessonPlan.defaultPlan(
        45,
        goal: 'Understand the topic',
        introTitle: 'Introduction',
        mainTitle: 'Main Content',
        practiceTitle: 'Practice',
        checkpointStarted: 'Lesson started',
        checkpointCovered: 'Topic covered',
        checkpointCompleted: 'Practice completed',
      );
      expect(plan.goals, isNotEmpty);
      expect(plan.sections, isNotEmpty);
      expect(plan.checkpoints, isNotEmpty);
      expect(plan.totalDurationMinutes, 45);
    });

    test('defaultPlan clamps to minimum when duration is 0', () {
      final plan = LessonPlan.defaultPlan(
        0,
        goal: 'Understand the topic',
        introTitle: 'Introduction',
        mainTitle: 'Main Content',
        practiceTitle: 'Practice',
        checkpointStarted: 'Lesson started',
        checkpointCovered: 'Topic covered',
        checkpointCompleted: 'Practice completed',
      );
      expect(plan.totalDurationMinutes, 20);
      expect(plan.sections.length, 3);
    });

    test('defaultPlan clamps to minimum when duration is very small', () {
      final plan = LessonPlan.defaultPlan(
        3,
        goal: 'Understand the topic',
        introTitle: 'Introduction',
        mainTitle: 'Main Content',
        practiceTitle: 'Practice',
        checkpointStarted: 'Lesson started',
        checkpointCovered: 'Topic covered',
        checkpointCompleted: 'Practice completed',
      );
      expect(plan.sections[1].durationMinutes, 5);
    });

    test('defaultPlan clamps to maximum when duration is very large', () {
      final plan = LessonPlan.defaultPlan(
        300,
        goal: 'Understand the topic',
        introTitle: 'Introduction',
        mainTitle: 'Main Content',
        practiceTitle: 'Practice',
        checkpointStarted: 'Lesson started',
        checkpointCovered: 'Topic covered',
        checkpointCompleted: 'Practice completed',
      );
      expect(plan.sections[1].durationMinutes, 120);
    });

    test('defaultPlan handles negative duration', () {
      final plan = LessonPlan.defaultPlan(
        -10,
        goal: 'Understand the topic',
        introTitle: 'Introduction',
        mainTitle: 'Main Content',
        practiceTitle: 'Practice',
        checkpointStarted: 'Lesson started',
        checkpointCovered: 'Topic covered',
        checkpointCompleted: 'Practice completed',
      );
      expect(plan.sections[1].durationMinutes, 5);
    });

    test('defaultPlan accepts all custom parameters', () {
      final plan = LessonPlan.defaultPlan(
        60,
        goal: 'Master calculus',
        introTitle: 'Warm-up',
        mainTitle: 'Deep Dive',
        practiceTitle: 'Exercises',
        checkpointStarted: 'Begin',
        checkpointCovered: 'Covered',
        checkpointCompleted: 'Done',
      );
      expect(plan.goals, ['Master calculus']);
      expect(plan.sections[0].title, 'Warm-up');
      expect(plan.sections[1].title, 'Deep Dive');
      expect(plan.sections[2].title, 'Exercises');
      expect(plan.checkpoints, ['Begin', 'Covered', 'Done']);
      expect(plan.totalDurationMinutes, 60);
    });

    test('serializes to JSON string', () {
      final plan = LessonPlan.defaultPlan(
        30,
        goal: 'Understand the topic',
        introTitle: 'Introduction',
        mainTitle: 'Main Content',
        practiceTitle: 'Practice',
        checkpointStarted: 'Lesson started',
        checkpointCovered: 'Topic covered',
        checkpointCompleted: 'Practice completed',
      );
      final jsonStr = plan.toJsonString();
      expect(jsonStr, contains('"goals"'));
      expect(jsonStr, contains('"sections"'));

      final restored = LessonPlan.fromJson(jsonStr);
      expect(restored, isNotNull);
      expect(restored!.goals.length, plan.goals.length);
      expect(restored.totalDurationMinutes, plan.totalDurationMinutes);
    });

    test('estimatedDifficulty defaults to 3 when missing', () {
      final json = '''
      {
        "goals": ["Goal"],
        "sections": [
          {"title": "Intro", "duration": 10, "type": "explanation"}
        ],
        "checkpoints": []
      }
      ''';
      final plan = LessonPlan.fromJson(json);
      expect(plan, isNotNull);
      expect(plan!.estimatedDifficulty, 3);
    });

    test('checkpoints default to empty list when missing', () {
      final json = '''
      {
        "goals": ["Goal"],
        "sections": [
          {"title": "Intro", "duration": 10, "type": "explanation"}
        ]
      }
      ''';
      final plan = LessonPlan.fromJson(json);
      expect(plan, isNotNull);
      expect(plan!.checkpoints, isEmpty);
    });

    test('constructor computes totalDurationMinutes', () {
      final plan = LessonPlan(
        goals: ['Goal A', 'Goal B'],
        sections: [
          LessonSection(title: 'S1', durationMinutes: 15, type: LessonSectionType.explanation),
          LessonSection(title: 'S2', durationMinutes: 25, type: LessonSectionType.exercise),
        ],
        checkpoints: ['C1', 'C2'],
        estimatedDifficulty: 4,
      );
      expect(plan.totalDurationMinutes, 40);
      expect(plan.goals, ['Goal A', 'Goal B']);
      expect(plan.estimatedDifficulty, 4);
    });

    test('toJsonString roundtrip preserves all fields', () {
      final plan = LessonPlan(
        goals: ['Learn Topic'],
        sections: [
          LessonSection(title: 'Intro', durationMinutes: 5, type: LessonSectionType.explanation),
          LessonSection(title: 'Quiz', durationMinutes: 10, type: LessonSectionType.quiz),
          LessonSection(title: 'Summary', durationMinutes: 5, type: LessonSectionType.summary),
        ],
        checkpoints: [],
        estimatedDifficulty: 5,
      );
      final jsonStr = plan.toJsonString();
      expect(jsonStr, contains('"quiz"'));
      expect(jsonStr, contains('"summary"'));

      final restored = LessonPlan.fromJson(jsonStr);
      expect(restored, isNotNull);
      expect(restored!.sections.length, 3);
      expect(restored.sections[1].type, LessonSectionType.quiz);
      expect(restored.totalDurationMinutes, 20);
    });
  });
}
