import 'package:hive_flutter/hive_flutter.dart';
import '../models/topic_dependency_model.dart';

class TopicDependencyAdapter extends TypeAdapter<TopicDependency> {
  @override
  final int typeId = 17;

  @override
  TopicDependency read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TopicDependency(
      topicId: fields[0] as String,
      prerequisites: (fields[1] as List?)?.cast<String>() ?? [],
      downstreamTopics: (fields[2] as List?)?.cast<String>() ?? [],
      syllabusWeight: fields[3] as double? ?? 1.0,
      dependencyWeights: (fields[4] as Map?)?.map((k, v) => MapEntry(k as String, v as double)) ?? {},
      estimatedQuestions: fields[5] as int? ?? 10,
      estimatedMinutes: fields[6] as int? ?? 30,
      masteryThreshold: fields[7] as double? ?? 0.8,
      isRequired: fields[8] as bool? ?? true,
      parentTopicId: fields[9] as String?,
      sortOrder: fields[10] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, TopicDependency obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.topicId)
      ..writeByte(1)
      ..write(obj.prerequisites)
      ..writeByte(2)
      ..write(obj.downstreamTopics)
      ..writeByte(3)
      ..write(obj.syllabusWeight)
      ..writeByte(4)
      ..write(obj.dependencyWeights)
      ..writeByte(5)
      ..write(obj.estimatedQuestions)
      ..writeByte(6)
      ..write(obj.estimatedMinutes)
      ..writeByte(7)
      ..write(obj.masteryThreshold)
      ..writeByte(8)
      ..write(obj.isRequired)
      ..writeByte(9)
      ..write(obj.parentTopicId)
      ..writeByte(10)
      ..write(obj.sortOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicDependencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}