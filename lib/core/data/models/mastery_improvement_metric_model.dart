import 'mastery_state_model.dart';

class MasteryImprovementMetric {
  final DateTime date;
  final String studentId;
  final String topicId;
  final double previousAccuracy;
  final double currentAccuracy;
  final double accuracyDelta;
  final double previousMasteryLevel;
  final double currentMasteryLevel;
  final MasteryLevel previousLevel;
  final MasteryLevel currentLevel;
  final Map<String, dynamic>? metadata;

  MasteryImprovementMetric({
    required this.date,
    required this.studentId,
    required this.topicId,
    required this.previousAccuracy,
    required this.currentAccuracy,
    required this.accuracyDelta,
    required this.previousMasteryLevel,
    required this.currentMasteryLevel,
    required this.previousLevel,
    required this.currentLevel,
    this.metadata,
  });

  bool get leveledUp => currentLevel.index > previousLevel.index;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'studentId': studentId,
    'topicId': topicId,
    'previousAccuracy': previousAccuracy,
    'currentAccuracy': currentAccuracy,
    'accuracyDelta': accuracyDelta,
    'previousMasteryLevel': previousMasteryLevel,
    'currentMasteryLevel': currentMasteryLevel,
    'previousLevel': previousLevel.index,
    'currentLevel': currentLevel.index,
    'leveledUp': leveledUp,
    'metadata': metadata,
  };
}
