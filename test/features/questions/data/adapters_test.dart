import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/questions/data/adapters.dart';

void main() {
  group('registerQuestionAdapters', () {
    test('registers all adapters when not already registered', () {
      registerQuestionAdapters();
      expect(Hive.isAdapterRegistered(12), isTrue);
      expect(Hive.isAdapterRegistered(13), isTrue);
      expect(Hive.isAdapterRegistered(14), isTrue);
      expect(Hive.isAdapterRegistered(15), isTrue);
    });

    test('is idempotent when called multiple times', () {
      expect(() => registerQuestionAdapters(), returnsNormally);
      expect(() => registerQuestionAdapters(), returnsNormally);
      expect(Hive.isAdapterRegistered(12), isTrue);
      expect(Hive.isAdapterRegistered(13), isTrue);
      expect(Hive.isAdapterRegistered(14), isTrue);
      expect(Hive.isAdapterRegistered(15), isTrue);
    });
  });
}
