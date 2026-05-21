import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';

class MarkschemeAdapter extends TypeAdapter<Markscheme> {
  @override
  final int typeId = 12;

  @override
  Markscheme read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Markscheme(
      questionId: fields[0] as String,
      correctAnswer: fields[1] as String,
      acceptableAnswers: (fields[2] as List?)?.cast<String>() ?? [],
      explanation: fields[3] as String?,
      markschemePoints: fields[4] as double?,
      steps: (fields[5] as List?)?.cast<MarkSchemeStep>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, Markscheme obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.questionId)
      ..writeByte(1)
      ..write(obj.correctAnswer)
      ..writeByte(2)
      ..write(obj.acceptableAnswers)
      ..writeByte(3)
      ..write(obj.explanation)
      ..writeByte(4)
      ..write(obj.markschemePoints)
      ..writeByte(5)
      ..write(obj.steps);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkschemeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MarkSchemeStepAdapter extends TypeAdapter<MarkSchemeStep> {
  @override
  final int typeId = 13;

  @override
  MarkSchemeStep read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MarkSchemeStep(
      stepNumber: fields[0] as String,
      requiredAnswer: fields[1] as String,
      points: fields[2] as double,
      description: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MarkSchemeStep obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.stepNumber)
      ..writeByte(1)
      ..write(obj.requiredAnswer)
      ..writeByte(2)
      ..write(obj.points)
      ..writeByte(3)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkSchemeStepAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
