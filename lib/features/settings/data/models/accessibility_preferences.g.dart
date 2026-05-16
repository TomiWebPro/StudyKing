// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accessibility_preferences.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccessibilityPreferencesAdapter
    extends TypeAdapter<AccessibilityPreferences> {
  @override
  final int typeId = 34;

  @override
  AccessibilityPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AccessibilityPreferences(
      boldText: fields[0] as bool,
      highContrast: fields[1] as bool,
      reduceMotion: fields[2] as bool,
      largeTouchTargets: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AccessibilityPreferences obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.boldText)
      ..writeByte(1)
      ..write(obj.highContrast)
      ..writeByte(2)
      ..write(obj.reduceMotion)
      ..writeByte(3)
      ..write(obj.largeTouchTargets);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccessibilityPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
