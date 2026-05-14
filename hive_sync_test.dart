import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  testWidgets('just init hive sync', (tester) async {
    Hive.init(Directory.systemTemp.createTempSync('test_').path);
    
    try {
      final box = await Hive.openBox<dynamic>('mybox');
      await box.put('key', 'value');
      await box.close();
    } catch (_) {}
  });
}
