import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/task_model.dart';

void main() {
  group('TaskModel', () {
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 5, 12);
    });

    group('constructor', () {
      test('creates with required fields', () {
        final task = TaskModel(
          id: 'task-1',
          title: 'Review Chapter 1',
          description: 'Read chapter 1',
        );
        expect(task.id, 'task-1');
        expect(task.title, 'Review Chapter 1');
        expect(task.description, 'Read chapter 1');
        expect(task.status, 'todo');
        expect(task.priority, 'medium');
        expect(task.assignee, isNull);
        expect(task.dueDate, isNull);
        expect(task.createdAt, isNull);
        expect(task.updatedAt, isNull);
      });

      test('creates with all fields', () {
        final task = TaskModel(
          id: 'task-1',
          title: 'Complete exercises',
          description: 'Do all exercises',
          status: 'inprogress',
          assignee: 'student-1',
          priority: 'high',
          dueDate: now,
          createdAt: now,
          updatedAt: now,
        );
        expect(task.status, 'inprogress');
        expect(task.assignee, 'student-1');
        expect(task.priority, 'high');
        expect(task.dueDate, now);
        expect(task.createdAt, now);
        expect(task.updatedAt, now);
      });
    });

    group('TaskModel.empty', () {
      test('creates empty task', () {
        final task = TaskModel.empty();
        expect(task.id, 'empty');
        expect(task.title, '');
        expect(task.description, '');
        expect(task.status, 'todo');
        expect(task.assignee, isNull);
        expect(task.priority, 'medium');
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final task = TaskModel(
          id: 'task-1',
          title: 'Title',
          description: 'Desc',
          status: 'done',
          priority: 'low',
        );
        final copy = task.copyWith();
        expect(copy.id, task.id);
        expect(copy.title, task.title);
        expect(copy.status, task.status);
      });

      test('updates specified fields', () {
        final task = TaskModel(
          id: 'task-1',
          title: 'Title',
          description: 'Desc',
        );
        final copy = task.copyWith(status: 'done', priority: 'high');
        expect(copy.status, 'done');
        expect(copy.priority, 'high');
        expect(copy.id, 'task-1');
      });
    });

    group('toModel', () {
      test('returns equivalent TaskModel', () {
        final task = TaskModel(
          id: 'task-1',
          title: 'Title',
          description: 'Desc',
          status: 'done',
          assignee: 'student-1',
          priority: 'high',
          dueDate: now,
          createdAt: now,
          updatedAt: now,
        );
        final model = task.toModel();
        expect(model.id, task.id);
        expect(model.title, task.title);
        expect(model.status, task.status);
        expect(model.priority, task.priority);
        expect(model.dueDate, task.dueDate);
      });
    });
  });
}
