import 'package:hive_flutter/hive_flutter.dart';
import '../models/question_evaluation_model.dart';

class QuestionEvaluationAdapter extends TypeAdapter<QuestionEvaluation> {
  @override
  final int typeId = 14;

  @override
  QuestionEvaluation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuestionEvaluation(
      questionId: fields[0] as String,
      correctAnswer: fields[1] as String,
      acceptableAnswers: (fields[2] as List?)?.cast<String>() ?? [],
      evaluationType: EvaluationType.values[fields[3] as int? ?? 0],
      explanation: fields[4] as String?,
      steps: (fields[5] as List?)?.cast<EvaluationStep>(),
      maxPoints: fields[6] as double?,
      metadata: fields[7] != null ? Map<String, dynamic>.from(fields[7] as Map) : null,
      version: fields[8] as int? ?? 1,
    );
  }

  @override
  void write(BinaryWriter writer, QuestionEvaluation obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.questionId)
      ..writeByte(1)
      ..write(obj.correctAnswer)
      ..writeByte(2)
      ..write(obj.acceptableAnswers)
      ..writeByte(3)
      ..write(obj.evaluationType.index)
      ..writeByte(4)
      ..write(obj.explanation)
      ..writeByte(5)
      ..write(obj.steps)
      ..writeByte(6)
      ..write(obj.maxPoints)
      ..writeByte(7)
      ..write(obj.metadata)
      ..writeByte(8)
      ..write(obj.version);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionEvaluationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EvaluationStepAdapter extends TypeAdapter<EvaluationStep> {
  @override
  final int typeId = 15;

  @override
  EvaluationStep read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EvaluationStep(
      stepNumber: fields[0] as String,
      requiredAnswer: fields[1] as String,
      points: fields[2] as double,
      description: fields[3] as String?,
      partialCredit: fields[4] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, EvaluationStep obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.stepNumber)
      ..writeByte(1)
      ..write(obj.requiredAnswer)
      ..writeByte(2)
      ..write(obj.points)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.partialCredit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationStepAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}