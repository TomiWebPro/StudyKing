import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/pdf_generator/question_pdf_generator.dart';

void main() {
  group('QuestionPDFGenerator', () {
    late QuestionPDFGenerator generator;

    setUp(() {
      generator = QuestionPDFGenerator();
    });

    group('addQuestion', () {
      test('adds a question without markscheme when showAnswers is false', () async {
        generator.addQuestion('q1', 'What is 2+2?', '4', false);

        final json = await generator.exportToJSON();
        expect(json['totalQuestions'], 1);
        expect(json['questions'][0]['id'], 'q1');
        expect(json['questions'][0]['text'], 'What is 2+2?');
        expect(json['questions'][0]['markscheme'], isNull);
      });

      test('adds a question with markscheme when showAnswers is true', () async {
        generator.addQuestion('q1', 'What is 2+2?', '4', true);

        final json = await generator.exportToJSON();
        expect(json['totalQuestions'], 1);
        expect(json['questions'][0]['markscheme'], '4');
      });

      test('adds multiple questions', () async {
        generator.addQuestion('q1', 'Q1', 'A1', true);
        generator.addQuestion('q2', 'Q2', 'A2', true);

        final json = await generator.exportToJSON();
        expect(json['totalQuestions'], 2);
      });
    });

    group('setMetadata', () {
      test('sets all metadata fields', () async {
        generator.setMetadata(
          title: 'Math Test',
          author: 'Teacher',
          subject: 'Mathematics',
          keywords: ['algebra', 'geometry'],
        );

        final json = await generator.exportToJSON();
        expect(json['metadata']['title'], 'Math Test');
        expect(json['metadata']['author'], 'Teacher');
        expect(json['metadata']['subject'], 'Mathematics');
        expect(json['metadata']['keywords'], ['algebra', 'geometry']);
      });

      test('defaults to empty metadata when not set', () async {
        final json = await generator.exportToJSON();
        expect(json['metadata'], <String, dynamic>{});
      });
    });

    group('generate', () {
      test('returns placeholder PDF with correct header', () async {
        generator.addQuestion('q1', 'Q1', 'A1', true);

        final output = await generator.generate();

        expect(output, contains('PDF QUESTION GENERATOR'));
        expect(output, contains('Total Questions: 1'));
        expect(output, contains('Question 1: Q1'));
        expect(output, contains('Answer: A1'));
      });

      test('generates without answers when markscheme is hidden', () async {
        generator.addQuestion('q1', 'Q1', 'secret', false);

        final output = await generator.generate();

        expect(output, contains('Q1'));
        expect(output, isNot(contains('secret')));
      });
    });

    group('exportToJSON', () {
      test('exports questions with metadata', () async {
        generator.setMetadata(title: 'Test');
        generator.addQuestion('q1', 'Q1', 'A1', true);

        final json = await generator.exportToJSON();

        expect(json['metadata']['title'], 'Test');
        expect(json['totalQuestions'], 1);
        expect(json['includeAnswers'], isTrue);
        expect(json['questions'].length, 1);
        expect(json['generatedAt'], isNotEmpty);
      });

      test('returns all questions when no subjectId filter', () async {
        generator.addQuestion('q1', 'Q1', 'A1', true);
        generator.addQuestion('q2', 'Q2', 'A2', true);

        final json = await generator.exportToJSON();

        expect(json['totalQuestions'], 2);
      });
    });

    group('exportToCSV', () {
      test('exports CSV with header row', () async {
        generator.addQuestion('q1', 'What is 2+2?', '4', true);

        final csv = await generator.exportToCSV();

        expect(csv, contains('ID,Question,Answer,Markscheme'));
        expect(csv, contains('q1'));
        expect(csv, contains('What is 2+2?'));
      });

      test('escapes commas in question text', () async {
        generator.addQuestion('q1', 'A, B, C', 'A', true);

        final csv = await generator.exportToCSV();

        expect(csv, contains('A; B; C'));
      });

      test('shows N/A when markscheme is null', () async {
        generator.addQuestion('q1', 'Q1', null, true);

        final csv = await generator.exportToCSV();

        expect(csv, contains('N/A'));
      });
    });

    group('generatePracticePDF', () {
      test('generates PDF without answers', () async {
        generator.addQuestion('q1', 'Q1', 'secret', true);

        final output = await generator.generatePracticePDF(
          subjectName: 'Math',
          title: 'Practice',
        );

        expect(output, contains('PDF QUESTION GENERATOR'));
        expect(output, isNot(contains('secret')));
      });
    });

    group('generateAnswerKeyPDF', () {
      test('generates PDF with answers', () async {
        generator.addQuestion('q1', 'Q1', 'answer-key', true);

        final output = await generator.generateAnswerKeyPDF(
          subjectName: 'Math',
          title: 'Answer Key',
        );

        expect(output, contains('answer-key'));
      });
    });

    group('generateWithAnswers', () {
      test('strips markscheme when showAnswers is false', () async {
        generator.addQuestion('q1', 'Q1', 'secret', true);

        await generator.generateWithAnswers(false);

        final json = await generator.exportToJSON();
        expect(json['questions'][0]['markscheme'], isNull);
      });

      test('preserves markscheme when showAnswers is true', () async {
        generator.addQuestion('q1', 'Q1', 'visible', true);

        await generator.generateWithAnswers(true);

        final json = await generator.exportToJSON();
        expect(json['questions'][0]['markscheme'], 'visible');
      });
    });

    group('clear', () {
      test('removes all questions and metadata', () async {
        generator.addQuestion('q1', 'Q1', 'A1', true);
        generator.setMetadata(title: 'Test');
        generator.clear();

        final json = await generator.exportToJSON();
        expect(json['totalQuestions'], 0);
        expect(json['metadata'], <String, dynamic>{});
      });
    });
  });
}
