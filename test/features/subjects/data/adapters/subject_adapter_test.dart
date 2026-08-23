import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/subjects/data/adapters/subject_adapter.dart';
import 'package:studyking/core/data/models/subject_model.dart';

late String _hivePath;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('subject_adapter_test_');
    _hivePath = dir.path;
    Hive.init(_hivePath);
    Hive.registerAdapter(SubjectAdapter());
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await Directory(_hivePath).delete(recursive: true);
  });

  group('SubjectAdapter', () {
    test('typeId is 11', () => expect(SubjectAdapter().typeId, 11));

    test('hashCode and equality', () {
      expect(SubjectAdapter().hashCode, SubjectAdapter().hashCode);
      expect(SubjectAdapter() == SubjectAdapter(), isTrue);
      expect(SubjectAdapter() == Object(), isFalse);
    });

    test('write/read round-trip', () async {
      final box = await Hive.openBox<Subject>('subjects_rt');
      final created = DateTime(2026, 7, 23);
      final exam = DateTime(2026, 12, 1);
      final subject = Subject(
        id: 'sub1',
        name: 'Biology',
        description: 'Life science',
        syllabus: 'CAMBRIDGE',
        code: 'BIO101',
        teacher: 'Mr. Smith',
        topicIds: ['t1', 't2'],
        color: '#FF0000',
        createdAt: created,
        examDate: exam,
        iconName: 'science',
      );
      await box.put('sub1', subject);
      final restored = box.get('sub1')!;
      expect(restored.id, 'sub1');
      expect(restored.name, 'Biology');
      expect(restored.syllabus, 'CAMBRIDGE');
      expect(restored.topicIds, ['t1', 't2']);
      expect(restored.color, '#FF0000');
      expect(restored.createdAt, created);
      expect(restored.examDate, exam);
      await box.close();
    });

    test('write/read with defaults', () async {
      final box = await Hive.openBox<Subject>('subjects_def');
      final created = DateTime(2026, 7, 23);
      final subject = Subject(
        id: 'sub2',
        name: 'Chemistry',
        createdAt: created,
      );
      await box.put('sub2', subject);
      final restored = box.get('sub2')!;
      expect(restored.name, 'Chemistry');
      expect(restored.topicIds, isEmpty);
      expect(restored.color, '#2196F3');
      expect(restored.examDate, isNull);
      await box.close();
    });
  });
}
