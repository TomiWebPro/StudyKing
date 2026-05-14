import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  testWidgets('just init hive', (tester) async {
    await Hive.initFlutter(Directory.systemTemp.createTempSync('test_').path);
  });
}
