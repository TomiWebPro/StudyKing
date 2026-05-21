import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/models/task_model.dart';

void main() {
  group('TaskModel', () {
    const id = 'task-1';
    const title = 'Complete Algebra HW';
    const description = 'Finish chapter 5 exercises';
    const status = 'inprogress';
    const assignee = 'student-1';
    const priority = 'high';
    final dueDate = DateTime(2026, 5, 20);
    final createdAt = DateTime(2026, 5, 16);
    final updatedAt = DateTime(2026, 5, 16);

    group('constructor', () {
      test('creates instance with required fields', () {
        final task = TaskModel(id: id, title: title, description: description);
        expect(task.id, id);
        expect(task.title, title);
        expect(task.description, description);
        expect(task.status, 'todo');
        expect(task.assignee, isNull);
        expect(task.priority, 'medium');
        expect(task.dueDate, isNull);
        expect(task.createdAt, isNull);
        expect(task.updatedAt, isNull);
      });

      test('accepts all optional fields', () {
        final task = TaskModel(
          id: id, title: title, description: description,
          status: status, assignee: assignee, priority: priority,
          dueDate: dueDate, createdAt: createdAt, updatedAt: updatedAt,
        );
        expect(task.status, status);
        expect(task.assignee, assignee);
        expect(task.priority, priority);
        expect(task.dueDate, dueDate);
        expect(task.createdAt, createdAt);
        expect(task.updatedAt, updatedAt);
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
        expect(task.dueDate, isNull);
        expect(task.createdAt, isNull);
        expect(task.updatedAt, isNull);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final task = TaskModel(id: id, title: title, description: description);
        final copy = task.copyWith();
        expect(copy.id, task.id);
        expect(copy.title, task.title);
        expect(copy.description, task.description);
      });

      test('updates specified fields', () {
        final task = TaskModel(id: id, title: title, description: description);
        final copy = task.copyWith(status: status, priority: priority);
        expect(copy.status, status);
        expect(copy.priority, priority);
        expect(copy.title, title);
      });
    });

    group('toModel', () {
      test('returns a copy with same values', () {
        final task = TaskModel(
          id: id, title: title, description: description,
          status: status, priority: priority,
        );
        final model = task.toModel();
        expect(model.id, task.id);
        expect(model.title, task.title);
        expect(model.status, task.status);
        expect(model.priority, task.priority);
        expect(model.description, task.description);
      });

      test('returns independent instance', () {
        final task = TaskModel(id: id, title: title, description: description);
        final model = task.toModel();
        expect(identical(model, task), isFalse);
      });

      test('preserves null date fields', () {
        final task = TaskModel(id: id, title: title, description: description);
        final model = task.toModel();
        expect(model.dueDate, isNull);
        expect(model.createdAt, isNull);
        expect(model.updatedAt, isNull);
      });

      test('preserves all date fields when set', () {
        final task = TaskModel(
          id: id, title: title, description: description,
          dueDate: dueDate, createdAt: createdAt, updatedAt: updatedAt,
        );
        final model = task.toModel();
        expect(model.dueDate, dueDate);
        expect(model.createdAt, createdAt);
        expect(model.updatedAt, updatedAt);
      });
    });

    group('equality', () {
      test('identical instances are equal', () {
        final a = TaskModel(id: id, title: title, description: description);
        expect(a == a, isTrue);
      });

      test('different instances are not equal', () {
        final a = TaskModel(id: id, title: title, description: description);
        final b = TaskModel(id: 'other', title: title, description: description);
        expect(a == b, isFalse);
      });

      test('hashCode is consistent', () {
        final a = TaskModel(id: id, title: title, description: description);
        expect(a.hashCode, a.hashCode);
      });
    });

    group('serialization', () {
      test('toJson/fromJson round-trip preserves all fields', () {
        final now = DateTime(2026, 5, 19);
        final original = TaskModel(
          id: 'rt-1',
          title: 'Review Kinematics',
          description: 'Complete chapter review',
          status: 'done',
          assignee: 'student-1',
          priority: 'high',
          dueDate: now,
          createdAt: now,
          updatedAt: now,
        );
        final json = original.toJson();
        final restored = TaskModel.fromJson(json);
        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.description, original.description);
        expect(restored.status, original.status);
        expect(restored.assignee, original.assignee);
        expect(restored.priority, original.priority);
        expect(restored.dueDate, original.dueDate);
        expect(restored.createdAt, original.createdAt);
        expect(restored.updatedAt, original.updatedAt);
      });

      test('toJson/fromJson round-trip with null optionals', () {
        final original = TaskModel(
          id: 'rt-2',
          title: 'Simple Task',
          description: 'No optional fields',
        );
        final json = original.toJson();
        final restored = TaskModel.fromJson(json);
        expect(restored.dueDate, isNull);
        expect(restored.createdAt, isNull);
        expect(restored.updatedAt, isNull);
        expect(restored.assignee, isNull);
        expect(restored.status, 'todo');
      });
    });

    group('edge cases', () {
      test('handles empty string fields', () {
        final task = TaskModel(id: '', title: '', description: '');
        expect(task.id, '');
        expect(task.title, '');
        expect(task.description, '');
      });

      test('handles special characters in fields', () {
        final task = TaskModel(
          id: 'task-1',
          title: r'Special: @#$% & *()',
          description: 'Unicode: ñ á é í ó ú ¡ ¿',
        );
        expect(task.title, r'Special: @#$% & *()');
        expect(task.description, 'Unicode: ñ á é í ó ú ¡ ¿');
      });

      test('handles very long string values', () {
        final longTitle = 'a' * 10000;
        final task = TaskModel(id: 'task-1', title: longTitle, description: 'desc');
        expect(task.title.length, 10000);
      });

      test('missing optional fields in fromJson use defaults', () {
        final task = TaskModel.fromJson({
          'id': 't1',
          'title': 'Test',
          'description': 'Desc',
          'status': 'done',
        });
        expect(task.assignee, isNull);
        expect(task.priority, 'medium');
        expect(task.dueDate, isNull);
        expect(task.createdAt, isNull);
        expect(task.updatedAt, isNull);
      });
    });
  });
}
