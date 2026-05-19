// ignore_for_file: experimental_member_use
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/sessions/data/adapters/session_adapter.dart';

void main() {
  group('SessionAdapter', () {
    test('has correct typeId', () {
      final adapter = SessionAdapter();
      expect(adapter.typeId, 36);
    });

    test('is a TypeAdapter<Session>', () {
      final adapter = SessionAdapter();
      expect(adapter, isA<TypeAdapter<Session>>());
    });

    test('read and write round-trips a Session without tutorMetadata', () {
      final adapter = SessionAdapter();
      final session = Session(
        id: 's1',
        studentId: 'student1',
        subjectId: 'subj1',
        topicId: 'topic1',
        type: SessionType.focus,
        startTime: DateTime.utc(2024, 1, 1, 10, 0),
        endTime: DateTime.utc(2024, 1, 1, 11, 0),
        plannedDurationMinutes: 60,
        actualDurationMs: 3600000,
        questionsAnswered: 10,
        correctAnswers: 8,
        completed: true,
      );

      final writeCache = <int, dynamic>{};
      final writer = _TestBinaryWriter(writeCache);
      adapter.write(writer, session);

      final reader = _TestBinaryReader(writeCache);
      final restored = adapter.read(reader);

      expect(restored.id, session.id);
      expect(restored.studentId, session.studentId);
      expect(restored.subjectId, session.subjectId);
      expect(restored.type, session.type);
      expect(restored.completed, session.completed);
    });

    test('read and write round-trips a Session with tutorMetadata', () {
      final adapter = SessionAdapter();
      final session = Session(
        id: 's2',
        studentId: 'student1',
        type: SessionType.tutoring,
        startTime: DateTime.utc(2024, 1, 1, 14, 0),
        tutorMetadata: TutorMetadata(
          topicTitle: 'Physics',
          totalMessages: 15,
          totalTokensUsed: 500,
        ),
      );

      final writeCache = <int, dynamic>{};
      final writer = _TestBinaryWriter(writeCache);
      adapter.write(writer, session);

      final reader = _TestBinaryReader(writeCache);
      final restored = adapter.read(reader);

      expect(restored.id, session.id);
      expect(restored.tutorMetadata, isNotNull);
      expect(restored.tutorMetadata!.topicTitle, 'Physics');
      expect(restored.tutorMetadata!.totalMessages, 15);
      expect(restored.tutorMetadata!.totalTokensUsed, 500);
    });
  });
}

class _TestBinaryWriter implements BinaryWriter {
  final Map<int, dynamic> _cache;
  int _position = 0;

  _TestBinaryWriter(this._cache);

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

class _TestBinaryReader implements BinaryReader {
  final Map<int, dynamic> _cache;
  int _position = 0;

  _TestBinaryReader(this._cache);

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
  HiveList readHiveList([int? length]) {
    length ??= _cache[_position++] as int? ?? 0;
    throw UnimplementedError('HiveList not supported in test fakes');
  }
}
