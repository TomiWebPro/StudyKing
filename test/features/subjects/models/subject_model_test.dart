import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/subjects/data/models/subject_model.dart';

void main() {
  group('Subject', () {
    group('constructor', () {
      test('creates with required fields', () {
        final subject = Subject(
          id: 'subject-1',
          name: 'Physics',
        );

        expect(subject.id, 'subject-1');
        expect(subject.name, 'Physics');
        expect(subject.description, isNull);
        expect(subject.syllabus, isNull);
        expect(subject.code, isNull);
        expect(subject.teacher, isNull);
        expect(subject.topicIds, isEmpty);
        expect(subject.color, '#2196F3');
        expect(subject.createdAt, isNotNull);
        expect(subject.examDate, isNull);
      });

      test('creates with all fields', () {
        final createdAt = DateTime(2024, 1, 15);
        final examDate = DateTime(2024, 6, 15);
        final subject = Subject(
          id: 'subject-2',
          name: 'Chemistry',
          description: 'IB Chemistry SL',
          syllabus: ' syllabus content',
          code: 'IB-CHEM',
          teacher: 'Dr. Smith',
          topicIds: ['topic-1', 'topic-2'],
          color: '#FF5722',
          createdAt: createdAt,
          examDate: examDate,
        );

        expect(subject.id, 'subject-2');
        expect(subject.name, 'Chemistry');
        expect(subject.description, 'IB Chemistry SL');
        expect(subject.syllabus, ' syllabus content');
        expect(subject.code, 'IB-CHEM');
        expect(subject.teacher, 'Dr. Smith');
        expect(subject.topicIds, ['topic-1', 'topic-2']);
        expect(subject.color, '#FF5722');
        expect(subject.createdAt, createdAt);
        expect(subject.examDate, examDate);
      });

      test('applies default color when not provided', () {
        final subject = Subject(
          id: 'subject-3',
          name: 'Biology',
        );

        expect(subject.color, '#2196F3');
      });

      test('applies default topicIds when null', () {
        final subject = Subject(
          id: 'subject-4',
          name: 'Math',
          topicIds: null,
        );

        expect(subject.topicIds, isEmpty);
      });

      test('applies default createdAt when null', () {
        final subject = Subject(
          id: 'subject-5',
          name: 'History',
          createdAt: null,
        );

        expect(subject.createdAt, isNotNull);
        expect(subject.createdAt.isBefore(DateTime.now().add(const Duration(seconds: 1))), isTrue);
      });
    });

    group('toJson', () {
      test('serializes required fields correctly', () {
        final subject = Subject(
          id: 'subject-1',
          name: 'Physics',
        );

        final json = subject.toJson();

        expect(json['id'], 'subject-1');
        expect(json['name'], 'Physics');
        expect(json['description'], isNull);
        expect(json['syllabus'], isNull);
        expect(json['code'], isNull);
        expect(json['teacher'], isNull);
        expect(json['topicIds'], <String>[]);
        expect(json['color'], '#2196F3');
        expect(json['createdAt'], isNotNull);
        expect(json['examDate'], isNull);
      });

      test('serializes all fields correctly', () {
        final createdAt = DateTime(2024, 1, 15, 10, 30);
        final examDate = DateTime(2024, 6, 15, 14, 0);
        final subject = Subject(
          id: 'subject-2',
          name: 'Chemistry',
          description: 'IB Chemistry SL',
          syllabus: 'syllabus content',
          code: 'IB-CHEM',
          teacher: 'Dr. Smith',
          topicIds: ['topic-1', 'topic-2'],
          color: '#FF5722',
          createdAt: createdAt,
          examDate: examDate,
        );

        final json = subject.toJson();

        expect(json['id'], 'subject-2');
        expect(json['name'], 'Chemistry');
        expect(json['description'], 'IB Chemistry SL');
        expect(json['syllabus'], 'syllabus content');
        expect(json['code'], 'IB-CHEM');
        expect(json['teacher'], 'Dr. Smith');
        expect(json['topicIds'], ['topic-1', 'topic-2']);
        expect(json['color'], '#FF5722');
        expect(json['createdAt'], createdAt.toIso8601String());
        expect(json['examDate'], examDate.toIso8601String());
      });

      test('topicIds serializes to list', () {
        final subject = Subject(
          id: 'subject-3',
          name: 'Biology',
          topicIds: ['t1', 't2', 't3'],
        );

        final json = subject.toJson();

        expect(json['topicIds'], ['t1', 't2', 't3']);
      });
    });

    group('fromJson', () {
      test('parses required fields correctly', () {
        final json = {
          'id': 'subject-1',
          'name': 'Physics',
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final subject = Subject.fromJson(json);

        expect(subject.id, 'subject-1');
        expect(subject.name, 'Physics');
        expect(subject.description, isNull);
        expect(subject.syllabus, isNull);
        expect(subject.code, isNull);
        expect(subject.teacher, isNull);
        expect(subject.topicIds, isEmpty);
        expect(subject.color, '#2196F3');
        expect(subject.createdAt, DateTime(2024, 1, 15, 10, 30));
        expect(subject.examDate, isNull);
      });

      test('parses all fields correctly', () {
        final json = {
          'id': 'subject-2',
          'name': 'Chemistry',
          'description': 'IB Chemistry SL',
          'syllabus': 'syllabus content',
          'code': 'IB-CHEM',
          'teacher': 'Dr. Smith',
          'topicIds': ['topic-1', 'topic-2'],
          'color': '#FF5722',
          'createdAt': '2024-01-15T10:30:00.000',
          'examDate': '2024-06-15T14:00:00.000',
        };

        final subject = Subject.fromJson(json);

        expect(subject.id, 'subject-2');
        expect(subject.name, 'Chemistry');
        expect(subject.description, 'IB Chemistry SL');
        expect(subject.syllabus, 'syllabus content');
        expect(subject.code, 'IB-CHEM');
        expect(subject.teacher, 'Dr. Smith');
        expect(subject.topicIds, ['topic-1', 'topic-2']);
        expect(subject.color, '#FF5722');
        expect(subject.createdAt, DateTime(2024, 1, 15, 10, 30));
        expect(subject.examDate, DateTime(2024, 6, 15, 14, 0));
      });

      test('handles null description', () {
        final json = {
          'id': 'subject-1',
          'name': 'Physics',
          'description': null,
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final subject = Subject.fromJson(json);

        expect(subject.description, isNull);
      });

      test('handles null topicIds', () {
        final json = {
          'id': 'subject-1',
          'name': 'Physics',
          'topicIds': null,
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final subject = Subject.fromJson(json);

        expect(subject.topicIds, isEmpty);
      });

      test('handles missing topicIds key', () {
        final json = {
          'id': 'subject-1',
          'name': 'Physics',
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final subject = Subject.fromJson(json);

        expect(subject.topicIds, isEmpty);
      });

      test('handles null color, uses default', () {
        final json = {
          'id': 'subject-1',
          'name': 'Physics',
          'color': null,
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final subject = Subject.fromJson(json);

        expect(subject.color, '#2196F3');
      });

      test('handles null examDate', () {
        final json = {
          'id': 'subject-1',
          'name': 'Physics',
          'examDate': null,
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final subject = Subject.fromJson(json);

        expect(subject.examDate, isNull);
      });

      test('handles null examDate string', () {
        final json = {
          'id': 'subject-1',
          'name': 'Physics',
          'examDate': null,
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final subject = Subject.fromJson(json);

        expect(subject.examDate, isNull);
      });

      test('parses list topicIds from JSON', () {
        final json = {
          'id': 'subject-1',
          'name': 'Physics',
          'topicIds': ['t1', 't2', 't3'],
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final subject = Subject.fromJson(json);

        expect(subject.topicIds, ['t1', 't2', 't3']);
      });
    });

    group('copyWith', () {
      test('creates copy with updated id', () {
        final original = Subject(
          id: 'subject-1',
          name: 'Physics',
        );
        final copy = original.copyWith(id: 'subject-2');

        expect(copy.id, 'subject-2');
        expect(copy.name, 'Physics');
      });

      test('creates copy with updated name', () {
        final original = Subject(
          id: 'subject-1',
          name: 'Physics',
        );
        final copy = original.copyWith(name: 'Chemistry');

        expect(copy.id, 'subject-1');
        expect(copy.name, 'Chemistry');
      });

      test('creates copy with updated description', () {
        final original = Subject(
          id: 'subject-1',
          name: 'Physics',
        );
        final copy = original.copyWith(description: 'New description');

        expect(copy.description, 'New description');
        expect(original.description, isNull);
      });

      test('creates copy with updated syllabus', () {
        final original = Subject(
          id: 'subject-1',
          name: 'Physics',
        );
        final copy = original.copyWith(syllabus: 'New syllabus');

        expect(copy.syllabus, 'New syllabus');
        expect(original.syllabus, isNull);
      });

      test('creates copy with updated code', () {
        final original = Subject(
          id: 'subject-1',
          name: 'Physics',
        );
        final copy = original.copyWith(code: 'IB-PHYS');

        expect(copy.code, 'IB-PHYS');
        expect(original.code, isNull);
      });

      test('creates copy with updated teacher', () {
        final original = Subject(
          id: 'subject-1',
          name: 'Physics',
        );
        final copy = original.copyWith(teacher: 'Dr. Smith');

        expect(copy.teacher, 'Dr. Smith');
        expect(original.teacher, isNull);
      });

      test('creates copy with updated topicIds', () {
        final original = Subject(
          id: 'subject-1',
          name: 'Physics',
          topicIds: ['t1'],
        );
        final copy = original.copyWith(topicIds: ['t1', 't2', 't3']);

        expect(copy.topicIds, ['t1', 't2', 't3']);
        expect(original.topicIds, ['t1']);
      });

      test('creates copy with updated color', () {
        final original = Subject(
          id: 'subject-1',
          name: 'Physics',
        );
        final copy = original.copyWith(color: '#FF0000');

        expect(copy.color, '#FF0000');
        expect(original.color, '#2196F3');
      });

      test('creates copy with updated createdAt', () {
        final original = Subject(
          id: 'subject-1',
          name: 'Physics',
        );
        final newDate = DateTime(2025, 1, 1);
        final copy = original.copyWith(createdAt: newDate);

        expect(copy.createdAt, newDate);
        expect(original.createdAt, isNot(newDate));
      });

      test('creates copy with updated examDate', () {
        final original = Subject(
          id: 'subject-1',
          name: 'Physics',
        );
        final examDate = DateTime(2024, 6, 15);
        final copy = original.copyWith(examDate: examDate);

        expect(copy.examDate, examDate);
        expect(original.examDate, isNull);
      });

      test('copyWith uses null-aware operator for examDate - cannot set to null', () {
        final original = Subject(
          id: 'subject-1',
          name: 'Physics',
          examDate: DateTime(2024, 6, 15),
        );
        final copy = original.copyWith(examDate: null);

        expect(copy.examDate, DateTime(2024, 6, 15));
        expect(original.examDate, DateTime(2024, 6, 15));
      });

      test('copyWith with examDate null preserves original examDate', () {
        final original = Subject(
          id: 'subject-1',
          name: 'Physics',
          examDate: DateTime(2024, 6, 15),
        );
        final copy = original.copyWith(examDate: null);

        expect(copy.examDate, equals(original.examDate));
      });

      test('copyWith can set examDate when original was null', () {
        final original = Subject(
          id: 'subject-1',
          name: 'Physics',
        );
        final examDate = DateTime(2025, 6, 15);
        final copy = original.copyWith(examDate: examDate);

        expect(copy.examDate, examDate);
        expect(original.examDate, isNull);
      });

      test('preserves original values when no params provided', () {
        final original = Subject(
          id: 'subject-1',
          name: 'Physics',
          description: 'IB Physics',
          syllabus: 'syllabus',
          code: 'IB-PHYS',
          teacher: 'Dr. Smith',
          topicIds: ['t1', 't2'],
          color: '#FF5722',
          createdAt: DateTime(2024, 1, 15),
          examDate: DateTime(2024, 6, 15),
        );
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.name, original.name);
        expect(copy.description, original.description);
        expect(copy.syllabus, original.syllabus);
        expect(copy.code, original.code);
        expect(copy.teacher, original.teacher);
        expect(copy.topicIds, original.topicIds);
        expect(copy.color, original.color);
        expect(copy.createdAt, original.createdAt);
        expect(copy.examDate, original.examDate);
      });

      test('returns new instance', () {
        final original = Subject(
          id: 'subject-1',
          name: 'Physics',
        );
        final copy = original.copyWith();

        expect(identical(original, copy), isFalse);
      });
    });

    group('JSON round-trip', () {
      test('full round-trip preserves all fields', () {
        final original = Subject(
          id: 'subject-1',
          name: 'Physics',
          description: 'IB Physics SL',
          syllabus: 'full syllabus',
          code: 'IB-PHYS',
          teacher: 'Dr. Smith',
          topicIds: ['topic-1', 'topic-2', 'topic-3'],
          color: '#FF5722',
          createdAt: DateTime(2024, 1, 15, 10, 30),
          examDate: DateTime(2024, 6, 15, 14, 0),
        );

        final json = original.toJson();
        final restored = Subject.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.description, original.description);
        expect(restored.syllabus, original.syllabus);
        expect(restored.code, original.code);
        expect(restored.teacher, original.teacher);
        expect(restored.topicIds, original.topicIds);
        expect(restored.color, original.color);
        expect(restored.createdAt, original.createdAt);
        expect(restored.examDate, original.examDate);
      });

      test('round-trip with minimal fields', () {
        final original = Subject(
          id: 'subject-1',
          name: 'Physics',
        );

        final json = original.toJson();
        final restored = Subject.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.description, original.description);
        expect(restored.topicIds, original.topicIds);
        expect(restored.color, original.color);
        expect(restored.examDate, original.examDate);
      });
    });

    group('toString', () {
      test('returns correct string representation', () {
        final subject = Subject(
          id: 'subject-1',
          name: 'Physics',
        );

        expect(subject.toString(), 'Subject(id: subject-1, name: Physics)');
      });

      test('toString with all fields includes only id and name', () {
        final subject = Subject(
          id: 'subject-2',
          name: 'Chemistry',
          description: 'IB Chemistry SL',
          code: 'IB-CHEM',
          teacher: 'Dr. Smith',
          topicIds: ['topic-1'],
          color: '#FF5722',
          examDate: DateTime(2024, 6, 15),
        );

        expect(subject.toString(), 'Subject(id: subject-2, name: Chemistry)');
      });
    });
  });
}