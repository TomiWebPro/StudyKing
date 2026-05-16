import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/repository.dart';

class _TestItem {
  final String id;
  final String name;

  _TestItem(this.id, this.name);
}

class _TestItemAdapter extends TypeAdapter<_TestItem> {
  @override
  final int typeId = 100;

  @override
  _TestItem read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    return _TestItem(id, name);
  }

  @override
  void write(BinaryWriter writer, _TestItem obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
  }
}

class _TestRepository extends Repository<_TestItem> {
  List<_TestItem> filterByName(String name) {
    return filterBy((item) => item.name, name);
  }
}

void main() {
  late Box<_TestItem> box;

  setUpAll(() {
    Hive.registerAdapter(_TestItemAdapter());
  });

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('hive_repo_test_');
    Hive.init(dir.path);
    box = await Hive.openBox<_TestItem>('test_repo_box');
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk('test_repo_box');
  });

  group('Repository', () {
    late _TestRepository repo;

    setUp(() {
      repo = _TestRepository();
      repo.attachBox(box);
    });

    test('save stores and get retrieves an item', () async {
      final item = _TestItem('1', 'apple');
      await repo.save('key1', item);
      final retrieved = await repo.get('key1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('1'));
      expect(retrieved.name, equals('apple'));
    });

    test('get returns null for missing key', () async {
      final result = await repo.get('nonexistent');
      expect(result, isNull);
    });

    test('getAll returns all saved items', () async {
      await repo.save('key1', _TestItem('1', 'apple'));
      await repo.save('key2', _TestItem('2', 'banana'));
      await repo.save('key3', _TestItem('3', 'cherry'));

      final all = await repo.getAll();
      expect(all, hasLength(3));
    });

    test('getAll returns empty list when nothing saved', () async {
      final all = await repo.getAll();
      expect(all, isEmpty);
    });

    test('delete removes an item', () async {
      await repo.save('key1', _TestItem('1', 'apple'));
      expect(await repo.get('key1'), isNotNull);

      await repo.delete('key1');
      expect(await repo.get('key1'), isNull);
    });

    test('delete is idempotent', () async {
      await repo.delete('nonexistent');
    });

    test('save overwrites existing item', () async {
      await repo.save('key1', _TestItem('1', 'apple'));
      await repo.save('key1', _TestItem('1', 'updated'));

      final retrieved = await repo.get('key1');
      expect(retrieved!.name, equals('updated'));
    });

    test('filterBy returns matching items', () async {
      await repo.save('key1', _TestItem('1', 'apple'));
      await repo.save('key2', _TestItem('2', 'banana'));
      await repo.save('key3', _TestItem('3', 'apple'));

      final filtered = repo.filterByName('apple');
      expect(filtered, hasLength(2));
      expect(filtered.every((item) => item.name == 'apple'), isTrue);
    });

    test('filterBy returns empty list for no match', () async {
      await repo.save('key1', _TestItem('1', 'apple'));

      final filtered = repo.filterByName('nonexistent');
      expect(filtered, isEmpty);
    });

    test('filterBy returns empty list when box is empty', () async {
      final filtered = repo.filterByName('anything');
      expect(filtered, isEmpty);
    });

    test('box getter returns attached box', () {
      expect(repo.box, same(box));
    });
  });

  group('Repository.openBox', () {
    late _TestRepository repo;
    const boxName = 'open_box_test';

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('hive_openbox_test_');
      Hive.init(dir.path);
      repo = _TestRepository();
      await repo.openBox(boxName);
    });

    tearDown(() async {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.deleteBoxFromDisk(boxName);
      }
    });

    test('openBox creates a box and allows operations', () async {
      await repo.save('k1', _TestItem('1', 'abc'));
      final result = await repo.get('k1');
      expect(result, isNotNull);
      expect(result!.name, 'abc');
    });

    test('openBox box contains saved items', () async {
      await repo.save('k1', _TestItem('1', 'x'));
      await repo.save('k2', _TestItem('2', 'y'));
      final all = await repo.getAll();
      expect(all, hasLength(2));
    });

    test('openBox box getter works', () {
      expect(repo.box, isNotNull);
      expect(repo.box.name, boxName);
    });
  });
}
