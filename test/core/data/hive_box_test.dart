import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/repository.dart';

class _BoxItem {
  final String id;
  final String name;

  _BoxItem(this.id, this.name);

  @override
  bool operator ==(Object other) =>
      other is _BoxItem && other.id == id && other.name == name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

class _BoxItemAdapter extends TypeAdapter<_BoxItem> {
  @override
  final int typeId = 101;

  @override
  _BoxItem read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    return _BoxItem(id, name);
  }

  @override
  void write(BinaryWriter writer, _BoxItem obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
  }
}

class _BoxRepository extends Repository<_BoxItem> {
  _BoxRepository();
}

void main() {
  setUpAll(() {
    Hive.registerAdapter(_BoxItemAdapter());
  });

  group('Repository open/close guards', () {
    test('isOpen is false before any box is attached or opened', () {
      final repo = _BoxRepository();
      expect(repo.isOpen, isFalse);
    });

    test('isOpen becomes true after attachBox', () async {
      final dir = await Directory.systemTemp.createTemp('hive_box_guard_');
      Hive.init(dir.path);
      final box = await Hive.openBox<_BoxItem>('guard_box');
      final repo = _BoxRepository()..attachBox(box);
      expect(repo.isOpen, isTrue);
      await box.close();
      await Hive.deleteBoxFromDisk('guard_box');
    });

    test('isOpen becomes true after openBox', () async {
      final dir = await Directory.systemTemp.createTemp('hive_box_open_');
      Hive.init(dir.path);
      final repo = _BoxRepository();
      await repo.openBox('opened_box');
      expect(repo.isOpen, isTrue);
      if (Hive.isBoxOpen('opened_box')) {
        await Hive.deleteBoxFromDisk('opened_box');
      }
    });
  });

  group('Repository not-open error path', () {
    late _BoxRepository repo;

    setUp(() {
      // A repository with no boxName and no attached box represents the
      // "not initialized" state that every public accessor must guard.
      repo = _BoxRepository();
    });

    test('get returns Result.failure when box is not open', () async {
      final result = await repo.get('missing');
      expect(result.isFailure, isTrue);
      expect(result.error, isNotNull);
      expect(result.data, isNull);
    });

    test('put (safePut) returns Result.failure when box is not open', () async {
      final result = await repo.put('k', _BoxItem('1', 'a'));
      expect(result.isFailure, isTrue);
      expect(result.error, contains('not initialized'));
    });

    test('save (safePut alias) returns Result.failure when box is not open',
        () async {
      final result = await repo.save('k', _BoxItem('1', 'a'));
      expect(result.isFailure, isTrue);
    });

    test('getAll returns Result.failure when box is not open', () async {
      final result = await repo.getAll();
      expect(result.isFailure, isTrue);
      expect(result.data, isNull);
    });

    test('delete returns Result.failure when box is not open', () async {
      final result = await repo.delete('k');
      expect(result.isFailure, isTrue);
    });
  });

  group('Repository typed accessors (safeGet/safePut)', () {
    late _BoxRepository repo;
    late Box<_BoxItem> box;

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('hive_box_accessor_');
      Hive.init(dir.path);
      box = await Hive.openBox<_BoxItem>('accessor_box');
      repo = _BoxRepository()..attachBox(box);
    });

    tearDown(() async {
      await box.close();
      await Hive.deleteBoxFromDisk('accessor_box');
    });

    test('put then get round-trips a typed value', () async {
      final putResult = await repo.put('a', _BoxItem('1', 'alpha'));
      expect(putResult.isSuccess, isTrue);

      final getResult = await repo.get('a');
      expect(getResult.isSuccess, isTrue);
      expect(getResult.data, _BoxItem('1', 'alpha'));
    });

    test('save then get round-trips a typed value', () async {
      final saveResult = await repo.save('b', _BoxItem('2', 'beta'));
      expect(saveResult.isSuccess, isTrue);

      final getResult = await repo.get('b');
      expect(getResult.data, _BoxItem('2', 'beta'));
    });

    test('get returns Result.success(null) for an unknown key', () async {
      final getResult = await repo.get('unknown');
      expect(getResult.isSuccess, isTrue);
      expect(getResult.data, isNull);
    });

    test('getAll returns every stored typed value', () async {
      await repo.put('a', _BoxItem('1', 'alpha'));
      await repo.put('b', _BoxItem('2', 'beta'));
      final all = await repo.getAll();
      expect(all.isSuccess, isTrue);
      expect(all.data, hasLength(2));
    });

    test('delete removes the typed value', () async {
      await repo.put('a', _BoxItem('1', 'alpha'));
      final deleteResult = await repo.delete('a');
      expect(deleteResult.isSuccess, isTrue);
      final getResult = await repo.get('a');
      expect(getResult.data, isNull);
    });

    test('put overwrites an existing key', () async {
      await repo.put('a', _BoxItem('1', 'alpha'));
      await repo.put('a', _BoxItem('1', 'alpha-v2'));
      final getResult = await repo.get('a');
      expect(getResult.data, _BoxItem('1', 'alpha-v2'));
    });
  });
}
