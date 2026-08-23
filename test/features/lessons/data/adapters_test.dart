import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/lessons/data/adapters.dart';

late String _hivePath;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('lesson_adapters_test_');
    _hivePath = dir.path;
    Hive.init(_hivePath);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await Directory(_hivePath).delete(recursive: true);
  });

  test('registerLessonAdapters registers lesson block and lesson adapters', () {
    registerLessonAdapters();
    expect(Hive.isAdapterRegistered(6), isTrue);
    expect(Hive.isAdapterRegistered(7), isTrue);
  });
}
