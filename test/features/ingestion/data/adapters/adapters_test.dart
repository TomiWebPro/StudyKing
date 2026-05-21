import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/ingestion/data/adapters/adapters.dart';

void main() {
  group('registerIngestionAdapters', () {
    setUp(() {
      Hive.init(Directory.systemTemp.createTempSync('ingestion_adapters_test_').path);
    });

    tearDown(() {
      Hive.close();
    });

    test('registers SourceAdapter with typeId 26', () {
      expect(Hive.isAdapterRegistered(26), isFalse);
      registerIngestionAdapters();
      expect(Hive.isAdapterRegistered(26), isTrue);
    });

    test('registers SourceAdapter when called twice does not throw', () {
      registerIngestionAdapters();
      registerIngestionAdapters();
      expect(Hive.isAdapterRegistered(26), isTrue);
    });
  });
}
