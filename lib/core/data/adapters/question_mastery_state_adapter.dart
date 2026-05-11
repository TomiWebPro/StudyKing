import 'package:hive_flutter/hive_flutter.dart';
import '../models/question_mastery_state_model.dart';

class QuestionMasteryStateAdapter extends TypeAdapter<QuestionMasteryState> {
  @override
  final int typeId = 18;

  @override
  QuestionMasteryState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuestionMasteryState(
      studentId: fields[0] as String,
      questionId: fields[1] as String,
      correctCount: fields[2] as int? ?? 0,
      incorrectCount: fields[3] as int? ?? 0,
      currentStreak: fields[4] as int? ?? 0,
      bestStreak: fields[5] as int? ?? 0,
      averageTimeMs: fields[6] as double? ?? 0.0,
      confidenceHistory: (fields[7] as List?)?.cast<int>() ?? [],
      lastAttempt: fields[8] as DateTime,
      lastCorrect: fields[9] as DateTime?,
      lastIncorrect: fields[10] as DateTime?,
      nextReview: fields[11] as DateTime?,
      masteryLevel: fields[12] as double? ?? 0.0,
      reviewUrgency: fields[13] as double? ?? 1.0,
      totalTimeMs: fields[14] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, QuestionMasteryState obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.studentId)
      ..writeByte(1)
      ..write(obj.questionId)
      ..writeByte(2)
      ..write(obj.correctCount)
      ..writeByte(3)
      ..write(obj.incorrectCount)
      ..writeByte(4)
      ..write(obj.currentStreak)
      ..writeByte(5)
      ..write(obj.bestStreak)
      ..writeByte(6)
      ..write(obj.averageTimeMs)
      ..writeByte(7)
      ..write(obj.confidenceHistory)
      ..writeByte(8)
      ..write(obj.lastAttempt)
      ..writeByte(9)
      ..write(obj.lastCorrect)
      ..writeByte(10)
      ..write(obj.lastIncorrect)
      ..writeByte(11)
      ..write(obj.nextReview)
      ..writeByte(12)
      ..write(obj.masteryLevel)
      ..writeByte(13)
      ..write(obj.reviewUrgency)
      ..writeByte(14)
      ..write(obj.totalTimeMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionMasteryStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}