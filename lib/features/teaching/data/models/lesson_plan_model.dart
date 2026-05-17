import 'dart:convert';
import '../../../../core/utils/logger.dart';

enum LessonSectionType { explanation, exercise, review, summary, quiz }

class LessonSection {
  final String title;
  final int durationMinutes;
  final LessonSectionType type;

  const LessonSection({
    required this.title,
    required this.durationMinutes,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'duration': durationMinutes,
    'type': type.name,
  };

  factory LessonSection.fromJson(Map<String, dynamic> json) {
    return LessonSection(
      title: json['title'] as String? ?? '',
      durationMinutes: json['duration'] as int? ?? 10,
      type: LessonSectionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => LessonSectionType.explanation,
      ),
    );
  }
}

class LessonPlan {
  static final Logger _logger = const Logger('LessonPlan');

  final List<String> goals;
  final List<LessonSection> sections;
  final List<String> checkpoints;
  final int estimatedDifficulty;
  final int totalDurationMinutes;

  LessonPlan({
    required this.goals,
    required this.sections,
    required this.checkpoints,
    required this.estimatedDifficulty,
  }) : totalDurationMinutes = sections.fold(0, (sum, s) => sum + s.durationMinutes);

  static LessonPlan? fromJson(String json) {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      if (data['goals'] == null || (data['goals'] as List).isEmpty) return null;
      if (data['sections'] == null || (data['sections'] as List).isEmpty) return null;
      final sections = (data['sections'] as List)
          .map((s) => LessonSection.fromJson(s as Map<String, dynamic>))
          .toList();
      if (sections.any((s) => s.durationMinutes <= 0)) return null;
      return LessonPlan(
        goals: List<String>.from(data['goals']),
        sections: sections,
        checkpoints: List<String>.from(data['checkpoints'] ?? []),
        estimatedDifficulty: data['estimatedDifficulty'] as int? ?? 3,
      );
    } catch (e) {
      _logger.w('Failed to parse lesson plan JSON', e);
      return null;
    }
  }

  // TODO: i18n - callers should override with localized values from ARB keys
  static LessonPlan defaultPlan(int durationMinutes) {
    return LessonPlan(
      goals: ['Understand the topic'],
      sections: [
        LessonSection(title: 'Introduction', durationMinutes: 5, type: LessonSectionType.explanation),
        LessonSection(title: 'Main Content', durationMinutes: (durationMinutes - 15).clamp(5, 120), type: LessonSectionType.explanation),
        LessonSection(title: 'Practice', durationMinutes: 10, type: LessonSectionType.exercise),
      ],
      checkpoints: ['Lesson started', 'Topic covered', 'Practice completed'],
      estimatedDifficulty: 3,
    );
  }

  String toJsonString() => jsonEncode({
    'goals': goals,
    'sections': sections.map((s) => s.toJson()).toList(),
    'checkpoints': checkpoints,
    'estimatedDifficulty': estimatedDifficulty,
  });
}
