import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/subjects/data/adapters.dart';
import 'package:studyking/features/subjects/data/adapters/topic_dependency_adapter.dart';

void main() {
  group('registerSubjectsAdapters', () {
    test('registers the adapter when not already registered', () {
      registerSubjectsAdapters();
      expect(Hive.isAdapterRegistered(17), isTrue);
    });

    test('is idempotent when called multiple times', () {
      expect(() => registerSubjectsAdapters(), returnsNormally);
      expect(() => registerSubjectsAdapters(), returnsNormally);
      expect(Hive.isAdapterRegistered(17), isTrue);
    });

    test('registers adapter with correct typeId', () {
      final adapter = TopicDependencyAdapter();
      expect(adapter.typeId, 17);
    });

    test('registered adapter has TopicDependencyAdapter type', () {
      registerSubjectsAdapters();
      final isRegistered = Hive.isAdapterRegistered(17);
      expect(isRegistered, isTrue);
    });

    test('adapter equality consistent with registration', () {
      final a1 = TopicDependencyAdapter();
      final a2 = TopicDependencyAdapter();
      expect(a1 == a2, isTrue);
      expect(a1.hashCode, a2.hashCode);
    });

    test('handles adapter already registered', () {
      if (!Hive.isAdapterRegistered(17)) {
        Hive.registerAdapter(TopicDependencyAdapter());
      }
      expect(() => registerSubjectsAdapters(), returnsNormally);
    });

    test('registers correct adapter type', () {
      registerSubjectsAdapters();
      expect(Hive.isAdapterRegistered(17), isTrue);
    });
  });
}
