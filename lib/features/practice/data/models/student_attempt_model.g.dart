// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_attempt_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentAttemptAdapter extends TypeAdapter<StudentAttempt> {
  @override
  final int typeId = 24;

  @override
  StudentAttempt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudentAttempt(
      id: fields[0] as String,
      studentId: fields[1] as String,
      questionId: fields[2] as String,
      subjectId: fields[3] as String,
      isCorrect: fields[4] == null ? false : fields[4] as bool,
      timeSpentMs: fields[5] == null ? 0 : fields[5] as int,
      confidence: fields[6] == null ? 3 : fields[6] as int,
      timestamp: fields[7] as DateTime,
      userAnswer: fields[8] == null ? '' : fields[8] as String,
      markschemeMatch: fields[9] as String?,
      lastDueDate: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, StudentAttempt obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.questionId)
      ..writeByte(3)
      ..write(obj.subjectId)
      ..writeByte(4)
      ..write(obj.isCorrect)
      ..writeByte(5)
      ..write(obj.timeSpentMs)
      ..writeByte(6)
      ..write(obj.confidence)
      ..writeByte(7)
      ..write(obj.timestamp)
      ..writeByte(8)
      ..write(obj.userAnswer)
      ..writeByte(9)
      ..write(obj.markschemeMatch)
      ..writeByte(10)
      ..write(obj.lastDueDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentAttemptAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
