import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/models/lesson_plan_model.dart';

void main() {
  group('LessonSection', () {
    test('creates section with valid params', () {
      final section = LessonSection(
        title: 'Introduction',
        durationMinutes: 10,
        type: LessonSectionType.explanation,
      );
      expect(section.title, equals('Introduction'));
      expect(section.durationMinutes, equals(10));
      expect(section.type, equals(LessonSectionType.explanation));
    });

    test('serializes to JSON and back', () {
      final section = LessonSection(
        title: 'Practice',
        durationMinutes: 15,
        type: LessonSectionType.exercise,
      );
      final json = section.toJson();
      final restored = LessonSection.fromJson(json);
      expect(restored.title, equals(section.title));
      expect(restored.durationMinutes, equals(section.durationMinutes));
      expect(restored.type, equals(section.type));
    });

    test('fromJson handles missing fields with defaults', () {
      final section = LessonSection.fromJson({});
      expect(section.title, equals(''));
      expect(section.durationMinutes, equals(10));
      expect(section.type, equals(LessonSectionType.explanation));
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
      expect(plan!.goals.length, equals(2));
      expect(plan.sections.length, equals(2));
      expect(plan.checkpoints.length, equals(2));
      expect(plan.estimatedDifficulty, equals(3));
      expect(plan.totalDurationMinutes, equals(30));
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

    test('returns null for malformed JSON', () {
      expect(LessonPlan.fromJson('not json'), isNull);
    });

    test('defaultPlan generates valid plan', () {
      final plan = LessonPlan.defaultPlan(45);
      expect(plan.goals, isNotEmpty);
      expect(plan.sections, isNotEmpty);
      expect(plan.checkpoints, isNotEmpty);
      expect(plan.totalDurationMinutes, equals(45));
    });

    test('serializes to JSON string', () {
      final plan = LessonPlan.defaultPlan(30);
      final jsonStr = plan.toJsonString();
      expect(jsonStr, contains('"goals"'));
      expect(jsonStr, contains('"sections"'));

      final restored = LessonPlan.fromJson(jsonStr);
      expect(restored, isNotNull);
      expect(restored!.goals.length, equals(plan.goals.length));
      expect(restored.totalDurationMinutes, equals(plan.totalDurationMinutes));
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
      expect(plan!.estimatedDifficulty, equals(3));
    });
  });
}
