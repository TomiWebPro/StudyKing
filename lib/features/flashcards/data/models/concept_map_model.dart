import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 40)
class ConceptMap extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String sourceId;

  @HiveField(2)
  final String topicId;

  @HiveField(3)
  final String subjectId;

  @HiveField(4)
  final String title;

  @HiveField(5)
  final List<ConceptNode> nodes;

  @HiveField(6)
  final List<ConceptEdge> edges;

  @HiveField(7)
  final DateTime createdAt;

  ConceptMap({
    required this.id,
    required this.sourceId,
    required this.topicId,
    required this.subjectId,
    required this.title,
    required this.nodes,
    required this.edges,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceId': sourceId,
    'topicId': topicId,
    'subjectId': subjectId,
    'title': title,
    'nodes': nodes.map((n) => n.toJson()).toList(),
    'edges': edges.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory ConceptMap.fromJson(Map<String, dynamic> json) => ConceptMap(
    id: json['id'] as String? ?? '',
    sourceId: json['sourceId'] as String? ?? '',
    topicId: json['topicId'] as String? ?? '',
    subjectId: json['subjectId'] as String? ?? '',
    title: json['title'] as String? ?? '',
    nodes: (json['nodes'] as List<dynamic>?)
            ?.map((n) => ConceptNode.fromJson(n as Map<String, dynamic>))
            .toList() ??
        [],
    edges: (json['edges'] as List<dynamic>?)
            ?.map((e) => ConceptEdge.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

@HiveType(typeId: 41)
class ConceptNode extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String label;

  @HiveField(2)
  final String? description;

  ConceptNode({
    required this.id,
    required this.label,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'description': description,
  };

  factory ConceptNode.fromJson(Map<String, dynamic> json) => ConceptNode(
    id: json['id'] as String? ?? '',
    label: json['label'] as String? ?? '',
    description: json['description'] as String?,
  );
}

@HiveType(typeId: 42)
class ConceptEdge extends HiveObject {
  @HiveField(0)
  final String fromId;

  @HiveField(1)
  final String toId;

  @HiveField(2)
  final String relationship;

  ConceptEdge({
    required this.fromId,
    required this.toId,
    required this.relationship,
  });

  Map<String, dynamic> toJson() => {
    'fromId': fromId,
    'toId': toId,
    'relationship': relationship,
  };

  factory ConceptEdge.fromJson(Map<String, dynamic> json) => ConceptEdge(
    fromId: json['fromId'] as String? ?? '',
    toId: json['toId'] as String? ?? '',
    relationship: json['relationship'] as String? ?? '',
  );
}
