import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/utils/question_export_utils.dart';

void main() {
  late Directory tmpDir;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('q_export_test_');
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  final sampleQuestion = Question(
    id: 'q_test_1',
    text: 'What is 2+2?',
    type: QuestionType.singleChoice,
    difficulty: 1,
    subjectId: 'subj_math',
    topicId: 'topic_arithmetic',
    variantIds: ['v1', 'v2'],
    sourceIds: ['src_textbook'],
    options: ['3', '4', '5'],
    allowedAnswerTypes: 'text',
    markscheme: Markscheme(correctAnswer: '4'),
    tags: ['math', 'basic'],
    model: null,
    difficultyText: 'easy',
    nextReview: DateTime(2026, 6, 1),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 5, 20),
  );

  final aiQuestion = Question(
    id: 'q_ai_2',
    text: 'Explain photosynthesis',
    type: QuestionType.typedAnswer,
    difficulty: 2,
    subjectId: 'subj_bio',
    topicId: 'topic_plants',
    sourceIds: [],
    options: [],
    markscheme: null,
    model: 'gpt-4',
    tags: ['biology'],
    difficultyText: null,
    createdAt: DateTime(2026, 3, 1),
    updatedAt: DateTime(2026, 3, 1),
  );

  group('QuestionExportUtils', () {
    test('exportAsCsv produces valid CSV with header and rows', () async {
      final result = await QuestionExportUtils.exportAsCsv(
        [sampleQuestion, aiQuestion],
        directory: tmpDir,
      );
      expect(result.isSuccess, true);
      final filePath = result.data!;
      final file = File(filePath);
      expect(await file.exists(), true);

      final content = await file.readAsString();
      final lines = content.trim().split('\n');
      expect(lines.length, 3);

      final header = lines[0];
      expect(header, contains('id'));
      expect(header, contains('variantIds'));
      expect(header, contains('allowedAnswerTypes'));
      expect(header, contains('tags'));
      expect(header, contains('difficultyText'));
      expect(header, contains('nextReview'));

      final firstRow = lines[1];
      expect(firstRow, contains('q_test_1'));
      expect(firstRow, contains('What is 2+2?'));
      expect(firstRow, contains('v1|v2'));
      expect(firstRow, contains('src_textbook'));
      expect(firstRow, contains('math;basic'));
      expect(firstRow, contains('easy'));
    });

    test('exportAsJson produces valid JSON array', () async {
      final result = await QuestionExportUtils.exportAsJson(
        [sampleQuestion],
        directory: tmpDir,
      );
      expect(result.isSuccess, true);
      final filePath = result.data!;
      final file = File(filePath);
      expect(await file.exists(), true);

      final content = await file.readAsString();
      expect(content, contains('"id": "q_test_1"'));
      expect(content, contains('"allowedAnswerTypes": "text"'));
      expect(content, contains('"tags"'));
      expect(content, contains('"difficultyText": "easy"'));
      expect(content, contains('"nextReview"'));
    });

    test('exportAsCsv handles empty list', () async {
      final result = await QuestionExportUtils.exportAsCsv([], directory: tmpDir);
      expect(result.isSuccess, true);
      final filePath = result.data!;
      final file = File(filePath);
      final content = await file.readAsString();
      final lines = content.trim().split('\n');
      expect(lines.length, 1);
    });

    test('exportAsJson handles empty list', () async {
      final result = await QuestionExportUtils.exportAsJson([], directory: tmpDir);
      expect(result.isSuccess, true);
      final filePath = result.data!;
      final file = File(filePath);
      final content = await file.readAsString();
      expect(content, '[]');
    });

    test('exportAsCsv escapes commas and quotes in text', () async {
      final qWithComma = Question(
        id: 'q_comma',
        text: 'Hello, world',
        type: QuestionType.typedAnswer,
        subjectId: '',
        topicId: '',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final result = await QuestionExportUtils.exportAsCsv(
        [qWithComma],
        directory: tmpDir,
      );
      expect(result.isSuccess, true);
      final content = await File(result.data!).readAsString();
      expect(content, contains('"Hello, world"'));
    });
  });
}
