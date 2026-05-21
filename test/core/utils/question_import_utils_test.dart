import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/utils/question_import_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuestionImportUtils.importFromText', () {
    test('imports simple text lines as typedAnswer questions', () async {
      final result = await QuestionImportUtils.importFromText('Line 1\nLine 2\nLine 3');
      expect(result.isSuccess, true);
      final questions = result.data!;
      expect(questions.length, 3);
      expect(questions[0].text, 'Line 1');
      expect(questions[0].type, QuestionType.typedAnswer);
      expect(questions[1].text, 'Line 2');
      expect(questions[2].text, 'Line 3');
    });

    test('imports structured text with || delimiter', () async {
      final text = 'What is 2+2? || 4 || singleChoice || subj_math || topic_arithmetic';
      final result = await QuestionImportUtils.importFromText(text);
      expect(result.isSuccess, true);
      final questions = result.data!;
      expect(questions.length, 1);
      expect(questions[0].text, 'What is 2+2?');
      expect(questions[0].markscheme?.correctAnswer, '4');
      expect(questions[0].type, QuestionType.singleChoice);
      expect(questions[0].subjectId, 'subj_math');
      expect(questions[0].topicId, 'topic_arithmetic');
    });

    test('imports structured text with multiChoice type shorthand', () async {
      final text = 'Pick all that apply || A, B || mc || subj_test || topic_test';
      final result = await QuestionImportUtils.importFromText(text);
      expect(result.isSuccess, true);
      final questions = result.data!;
      expect(questions.length, 1);
      expect(questions[0].type, QuestionType.multiChoice);
    });

    test('imports structured text with typedAnswer type shorthand', () async {
      final text = 'Define x || x is a variable || ta || subj_math || topic_algebra';
      final result = await QuestionImportUtils.importFromText(text);
      expect(result.isSuccess, true);
      final questions = result.data!;
      expect(questions.length, 1);
      expect(questions[0].type, QuestionType.typedAnswer);
    });

    test('falls back to basic typedAnswer for lines without || delimiter', () async {
      final result = await QuestionImportUtils.importFromText('Just a plain line');
      expect(result.isSuccess, true);
      final questions = result.data!;
      expect(questions.length, 1);
      expect(questions[0].text, 'Just a plain line');
      expect(questions[0].type, QuestionType.typedAnswer);
      expect(questions[0].subjectId, '');
      expect(questions[0].topicId, '');
    });

    test('handles empty input', () async {
      final result = await QuestionImportUtils.importFromText('');
      expect(result.isSuccess, true);
      expect(result.data, isEmpty);
    });

    test('handles whitespace-only input', () async {
      final result = await QuestionImportUtils.importFromText('   \n  \n  ');
      expect(result.isSuccess, true);
      expect(result.data, isEmpty);
    });

    test('mixed structured and unstructured lines', () async {
      final text = 'Simple line\nWhat is 2+2? || 4 || singleChoice || subj_math || topic_arith\nAnother plain';
      final result = await QuestionImportUtils.importFromText(text);
      expect(result.isSuccess, true);
      final questions = result.data!;
      expect(questions.length, 3);
      expect(questions[0].type, QuestionType.typedAnswer);
      expect(questions[1].type, QuestionType.singleChoice);
      expect(questions[1].markscheme?.correctAnswer, '4');
      expect(questions[2].type, QuestionType.typedAnswer);
    });

    test('generates unique IDs for each imported question', () async {
      final result = await QuestionImportUtils.importFromText('Q1\nQ2\nQ3');
      expect(result.isSuccess, true);
      final questions = result.data!;
      final ids = questions.map((q) => q.id).toSet();
      expect(ids.length, 3);
    });
  });

  group('QuestionImportUtils.importFromJsonString', () {
    test('imports valid JSON string', () async {
      final json = '''
      [
        {
          "id": "q1",
          "text": "Test question",
          "type": 0,
          "difficulty": 1,
          "subjectId": "subj_1",
          "topicId": "topic_1",
          "options": [],
          "createdAt": "2026-01-01T00:00:00.000",
          "updatedAt": "2026-01-01T00:00:00.000"
        }
      ]
      ''';
      final result = await QuestionImportUtils.importFromJsonString(json);
      expect(result.isSuccess, true);
      expect(result.data!.length, 1);
      expect(result.data![0].text, 'Test question');
      expect(result.data![0].id, 'q1');
    });

    test('skips existing IDs with skipExisting strategy', () async {
      final json = '''
      [
        {"id": "q1", "text": "First", "type": 0, "difficulty": 1, "subjectId": "", "topicId": "", "options": [], "createdAt": "2026-01-01T00:00:00.000", "updatedAt": "2026-01-01T00:00:00.000"},
        {"id": "q2", "text": "Second", "type": 0, "difficulty": 1, "subjectId": "", "topicId": "", "options": [], "createdAt": "2026-01-01T00:00:00.000", "updatedAt": "2026-01-01T00:00:00.000"}
      ]
      ''';
      final result = await QuestionImportUtils.importFromJsonString(
        json,
        existingIds: {'q1'},
        strategy: ConflictStrategy.skipExisting,
      );
      expect(result.isSuccess, true);
      expect(result.data!.length, 1);
      expect(result.data![0].id, 'q2');
    });

    test('handles empty JSON array', () async {
      final result = await QuestionImportUtils.importFromJsonString('[]');
      expect(result.isSuccess, true);
      expect(result.data, isEmpty);
    });

    test('rejects invalid JSON', () async {
      final result = await QuestionImportUtils.importFromJsonString('not json');
      expect(result.isSuccess, false);
    });

    test('parses tags and allowedAnswerTypes from JSON', () async {
      final json = '''
      [
        {
          "id": "q_tags",
          "text": "Tagged question",
          "type": 0,
          "difficulty": 1,
          "subjectId": "subj_1",
          "topicId": "topic_1",
          "options": [],
          "tags": ["tag1", "tag2"],
          "allowedAnswerTypes": "text,voice",
          "difficultyText": "hard",
          "createdAt": "2026-01-01T00:00:00.000",
          "updatedAt": "2026-01-01T00:00:00.000"
        }
      ]
      ''';
      final result = await QuestionImportUtils.importFromJsonString(json);
      expect(result.isSuccess, true);
      final q = result.data!.first;
      expect(q.tags, ['tag1', 'tag2']);
      expect(q.allowedAnswerTypes, 'text,voice');
      expect(q.difficultyText, 'hard');
    });
  });

  group('QuestionImportUtils.importFromCsv', () {
    test('imports from CSV file with 18-column format', () async {
      final csv = '''id,text,type,difficulty,subjectId,topicId,variantIds,sourceIds,options,allowedAnswerTypes,correctAnswer,explanation,tags,model,difficultyText,nextReview,createdAt,updatedAt
q_imp_1,Imported question,0,1,subj_1,topic_1,,src_1,opt1|opt2,text,opt1,Explanation text,tag1;tag2,,easy,2026-06-01T00:00:00.000,2026-01-01T00:00:00.000,2026-05-20T00:00:00.000''';
      final file = File('${Directory.systemTemp.path}/test_import_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);

      final result = await QuestionImportUtils.importFromCsv(file.path);
      expect(result.isSuccess, true);
      final questions = result.data!;
      expect(questions.length, 1);
      expect(questions[0].text, 'Imported question');
      expect(questions[0].subjectId, 'subj_1');
      expect(questions[0].topicId, 'topic_1');
      expect(questions[0].options, ['opt1', 'opt2']);
      expect(questions[0].allowedAnswerTypes, 'text');
      expect(questions[0].markscheme?.correctAnswer, 'opt1');
      expect(questions[0].explanation, 'Explanation text');
      expect(questions[0].tags, ['tag1', 'tag2']);
      expect(questions[0].difficultyText, 'easy');
      expect(questions[0].nextReview, DateTime(2026, 6, 1));

      await file.delete();
    });

    test('imports from old CSV with 13-column format (backward compat)', () async {
      final csv = '''id,text,type,difficulty,subjectId,topicId,sourceIds,options,correctAnswer,explanation,model,createdAt,updatedAt
q_old,Old question,0,1,subj_1,topic_1,src_1,opt1|opt2,opt1,Old explanation,,2026-01-01T00:00:00.000,2026-05-20T00:00:00.000''';
      final file = File('${Directory.systemTemp.path}/test_import_old_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);

      final result = await QuestionImportUtils.importFromCsv(file.path);
      expect(result.isSuccess, true);
      final questions = result.data!;
      expect(questions.length, 1);
      expect(questions[0].text, 'Old question');
      expect(questions[0].subjectId, 'subj_1');
      expect(questions[0].topicId, 'topic_1');
      expect(questions[0].sourceIds, ['src_1']);
      expect(questions[0].options, ['opt1', 'opt2']);
      expect(questions[0].markscheme?.correctAnswer, 'opt1');
      expect(questions[0].explanation, 'Old explanation');

      await file.delete();
    });

    test('importFromCsv fails on missing file', () async {
      final result = await QuestionImportUtils.importFromCsv('/nonexistent/file.csv');
      expect(result.isSuccess, false);
    });
  });

  group('QuestionImportUtils.importFromJson', () {
    test('import from JSON file', () async {
      final json = '''
      [
        {
          "id": "q_file_1",
          "text": "From file",
          "type": 1,
          "difficulty": 2,
          "subjectId": "subj_2",
          "topicId": "",
          "options": ["A", "B"],
          "createdAt": "2026-01-01T00:00:00.000",
          "updatedAt": "2026-01-01T00:00:00.000"
        }
      ]
      ''';
      final file = File('${Directory.systemTemp.path}/test_import_json_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(json);

      final result = await QuestionImportUtils.importFromJson(file.path);
      expect(result.isSuccess, true);
      expect(result.data!.length, 1);
      expect(result.data![0].text, 'From file');
      expect(result.data![0].type, QuestionType.values[1]);

      await file.delete();
    });
  });
}
