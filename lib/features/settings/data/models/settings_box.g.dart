// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_box.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsBoxAdapter extends TypeAdapter<SettingsBox> {
  @override
  final int typeId = 4;

  @override
  SettingsBox read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsBox(
      apiKey: fields[0] as String,
      apiBaseUrl: fields[1] as String,
      selectedModel: fields[2] as String,
      themeMode: fields[3] as int,
      fontSize: fields[4] as double,
      totalSessionCount: fields[5] as int,
      totalStudyTimeMs: fields[6] as int,
      totalQuestions: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsBox obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.apiKey)
      ..writeByte(1)
      ..write(obj.apiBaseUrl)
      ..writeByte(2)
      ..write(obj.selectedModel)
      ..writeByte(3)
      ..write(obj.themeMode)
      ..writeByte(4)
      ..write(obj.fontSize)
      ..writeByte(5)
      ..write(obj.totalSessionCount)
      ..writeByte(6)
      ..write(obj.totalStudyTimeMs)
      ..writeByte(7)
      ..write(obj.totalQuestions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsBoxAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProfileDataAdapter extends TypeAdapter<ProfileData> {
  @override
  final int typeId = 5;

  @override
  ProfileData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProfileData(
      id: fields[0] as String,
      name: fields[1] as String,
      studentId: fields[2] as String?,
      avatarIcon: fields[3] as String?,
      learningGoal: fields[4] as String?,
      preferredStudyTime: fields[5] as String?,
      notificationsEnabled: fields[6] as bool,
      language: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ProfileData obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.studentId)
      ..writeByte(3)
      ..write(obj.avatarIcon)
      ..writeByte(4)
      ..write(obj.learningGoal)
      ..writeByte(5)
      ..write(obj.preferredStudyTime)
      ..writeByte(6)
      ..write(obj.notificationsEnabled)
      ..writeByte(7)
      ..write(obj.language);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
