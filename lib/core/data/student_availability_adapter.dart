import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/planner/data/models/student_availability_model.dart';

class StudentAvailabilityModelAdapter extends TypeAdapter<StudentAvailabilityModel> {
  @override
  final int typeId = 35;

  @override
  StudentAvailabilityModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudentAvailabilityModel(
      studentId: fields[0] as String,
      preferredStudyDays: fields[1] != null
          ? List<int>.from(fields[1] as List)
          : const [1, 2, 3, 4, 5, 6, 7],
      preferredStartHour: fields[2] as int? ?? 9,
      preferredEndHour: fields[3] as int? ?? 21,
      maxSessionsPerDay: fields[4] as int? ?? 3,
      defaultSessionDurationMinutes: fields[5] as int? ?? 30,
      blackoutDates: fields[6] != null
          ? List<DateTime>.from(fields[6] as List)
          : const [],
    );
  }

  @override
  void write(BinaryWriter writer, StudentAvailabilityModel obj) {
    writer.writeByte(7);
    writer.writeByte(0);
    writer.write(obj.studentId);
    writer.writeByte(1);
    writer.write(obj.preferredStudyDays);
    writer.writeByte(2);
    writer.write(obj.preferredStartHour);
    writer.writeByte(3);
    writer.write(obj.preferredEndHour);
    writer.writeByte(4);
    writer.write(obj.maxSessionsPerDay);
    writer.writeByte(5);
    writer.write(obj.defaultSessionDurationMinutes);
    writer.writeByte(6);
    writer.write(obj.blackoutDates);
  }
}
