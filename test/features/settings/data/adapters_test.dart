import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/settings/data/adapters.dart';

late String _hivePath;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('settings_adapters_test_');
    _hivePath = dir.path;
    Hive.init(_hivePath);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await Directory(_hivePath).delete(recursive: true);
  });

  test('registerSettingsAdapters registers the settings box adapter', () {
    registerSettingsAdapters();
    expect(Hive.isAdapterRegistered(4), isTrue);
  });
}
