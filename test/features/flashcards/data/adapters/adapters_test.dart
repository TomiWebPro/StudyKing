import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/flashcards/data/adapters/adapters.dart';

late String _hivePath;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('fc_adapters_test_');
    _hivePath = dir.path;
    Hive.init(_hivePath);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await Directory(_hivePath).delete(recursive: true);
  });

  test('registerFlashcardAdapters registers all five adapters', () {
    registerFlashcardAdapters();
    expect(Hive.isAdapterRegistered(38), isTrue);
    expect(Hive.isAdapterRegistered(39), isTrue);
    expect(Hive.isAdapterRegistered(40), isTrue);
    expect(Hive.isAdapterRegistered(41), isTrue);
    expect(Hive.isAdapterRegistered(42), isTrue);
  });
}
