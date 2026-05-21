import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/sessions/data/adapters/adapters.dart';

void main() {
  group('registerSessionAdapters', () {
    setUp(() {
      Hive.init(Directory.systemTemp.createTempSync('session_adapters_test_').path);
    });

    tearDown(() {
      Hive.close();
    });

    test('registers SessionAdapter with typeId 36', () {
      expect(Hive.isAdapterRegistered(36), isFalse);
      registerSessionAdapters();
      expect(Hive.isAdapterRegistered(36), isTrue);
    });

    test('registers SessionAdapter when called twice does not throw', () {
      registerSessionAdapters();
      registerSessionAdapters();
      expect(Hive.isAdapterRegistered(36), isTrue);
    });
  });
}
