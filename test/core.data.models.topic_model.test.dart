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
  });
}
