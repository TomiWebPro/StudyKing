import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 17)
class TopicDependency extends HiveObject {
  @HiveField(0)
  final String topicId;

  @HiveField(1)
  final List<String> prerequisites;

  @HiveField(2)
  final List<String> downstreamTopics;

  @HiveField(3)
  final double syllabusWeight;

  @HiveField(4)
  final Map<String, double> dependencyWeights;

  @HiveField(5)
  final int estimatedQuestions;

  @HiveField(6)
  final int estimatedMinutes;

  @HiveField(7)
  final double masteryThreshold;

  @HiveField(8)
  final bool isRequired;

  @HiveField(9)
  final String? parentTopicId;

  @HiveField(10)
  final int sortOrder;

  TopicDependency({
    required this.topicId,
    this.prerequisites = const [],
    this.downstreamTopics = const [],
    this.syllabusWeight = 1.0,
    this.dependencyWeights = const {},
    this.estimatedQuestions = 10,
    this.estimatedMinutes = 30,
    this.masteryThreshold = 0.8,
    this.isRequired = true,
    this.parentTopicId,
    this.sortOrder = 0,
  });

  bool isReady(List<String> completedTopicIds, double? readinessScore) {
    if (prerequisites.isEmpty) return true;
    final allPrereqsMet = prerequisites.every((p) => completedTopicIds.contains(p));
    if (!allPrereqsMet) return false;
    if (readinessScore != null && readinessScore < masteryThreshold) return false;
    return true;
  }

  double calculatePriority({
    required double masteryState,
    required bool isPrerequisite,
    required int downstreamCount,
  }) {
    double priority = syllabusWeight;

    if (masteryState < masteryThreshold) {
      priority *= 1 + (masteryThreshold - masteryState);
    }

    if (isPrerequisite) {
      priority *= 1.5;
    }

    priority *= (1 + downstreamCount * 0.1);

    return priority.clamp(0.0, 10.0);
  }

  Map<String, dynamic> toJson() => {
    'topicId': topicId,
    'prerequisites': prerequisites,
    'downstreamTopics': downstreamTopics,
    'syllabusWeight': syllabusWeight,
    'dependencyWeights': dependencyWeights,
    'estimatedQuestions': estimatedQuestions,
    'estimatedMinutes': estimatedMinutes,
    'masteryThreshold': masteryThreshold,
    'isRequired': isRequired,
    'parentTopicId': parentTopicId,
    'sortOrder': sortOrder,
  };

  factory TopicDependency.fromJson(Map<String, dynamic> json) => TopicDependency(
    topicId: json['topicId'],
    prerequisites: List<String>.from(json['prerequisites'] ?? []),
    downstreamTopics: List<String>.from(json['downstreamTopics'] ?? []),
    syllabusWeight: (json['syllabusWeight'] ?? 1.0).toDouble(),
    dependencyWeights: json['dependencyWeights'] != null
        ? Map<String, double>.from(json['dependencyWeights'])
        : {},
    estimatedQuestions: json['estimatedQuestions'] ?? 10,
    estimatedMinutes: json['estimatedMinutes'] ?? 30,
    masteryThreshold: (json['masteryThreshold'] ?? 0.8).toDouble(),
    isRequired: json['isRequired'] ?? true,
    parentTopicId: json['parentTopicId'],
    sortOrder: json['sortOrder'] ?? 0,
  );

  factory TopicDependency.fromTopic({
    required String topicId,
    required List<String> childTopicIds,
    String? parentId,
    int? sortOrder,
  }) => TopicDependency(
    topicId: topicId,
    downstreamTopics: childTopicIds,
    parentTopicId: parentId,
    sortOrder: sortOrder ?? 0,
  );

  TopicDependency copyWith({
    String? topicId,
    List<String>? prerequisites,
    List<String>? downstreamTopics,
    double? syllabusWeight,
    Map<String, double>? dependencyWeights,
    int? estimatedQuestions,
    int? estimatedMinutes,
    double? masteryThreshold,
    bool? isRequired,
    String? parentTopicId,
    int? sortOrder,
  }) {
    return TopicDependency(
      topicId: topicId ?? this.topicId,
      prerequisites: prerequisites ?? this.prerequisites,
      downstreamTopics: downstreamTopics ?? this.downstreamTopics,
      syllabusWeight: syllabusWeight ?? this.syllabusWeight,
      dependencyWeights: dependencyWeights ?? this.dependencyWeights,
      estimatedQuestions: estimatedQuestions ?? this.estimatedQuestions,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      masteryThreshold: masteryThreshold ?? this.masteryThreshold,
      isRequired: isRequired ?? this.isRequired,
      parentTopicId: parentTopicId ?? this.parentTopicId,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}