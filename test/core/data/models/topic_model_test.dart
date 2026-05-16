import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/topic_model.dart';

void main() {
  group('Topic', () {
    group('constructor', () {
      test('creates topic with required fields', () {
        final topic = Topic(
          id: 'topic-1',
          subjectId: 'subject-1',
          title: 'Algebra',
          description: 'Introduction to algebra',
          syllabusText: 'Chapter 1',
        );
        expect(topic.id, 'topic-1');
        expect(topic.subjectId, 'subject-1');
        expect(topic.title, 'Algebra');
        expect(topic.description, 'Introduction to algebra');
        expect(topic.parentId, isNull);
        expect(topic.sortOrder, 0);
        expect(topic.syllabusText, 'Chapter 1');
        expect(topic.childTopicIds, isEmpty);
      });

      test('creates topic with all fields', () {
        final topic = Topic(
          id: 'topic-2',
          subjectId: 'subject-1',
          title: 'Calculus',
          description: 'Advanced calculus',
          parentId: 'topic-1',
          sortOrder: 2,
          syllabusText: 'Chapter 2',
          childTopicIds: ['topic-3', 'topic-4'],
        );
        expect(topic.parentId, 'topic-1');
        expect(topic.sortOrder, 2);
        expect(topic.childTopicIds, ['topic-3', 'topic-4']);
      });
    });

    group('toJson', () {
      test('serializes topic with all fields', () {
        final topic = Topic(
          id: 'topic-1',
          subjectId: 'subject-1',
          title: 'Algebra',
          description: 'Introduction',
          parentId: 'parent-1',
          sortOrder: 1,
          syllabusText: 'Syllabus',
          childTopicIds: ['child-1'],
        );
        final json = topic.toJson();
        expect(json['id'], 'topic-1');
        expect(json['subjectId'], 'subject-1');
        expect(json['title'], 'Algebra');
        expect(json['description'], 'Introduction');
        expect(json['parentId'], 'parent-1');
        expect(json['sortOrder'], 1);
        expect(json['syllabusText'], 'Syllabus');
        expect(json['childTopicIds'], ['child-1']);
      });

      test('serializes topic without optional fields', () {
        final topic = Topic(
          id: 'topic-1',
          subjectId: 'subject-1',
          title: 'Algebra',
          description: '',
          syllabusText: '',
        );
        final json = topic.toJson();
        expect(json['parentId'], isNull);
        expect(json['sortOrder'], 0);
        expect(json['childTopicIds'], []);
      });
    });

    group('fromJson', () {
      test('deserializes topic with all fields', () {
        final json = {
          'id': 'topic-1',
          'subjectId': 'subject-1',
          'title': 'Algebra',
          'description': 'Intro',
          'parentId': 'parent-1',
          'sortOrder': 2,
          'syllabusText': 'Syllabus',
          'childTopicIds': ['child-1', 'child-2'],
        };
        final topic = Topic.fromJson(json);
        expect(topic.id, 'topic-1');
        expect(topic.subjectId, 'subject-1');
        expect(topic.title, 'Algebra');
        expect(topic.description, 'Intro');
        expect(topic.parentId, 'parent-1');
        expect(topic.sortOrder, 2);
        expect(topic.syllabusText, 'Syllabus');
        expect(topic.childTopicIds, ['child-1', 'child-2']);
      });

      test('deserializes with missing optional fields', () {
        final json = {
          'id': 'topic-1',
          'subjectId': 'subject-1',
          'title': 'Algebra',
          'description': 'Intro',
          'syllabusText': 'Syllabus',
        };
        final topic = Topic.fromJson(json);
        expect(topic.parentId, isNull);
        expect(topic.sortOrder, 0);
        expect(topic.childTopicIds, isEmpty);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final topic = Topic(
          id: 'topic-1',
          subjectId: 'subject-1',
          title: 'Algebra',
          description: 'Intro',
          syllabusText: 'Syllabus',
        );
        final copy = topic.copyWith();
        expect(copy.id, topic.id);
        expect(copy.title, topic.title);
        expect(copy.description, topic.description);
      });

      test('updates specified fields', () {
        final topic = Topic(
          id: 'topic-1',
          subjectId: 'subject-1',
          title: 'Algebra',
          description: 'Intro',
          syllabusText: 'Syllabus',
        );
        final copy = topic.copyWith(title: 'Geometry', sortOrder: 5);
        expect(copy.title, 'Geometry');
        expect(copy.sortOrder, 5);
        expect(copy.id, topic.id);
        expect(copy.subjectId, topic.subjectId);
      });
    });

    group('serialization roundtrip', () {
      test('toJson then fromJson preserves data', () {
        final original = Topic(
          id: 'topic-1',
          subjectId: 'subject-1',
          title: 'Algebra',
          description: 'Intro',
          parentId: 'parent-1',
          sortOrder: 3,
          syllabusText: 'Syllabus',
          childTopicIds: ['child-1'],
        );
        final json = original.toJson();
        final restored = Topic.fromJson(json);
        expect(restored.id, original.id);
        expect(restored.subjectId, original.subjectId);
        expect(restored.title, original.title);
        expect(restored.description, original.description);
        expect(restored.parentId, original.parentId);
        expect(restored.sortOrder, original.sortOrder);
        expect(restored.syllabusText, original.syllabusText);
        expect(restored.childTopicIds, original.childTopicIds);
      });
    });

    group('fromJson edge cases', () {
      test('uses default sortOrder 0 when null', () {
        final json = {
          'id': 'topic-1',
          'subjectId': 's1',
          'title': 'Title',
          'description': 'Desc',
          'sortOrder': null,
          'syllabusText': 'Syllabus',
        };
        final topic = Topic.fromJson(json);
        expect(topic.sortOrder, 0);
      });

      test('uses empty childTopicIds when null', () {
        final json = {
          'id': 'topic-1',
          'subjectId': 's1',
          'title': 'Title',
          'description': 'Desc',
          'syllabusText': 'Syllabus',
          'childTopicIds': null,
        };
        final topic = Topic.fromJson(json);
        expect(topic.childTopicIds, isEmpty);
      });

      test('uses empty childTopicIds when missing', () {
        final json = {
          'id': 'topic-1',
          'subjectId': 's1',
          'title': 'Title',
          'description': 'Desc',
          'syllabusText': 'Syllabus',
        };
        final topic = Topic.fromJson(json);
        expect(topic.childTopicIds, isEmpty);
      });

      test('handles null parentId', () {
        final json = {
          'id': 'topic-1',
          'subjectId': 's1',
          'title': 'Title',
          'description': 'Desc',
          'parentId': null,
          'syllabusText': 'Syllabus',
        };
        final topic = Topic.fromJson(json);
        expect(topic.parentId, isNull);
      });
    });

    group('copyWith edge cases', () {
      test('cannot reset parentId to null with null arg', () {
        final topic = Topic(
          id: 'topic-1',
          subjectId: 's1',
          title: 'Title',
          description: 'Desc',
          parentId: 'parent-1',
          syllabusText: 'Syllabus',
        );
        final copy = topic.copyWith(parentId: null);
        expect(copy.parentId, 'parent-1');
      });

      test('updates subjectId', () {
        final topic = Topic(
          id: 'topic-1',
          subjectId: 's1',
          title: 'Title',
          description: 'Desc',
          syllabusText: 'Syllabus',
        );
        final copy = topic.copyWith(subjectId: 's2');
        expect(copy.subjectId, 's2');
        expect(copy.id, 'topic-1');
      });

      test('updates description', () {
        final topic = Topic(
          id: 'topic-1',
          subjectId: 's1',
          title: 'Title',
          description: 'Desc',
          syllabusText: 'Syllabus',
        );
        final copy = topic.copyWith(description: 'New description');
        expect(copy.description, 'New description');
      });

      test('updates syllabusText', () {
        final topic = Topic(
          id: 'topic-1',
          subjectId: 's1',
          title: 'Title',
          description: 'Desc',
          syllabusText: 'Syllabus',
        );
        final copy = topic.copyWith(syllabusText: 'New syllabus');
        expect(copy.syllabusText, 'New syllabus');
      });

      test('updates childTopicIds', () {
        final topic = Topic(
          id: 'topic-1',
          subjectId: 's1',
          title: 'Title',
          description: 'Desc',
          syllabusText: 'Syllabus',
          childTopicIds: ['c1'],
        );
        final copy = topic.copyWith(childTopicIds: ['c1', 'c2', 'c3']);
        expect(copy.childTopicIds, ['c1', 'c2', 'c3']);
      });

      test('preserves childTopicIds when null is passed', () {
        final topic = Topic(
          id: 'topic-1',
          subjectId: 's1',
          title: 'Title',
          description: 'Desc',
          syllabusText: 'Syllabus',
          childTopicIds: ['c1', 'c2'],
        );
        final copy = topic.copyWith(childTopicIds: null);
        expect(copy.childTopicIds, ['c1', 'c2']);
      });
    });

    group('equality', () {
      test('uses identity-based equality', () {
        final a = Topic(
          id: 'topic-1',
          subjectId: 'subject-1',
          title: 'Algebra',
          description: 'Intro',
          syllabusText: 'Syllabus',
        );
        final b = Topic(
          id: 'topic-2',
          subjectId: 'subject-2',
          title: 'Geometry',
          description: 'Shapes',
          syllabusText: 'Chapter 2',
        );
        expect(a == b, isFalse);
        expect(a == a, isTrue);
      });

      test('hashCode is consistent', () {
        final obj = Topic(
          id: 'topic-1',
          subjectId: 'subject-1',
          title: 'Algebra',
          description: 'Intro',
          syllabusText: 'Syllabus',
        );
        final hash = obj.hashCode;
        expect(obj.hashCode, hash);
      });
    });

    group('Hive type annotation', () {
      test('class name matches HiveType', () {
        const topic = Topic;
        expect(topic.toString(), 'Topic');
      });
    });

    group('toString', () {
      test('includes class name', () {
        final obj = Topic(id: 't1', subjectId: 's1', title: 'T', description: 'D', syllabusText: 'S');
        expect(obj.toString(), contains('Topic'));
      });
    });
  });
}
