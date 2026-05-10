// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_model.dart';

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 10;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      id: fields[0] as String,
      name: fields[1] as String,
      studentId: fields[2] as String?,
      avatarUrl: fields[3] as String?,
      learningGoal: fields[4] as String?,
      preferredStudyTime: fields[5] as String?,
      notificationsEnabled: fields[6] as bool? ?? true,
      language: fields[7] as String? ?? 'en',
      accessibilitySettings: fields[8] as String? ?? 'default',
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.studentId)
      ..writeByte(3)
      ..write(obj.avatarUrl)
      ..writeByte(4)
      ..write(obj.learningGoal)
      ..writeByte(5)
      ..write(obj.preferredStudyTime)
      ..writeByte(6)
      ..write(obj.notificationsEnabled)
      ..writeByte(7)
      ..write(obj.language)
      ..writeByte(8)
      ..write(obj.accessibilitySettings);
  }
}
