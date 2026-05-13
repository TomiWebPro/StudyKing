import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:studyking/core/data/adapters/topic_dependency_adapter.dart';
import 'package:studyking/core/data/models/topic_dependency_model.dart';

void main() {
  group('TopicDependencyAdapter', () {
    test('typeId is 17', () {
      expect(TopicDependencyAdapter().typeId, 17);
    });

    test('hashCode and equality', () {
      expect(TopicDependencyAdapter().hashCode, TopicDependencyAdapter().hashCode);
      expect(TopicDependencyAdapter() == TopicDependencyAdapter(), isTrue);
    });

    test('write/read round-trip', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(TopicDependencyAdapter());
      final adapter = TopicDependencyAdapter();
      final source = TopicDependency(
        topicId: 'topic1',
        prerequisites: ['topic0'],
        downstreamTopics: ['topic2'],
        syllabusWeight: 2.0,
        dependencyWeights: {'topic0': 0.5, 'topic2': 0.3},
        estimatedQuestions: 20,
        estimatedMinutes: 60,
        masteryThreshold: 0.9,
        isRequired: false,
        parentTopicId: 'parent1',
        sortOrder: 3,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.topicId, 'topic1');
      expect(restored.prerequisites, ['topic0']);
      expect(restored.downstreamTopics, ['topic2']);
      expect(restored.syllabusWeight, 2.0);
      expect(restored.dependencyWeights, {'topic0': 0.5, 'topic2': 0.3});
      expect(restored.estimatedQuestions, 20);
      expect(restored.estimatedMinutes, 60);
      expect(restored.masteryThreshold, 0.9);
      expect(restored.isRequired, isFalse);
      expect(restored.parentTopicId, 'parent1');
      expect(restored.sortOrder, 3);
    });

    test('write/read with minimal fields', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(TopicDependencyAdapter());
      final adapter = TopicDependencyAdapter();
      final source = TopicDependency(topicId: 'topic1');

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.prerequisites, []);
      expect(restored.syllabusWeight, 1.0);
      expect(restored.estimatedQuestions, 10);
      expect(restored.masteryThreshold, 0.8);
      expect(restored.isRequired, isTrue);
      expect(restored.parentTopicId, isNull);
      expect(restored.sortOrder, 0);
    });
  });
}
