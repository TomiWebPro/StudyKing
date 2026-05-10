import 'package:hive_flutter/hive_flutter.dart';

/// Markscheme model for correct answer with optional acceptable answers
/// Used in single/multiple choice questions to validate user responses
@HiveType(typeId: 5)
class Markscheme extends HiveObject {
  @HiveField(0)
  final String correctAnswer;

  @HiveField(1, defaultValue: [])
  final List<String> acceptableAnswers;

  @HiveField(2, defaultValue: '')
  final String explanation;

  @HiveField(3, defaultValue: [])
  final List<String> steps;

  Markscheme({
    required this.correctAnswer,
    this.acceptableAnswers = const [],
    this.explanation = '',
    this.steps = const [],
  });

  bool isMatch(String userAnswer) {
    final answer = userAnswer.toLowerCase().trim();
    final correct = correctAnswer.toLowerCase().trim();
    if (answer == correct) return true;

    for (final acceptable in acceptableAnswers) {
      if (acceptable.toLowerCase().trim() == answer) return true;
    }

    // Pattern matching for similar answers
    return _isSimilar(answer, correct);
  }

  bool _isSimilar(String answer, String correct) {
    // Simple fuzzy matching - can be enhanced with libraries
    final answerWords = answer.split(' ');
    final correctWords = correct.split(' ');

    if (answerWords.length >= correctWords.length * 0.8) {
      final matchingRatio = answerWords
          .where((word) => correctWords.contains(word))
          .length /
        correctWords.length;
      return matchingRatio > 0.7;
    }

    return false;
  }

  Map<String, dynamic> toJson() => {
        'correctAnswer': correctAnswer,
        'acceptableAnswers': acceptableAnswers,
        'explanation': explanation,
        'steps': steps,
      };

  factory Markscheme.fromJson(Map<String, dynamic> json) {
    return Markscheme(
      correctAnswer: json['correctAnswer'] ?? '',
      acceptableAnswers: List<String>.from(json['acceptableAnswers'] ?? []),
      explanation: json['explanation'] ?? '',
      steps: List<String>.from(json['steps'] ?? []),
    );
  }

  Markscheme copyWith({
    String? correctAnswer,
    List<String>? acceptableAnswers,
    String? explanation,
    List<String>? steps,
  }) {
    return Markscheme(
      correctAnswer: correctAnswer ?? this.correctAnswer,
      acceptableAnswers: acceptableAnswers ?? this.acceptableAnswers,
      explanation: explanation ?? this.explanation,
      steps: steps ?? this.steps,
    );
  }
}
