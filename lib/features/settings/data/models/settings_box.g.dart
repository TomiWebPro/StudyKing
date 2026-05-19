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
      studyRemindersEnabled: fields[8] as bool,
      requestTimeoutSeconds: fields[9] as int,
      sessionDurationMinutes: fields[10] as int,
      highContrastEnabled: fields[11] as bool,
      largeTouchTargets: fields[12] as bool,
      reduceMotion: fields[13] as bool,
      revisionRemindersEnabled: fields[14] as bool,
      lessonNotificationsEnabled: fields[15] as bool,
      overworkAlertsEnabled: fields[16] as bool,
      planAdjustmentNotificationsEnabled: fields[17] as bool,
      breakDurationSeconds: fields[18] as int,
      dailyReminderHour: fields[19] as int,
      dailyReminderMinute: fields[20] as int,
      firstFocusVisit: fields[21] as bool,
      dailyReminderEnabled: fields[22] as bool,
      llmProviderName: fields[23] as String,
      lastConnectionTestMs: fields[24] as int,
      lastLlmError: fields[25] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsBox obj) {
    writer
      ..writeByte(26)
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
      ..write(obj.totalQuestions)
      ..writeByte(8)
      ..write(obj.studyRemindersEnabled)
      ..writeByte(9)
      ..write(obj.requestTimeoutSeconds)
      ..writeByte(10)
      ..write(obj.sessionDurationMinutes)
      ..writeByte(11)
      ..write(obj.highContrastEnabled)
      ..writeByte(12)
      ..write(obj.largeTouchTargets)
      ..writeByte(13)
      ..write(obj.reduceMotion)
      ..writeByte(14)
      ..write(obj.revisionRemindersEnabled)
      ..writeByte(15)
      ..write(obj.lessonNotificationsEnabled)
      ..writeByte(16)
      ..write(obj.overworkAlertsEnabled)
      ..writeByte(17)
      ..write(obj.planAdjustmentNotificationsEnabled)
      ..writeByte(18)
      ..write(obj.breakDurationSeconds)
      ..writeByte(19)
      ..write(obj.dailyReminderHour)
      ..writeByte(20)
      ..write(obj.dailyReminderMinute)
      ..writeByte(21)
      ..write(obj.firstFocusVisit)
      ..writeByte(22)
      ..write(obj.dailyReminderEnabled)
      ..writeByte(23)
      ..write(obj.llmProviderName)
      ..writeByte(24)
      ..write(obj.lastConnectionTestMs)
      ..writeByte(25)
      ..write(obj.lastLlmError);
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
