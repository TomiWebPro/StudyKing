import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late String hivePath;
  late Box box;

  setUp(() async {
    hivePath = (await Directory.systemTemp.createTemp('hive_test_')).path;
    Hive.init(hivePath);
    box = await Hive.openBox('test_box');
  });

  tearDown(() async {
    await Hive.close();
    if (hivePath.isNotEmpty) {
      await Directory(hivePath).delete(recursive: true);
    }
  });

  testWidgets('minimal hive widget test', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Text('Hello'))));
    await tester.pump();
    expect(box.get('key'), isNull);
    box.put('key', 'value');
    expect(box.get('key'), 'value');
  });
}
