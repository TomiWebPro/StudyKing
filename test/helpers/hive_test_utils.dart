import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';

class TestBinaryWriter implements BinaryWriter {
  final Map<int, dynamic> _cache;
  int _position = 0;

  TestBinaryWriter(this._cache);

  @override
  void writeByte(int byte) {
    _cache[_position++] = byte;
  }

  @override
  void write<T>(T value, {bool writeTypeId = true}) {
    _cache[_position++] = value;
  }

  @override
  void writeBool(bool value) => _cache[_position++] = value;

  @override
  void writeBoolList(List<bool> list, {bool writeLength = true}) {
    if (writeLength) _cache[_position++] = list.length;
    _cache[_position++] = list;
  }

  @override
  void writeByteList(List<int> bytes, {bool writeLength = true}) {
    if (writeLength) _cache[_position++] = bytes.length;
    _cache[_position++] = bytes;
  }

  @override
  void writeDouble(double value) => _cache[_position++] = value;

  @override
  void writeDoubleList(List<double> list, {bool writeLength = true}) {
    if (writeLength) _cache[_position++] = list.length;
    _cache[_position++] = list;
  }

  @override
  // ignore: experimental_member_use
  void writeHiveList(HiveList list, {bool writeLength = true}) {
    if (writeLength) _cache[_position++] = list.length;
    _cache[_position++] = list;
  }

  @override
  void writeInt(int value) => _cache[_position++] = value;

  @override
  void writeInt32(int value) => _cache[_position++] = value;

  @override
  void writeIntList(List<int> list, {bool writeLength = true}) {
    if (writeLength) _cache[_position++] = list.length;
    _cache[_position++] = list;
  }

  @override
  void writeList(List list, {bool writeLength = true}) {
    if (writeLength) _cache[_position++] = list.length;
    _cache[_position++] = list;
  }

  @override
  void writeMap(Map map, {bool writeLength = true}) {
    if (writeLength) _cache[_position++] = map.length;
    _cache[_position++] = map;
  }

  @override
  void writeString(
    String value, {
    bool writeByteCount = true,
    Converter<String, List<int>> encoder = BinaryWriter.utf8Encoder,
  }) {
    if (writeByteCount) _cache[_position++] = value.length;
    _cache[_position++] = value;
  }

  @override
  void writeStringList(
    List<String> list, {
    bool writeLength = true,
    Converter<String, List<int>> encoder = BinaryWriter.utf8Encoder,
  }) {
    if (writeLength) _cache[_position++] = list.length;
    _cache[_position++] = list;
  }

  @override
  void writeUint32(int value) => _cache[_position++] = value;

  @override
  void writeWord(int value) => _cache[_position++] = value;
}

class TestBinaryReader implements BinaryReader {
  final Map<int, dynamic> _cache;
  int _position = 0;

  TestBinaryReader(this._cache);

  @override
  int get availableBytes => _cache.length - _position;

  @override
  int get usedBytes => _position;

  @override
  int readByte() => _cache[_position++] as int? ?? 0;

  @override
  dynamic read([int? typeId]) => _cache[_position++];

  @override
  void skip(int bytes) => _position += bytes;

  @override
  Uint8List viewBytes(int bytes) {
    final result = _cache[_position] as Uint8List? ?? Uint8List(0);
    _position += bytes;
    return result;
  }

  @override
  Uint8List peekBytes(int bytes) => _cache[_position] as Uint8List? ?? Uint8List(0);

  @override
  int readWord() => _cache[_position++] as int? ?? 0;

  @override
  int readInt32() => _cache[_position++] as int? ?? 0;

  @override
  int readUint32() => _cache[_position++] as int? ?? 0;

  @override
  int readInt() => _cache[_position++] as int? ?? 0;

  @override
  double readDouble() => _cache[_position++] as double? ?? 0.0;

  @override
  bool readBool() => _cache[_position++] as bool? ?? false;

  @override
  String readString([
    int? byteCount,
    Converter<List<int>, String> decoder = BinaryReader.utf8Decoder,
  ]) {
    byteCount ??= _cache[_position++] as int? ?? 0;
    return _cache[_position++] as String? ?? '';
  }

  @override
  Uint8List readByteList([int? length]) {
    length ??= _cache[_position++] as int? ?? 0;
    return _cache[_position++] as Uint8List? ?? Uint8List(0);
  }

  @override
  List<int> readIntList([int? length]) {
    length ??= _cache[_position++] as int? ?? 0;
    return _cache[_position++] as List<int>? ?? [];
  }

  @override
  List<double> readDoubleList([int? length]) {
    length ??= _cache[_position++] as int? ?? 0;
    return _cache[_position++] as List<double>? ?? [];
  }

  @override
  List<bool> readBoolList([int? length]) {
    length ??= _cache[_position++] as int? ?? 0;
    return _cache[_position++] as List<bool>? ?? [];
  }

  @override
  List<String> readStringList([
    int? length,
    Converter<List<int>, String> decoder = BinaryReader.utf8Decoder,
  ]) {
    length ??= _cache[_position++] as int? ?? 0;
    return _cache[_position++] as List<String>? ?? [];
  }

  @override
  List readList([int? length]) {
    length ??= _cache[_position++] as int? ?? 0;
    return _cache[_position++] as List? ?? [];
  }

  @override
  Map readMap([int? length]) {
    length ??= _cache[_position++] as int? ?? 0;
    return _cache[_position++] as Map? ?? {};
  }

  @override
  // ignore: experimental_member_use
  HiveList readHiveList([int? length]) {
    length ??= _cache[_position++] as int? ?? 0;
    throw UnimplementedError('HiveList not supported in test fakes');
  }
}

/// Reusable Hive test lifecycle helpers.
///
/// Usage in `setUpAll`:
/// ```dart
/// setUpAll(() async {
///   hivePath = await HiveTestHelper.initHive();
/// });
/// ```
///
/// Usage in `tearDownAll`:
/// ```dart
/// tearDownAll(() async {
///   await HiveTestHelper.cleanHive(hivePath);
/// });
/// ```
class HiveTestHelper {
  /// Initialises Hive with a temporary directory and returns the path.
  ///
  /// Call from `setUpAll` or `setUp`.
  static Future<String> initHive() async {
    final path = Directory.systemTemp.createTempSync('hive_test_').path;
    Hive.init(path);
    return path;
  }

  /// Closes all open Hive boxes and deletes the directory at [path].
  ///
  /// Call from `tearDownAll` or `tearDown`.
  static Future<void> cleanHive(String path) async {
    try {
      await Hive.close();
    } catch (_) {}
    try {
      await Directory(path).delete(recursive: true);
    } catch (_) {}
  }

  /// Opens or reuses the settings box and sets [key] to [value].
  ///
  /// This is useful for tests that rely on Hive settings (e.g. daily cap).
  static Future<void> setSetting(String key, dynamic value) async {
    final box = await Hive.openBox('settings');
    await box.put(key, value);
  }
}
