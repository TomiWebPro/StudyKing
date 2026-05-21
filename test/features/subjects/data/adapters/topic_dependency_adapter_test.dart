import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:studyking/features/subjects/data/adapters/topic_dependency_adapter.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';

void main() {
  group('TopicDependencyAdapter', () {
    test('typeId is 17', () {
      expect(TopicDependencyAdapter().typeId, 17);
    });

    group('hashCode and equality', () {
      test('same hash code for equal instances', () {
        expect(
          TopicDependencyAdapter().hashCode,
          TopicDependencyAdapter().hashCode,
        );
      });

      test('equal instances are equal', () {
        expect(TopicDependencyAdapter() == TopicDependencyAdapter(), isTrue);
      });

      test('identical instances are equal', () {
        final adapter = TopicDependencyAdapter();
        expect(adapter == adapter, isTrue);
      });

      test('not equal to non-adapter object', () {
        expect(TopicDependencyAdapter() == Object(), isFalse);
      });

      test('not equal to null', () {
        expect(TopicDependencyAdapter(), isNotNull);
      });
    });

    group('write/read round-trip with all fields', () {
      test('full field set round-trips correctly', () {
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

      test('round-trip with null parentTopicId', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();
        final source = TopicDependency(
          topicId: 'no-parent',
          parentTopicId: null,
        );

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.parentTopicId, isNull);
        expect(restored.topicId, 'no-parent');
      });

      test('round-trip with empty collections', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();
        final source = TopicDependency(
          topicId: 'empty-colls',
          prerequisites: [],
          downstreamTopics: [],
          dependencyWeights: {},
        );

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.prerequisites, []);
        expect(restored.downstreamTopics, []);
        expect(restored.dependencyWeights, {});
      });

      test('round-trip with zero and negative values', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();
        final source = TopicDependency(
          topicId: 'edge-vals',
          syllabusWeight: 0.0,
          estimatedQuestions: 0,
          estimatedMinutes: 0,
          masteryThreshold: 0.0,
          sortOrder: -1,
        );

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.syllabusWeight, 0.0);
        expect(restored.estimatedQuestions, 0);
        expect(restored.estimatedMinutes, 0);
        expect(restored.masteryThreshold, 0.0);
        expect(restored.sortOrder, -1);
      });
    });

    group('write/read with scrambled field order', () {
      test('fields read correctly regardless of write order', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();

        final writer = BinaryWriterImpl(registry);
        writer.writeByte(11);
        writer.writeByte(10);
        writer.write(5);
        writer.writeByte(9);
        writer.write('parent1');
        writer.writeByte(8);
        writer.write(true);
        writer.writeByte(7);
        writer.write(0.95);
        writer.writeByte(6);
        writer.write(45);
        writer.writeByte(5);
        writer.write(15);
        writer.writeByte(4);
        writer.write(<String, double>{'prereq': 0.7});
        writer.writeByte(3);
        writer.write(1.5);
        writer.writeByte(2);
        writer.write(<String>['downstream']);
        writer.writeByte(1);
        writer.write(<String>['prereq1', 'prereq2']);
        writer.writeByte(0);
        writer.write('scrambled');

        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.topicId, 'scrambled');
        expect(restored.prerequisites, ['prereq1', 'prereq2']);
        expect(restored.downstreamTopics, ['downstream']);
        expect(restored.syllabusWeight, 1.5);
        expect(
          restored.dependencyWeights,
          {'prereq': 0.7},
        );
        expect(restored.estimatedQuestions, 15);
        expect(restored.estimatedMinutes, 45);
        expect(restored.masteryThreshold, 0.95);
        expect(restored.isRequired, isTrue);
        expect(restored.parentTopicId, 'parent1');
        expect(restored.sortOrder, 5);
      });


    });

    group('read with missing fields triggers default fallbacks', () {
      test('only topicId present, all other fields use defaults', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();

        final writer = BinaryWriterImpl(registry);
        writer.writeByte(1);
        writer.writeByte(0);
        writer.write('only-topic-id');

        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.topicId, 'only-topic-id');
        expect(restored.prerequisites, []);
        expect(restored.downstreamTopics, []);
        expect(restored.syllabusWeight, 1.0);
        expect(restored.dependencyWeights, {});
        expect(restored.estimatedQuestions, 10);
        expect(restored.estimatedMinutes, 30);
        expect(restored.masteryThreshold, 0.8);
        expect(restored.isRequired, isTrue);
        expect(restored.parentTopicId, isNull);
        expect(restored.sortOrder, 0);
      });

      test('topicId present with some optional fields missing', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();

        final writer = BinaryWriterImpl(registry);
        writer.writeByte(3);
        writer.writeByte(0);
        writer.write('partial-fields');
        writer.writeByte(1);
        writer.write(<String>['prereq']);
        writer.writeByte(8);
        writer.write(false);

        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.topicId, 'partial-fields');
        expect(restored.prerequisites, ['prereq']);
        expect(restored.isRequired, isFalse);
        expect(restored.downstreamTopics, []);
        expect(restored.syllabusWeight, 1.0);
        expect(restored.parentTopicId, isNull);
        expect(restored.sortOrder, 0);
      });

      test('partial fields present (field 0, 9 only)', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();

        final writer = BinaryWriterImpl(registry);
        writer.writeByte(2);
        writer.writeByte(0);
        writer.write('partial');
        writer.writeByte(9);
        writer.write('parent-x');

        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.topicId, 'partial');
        expect(restored.prerequisites, []);
        expect(restored.parentTopicId, 'parent-x');
        expect(restored.sortOrder, 0);
      });
    });

    group('write/read with minimal fields', () {
      test('defaults preserved through round-trip', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();
        final source = TopicDependency(topicId: 'topic1');

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.prerequisites, []);
        expect(restored.downstreamTopics, []);
        expect(restored.syllabusWeight, 1.0);
        expect(restored.dependencyWeights, {});
        expect(restored.estimatedQuestions, 10);
        expect(restored.estimatedMinutes, 30);
        expect(restored.masteryThreshold, 0.8);
        expect(restored.isRequired, isTrue);
        expect(restored.parentTopicId, isNull);
        expect(restored.sortOrder, 0);
      });
    });

    group('edge cases - string fields', () {
      test('round-trip with empty string topicId and parentTopicId', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();
        final source = TopicDependency(
          topicId: '',
          parentTopicId: '',
        );

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.topicId, '');
        expect(restored.parentTopicId, '');
      });

      test('round-trip with unicode and special characters in topicId and parentTopicId', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();
        final source = TopicDependency(
          topicId: '物理-力学-ñöü',
          parentTopicId: '数学-代数-çåé',
        );

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.topicId, '物理-力学-ñöü');
        expect(restored.parentTopicId, '数学-代数-çåé');
      });

      test('round-trip with emoji in topicId', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();
        final source = TopicDependency(
          topicId: '🎯-数学-📐',
        );

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.topicId, '🎯-数学-📐');
      });

      test('round-trip with very long topicId', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();
        final longId = 'topic-' * 200;
        final source = TopicDependency(topicId: longId);

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.topicId.length, 1200);
        expect(restored.topicId, longId);
      });
    });

    group('edge cases - numeric extremes', () {
      test('round-trip with max int values', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();
        final source = TopicDependency(
          topicId: 'max-vals',
          estimatedQuestions: 2147483647,
          estimatedMinutes: 2147483647,
          sortOrder: 2147483647,
        );

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.estimatedQuestions, 2147483647);
        expect(restored.estimatedMinutes, 2147483647);
        expect(restored.sortOrder, 2147483647);
      });

      test('round-trip with min int values', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();
        final source = TopicDependency(
          topicId: 'min-vals',
          estimatedQuestions: -2147483648,
          estimatedMinutes: -2147483648,
          sortOrder: -2147483648,
        );

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.estimatedQuestions, -2147483648);
        expect(restored.estimatedMinutes, -2147483648);
        expect(restored.sortOrder, -2147483648);
      });

      test('round-trip with max double values', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();
        final source = TopicDependency(
          topicId: 'max-double',
          syllabusWeight: 1.0e10,
          masteryThreshold: 1.0e10,
        );

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.syllabusWeight, 1.0e10);
        expect(restored.masteryThreshold, 1.0e10);
      });

      test('round-trip with negative double values', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();
        final source = TopicDependency(
          topicId: 'neg-double',
          syllabusWeight: -5.5,
          masteryThreshold: -0.1,
        );

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.syllabusWeight, -5.5);
        expect(restored.masteryThreshold, -0.1);
      });
    });

    group('edge cases - collections', () {
      test('round-trip with large prerequisite list', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();
        final prereqs = List.generate(100, (i) => 'prereq-$i');
        final source = TopicDependency(
          topicId: 'large-prereqs',
          prerequisites: prereqs,
        );

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.prerequisites.length, 100);
        expect(restored.prerequisites.last, 'prereq-99');
      });

      test('round-trip with large downstreamTopics list', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();
        final downstream = List.generate(50, (i) => 'down-$i');
        final source = TopicDependency(
          topicId: 'large-down',
          downstreamTopics: downstream,
        );

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.downstreamTopics.length, 50);
        expect(restored.downstreamTopics.first, 'down-0');
      });

      test('round-trip with large dependencyWeights map', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();
        final weights = <String, double>{
          for (int i = 0; i < 50; i++) 'topic-$i': i * 0.1,
        };
        final source = TopicDependency(
          topicId: 'large-weights',
          dependencyWeights: weights,
        );

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.dependencyWeights.length, 50);
        expect(restored.dependencyWeights['topic-0'], 0.0);
        expect(restored.dependencyWeights['topic-49'], 4.9);
      });

      test('round-trip with long strings in prerequisites list', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();
        final longStr = 'A' * 5000;
        final source = TopicDependency(
          topicId: 'long-str-list',
          prerequisites: [longStr],
          downstreamTopics: [longStr],
        );

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.prerequisites.first.length, 5000);
        expect(restored.downstreamTopics.first.length, 5000);
      });

      test('round-trip with unicode strings in list fields', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();
        final source = TopicDependency(
          topicId: 'unicode-lists',
          prerequisites: ['物理', '化学', '生物学'],
          downstreamTopics: ['代数', '幾何', '三角法'],
          dependencyWeights: {'物理': 0.8, '化学': 0.6},
        );

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.prerequisites, ['物理', '化学', '生物学']);
        expect(restored.downstreamTopics, ['代数', '幾何', '三角法']);
        expect(restored.dependencyWeights, {'物理': 0.8, '化学': 0.6});
      });
    });

    group('edge cases - boolean and nullable fields', () {
      test('round-trip with isRequired=false', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();
        final source = TopicDependency(
          topicId: 'not-required',
          isRequired: false,
        );

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.isRequired, isFalse);
      });

      test('round-trip with all booleans as false and null parentTopicId', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();
        final source = TopicDependency(
          topicId: 'all-false',
          isRequired: false,
          sortOrder: -1,
          parentTopicId: null,
        );

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.isRequired, isFalse);
        expect(restored.parentTopicId, isNull);
      });
    });

    group('edge cases - mixed field defaults', () {
      test('round-trip preserves field-specific defaults after multiple cycles', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();

        TopicDependency roundTrip(TopicDependency input) {
          final w = BinaryWriterImpl(registry);
          adapter.write(w, input);
          final r = BinaryReaderImpl(w.toBytes(), registry);
          return adapter.read(r);
        }

        final source = TopicDependency(topicId: 'multi-cycle');
        final cycle1 = roundTrip(source);
        final cycle2 = roundTrip(cycle1);
        final cycle3 = roundTrip(cycle2);

        expect(cycle3.topicId, 'multi-cycle');
        expect(cycle3.prerequisites, []);
        expect(cycle3.syllabusWeight, 1.0);
        expect(cycle3.sortOrder, 0);
      });
    });

    group('edge cases - field type boundary values', () {
      test('round-trip with fractional syllabusWeight', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();
        final source = TopicDependency(
          topicId: 'fractional',
          syllabusWeight: 0.3333333333333333,
          masteryThreshold: 0.6666666666666666,
        );

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.syllabusWeight, closeTo(0.3333333333333333, 1e-15));
        expect(restored.masteryThreshold, closeTo(0.6666666666666666, 1e-15));
      });

      test('round-trip with dependencyWeights containing fractional values', () {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TopicDependencyAdapter());
        final adapter = TopicDependencyAdapter();
        final source = TopicDependency(
          topicId: 'fractional-weights',
          dependencyWeights: {
            'a': 1.0 / 3.0,
            'b': 2.0 / 3.0,
            'c': 0.123456789,
          },
        );

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.dependencyWeights['a'], closeTo(1.0 / 3.0, 1e-15));
        expect(restored.dependencyWeights['b'], closeTo(2.0 / 3.0, 1e-15));
        expect(restored.dependencyWeights['c'], closeTo(0.123456789, 1e-15));
      });
    });
  });
}
