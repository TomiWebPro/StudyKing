import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/dashboard/data/adapters.dart';

late String _hivePath;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('dashboard_adapters_test_');
    _hivePath = dir.path;
    Hive.init(_hivePath);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await Directory(_hivePath).delete(recursive: true);
  });

  test('registerDashboardAdapters registers the badge adapter', () {
    registerDashboardAdapters();
    expect(Hive.isAdapterRegistered(8), isTrue);
  });
}
