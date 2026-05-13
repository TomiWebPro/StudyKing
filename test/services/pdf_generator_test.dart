import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/pdf_generator/question_pdf_generator.dart';

void main() {
  group('QuestionPDFGenerator', () {
    late QuestionPDFGenerator generator;

    setUp(() {
      generator = QuestionPDFGenerator();
    });

    group('addQuestion', () {
      test('adds question without markscheme when showAnswers is false', () async {
        generator.addQuestion('q1', 'What is 2+2?', null, false);

        final result = await generator.exportToJSON(includeAnswers: true);

        expect(result['totalQuestions'], 1);
        expect(result['questions'][0]['id'], 'q1');
        expect(result['questions'][0]['text'], 'What is 2+2?');
        expect(result['questions'][0]['markscheme'], isNull);
      });

      test('adds question with markscheme when showAnswers is true', () async {
        generator.addQuestion('q1', 'What is 2+2?', '4', true);

        final result = await generator.exportToJSON(includeAnswers: true);

        expect(result['questions'][0]['markscheme'], '4');
      });

      test('adds multiple questions in order', () async {
        generator.addQuestion('q1', 'Question 1', null, false);
        generator.addQuestion('q2', 'Question 2', 'Answer 2', true);
        generator.addQuestion('q3', 'Question 3', null, false);

        final result = await generator.exportToJSON(includeAnswers: true);

        expect(result['totalQuestions'], 3);
        expect(result['questions'][0]['id'], 'q1');
        expect(result['questions'][1]['id'], 'q2');
        expect(result['questions'][2]['id'], 'q3');
      });
    });

    group('setMetadata', () {
      test('sets all metadata fields', () async {
        generator.setMetadata(
          title: 'Math Test',
          author: 'John Doe',
          subject: 'Mathematics',
          keywords: ['algebra', 'calculus'],
        );

        final result = await generator.exportToJSON(includeAnswers: true);

        expect(result['metadata']['title'], 'Math Test');
        expect(result['metadata']['author'], 'John Doe');
        expect(result['metadata']['subject'], 'Mathematics');
        expect(result['metadata']['keywords'], ['algebra', 'calculus']);
      });

      test('sets partial metadata with null fields', () async {
        generator.setMetadata(title: 'Partial Test', subject: 'Science');

        final result = await generator.exportToJSON(includeAnswers: true);

        expect(result['metadata']['title'], 'Partial Test');
        expect(result['metadata']['author'], isNull);
        expect(result['metadata']['subject'], 'Science');
        expect(result['metadata']['keywords'], isNull);
      });
    });

    group('generate', () {
      test('generates placeholder PDF with no questions', () async {
        final pdf = await generator.generate();

        expect(pdf, contains('PDF QUESTION GENERATOR'));
        expect(pdf, contains('Total Questions: 0'));
        expect(pdf, contains('Metadata: None'));
      });

      test('generates placeholder PDF with questions', () async {
        generator.addQuestion('q1', 'First question', 'Answer 1', true);
        generator.addQuestion('q2', 'Second question', 'Answer 2', true);

        final pdf = await generator.generate();

        expect(pdf, contains('Total Questions: 2'));
        expect(pdf, contains('Question 1: First question'));
        expect(pdf, contains('Answer: Answer 1'));
        expect(pdf, contains('Question 2: Second question'));
        expect(pdf, contains('Answer: Answer 2'));
      });

      test('generates PDF without answers for hidden markschemes', () async {
        generator.addQuestion('q1', 'Question without answer', null, false);

        final pdf = await generator.generate();

        expect(pdf, contains('Question 1: Question without answer'));
        expect(pdf, isNot(contains('Answer:')));
      });

      test('generates PDF with metadata', () async {
        generator.setMetadata(title: 'Test Title', author: 'Test Author');
        generator.addQuestion('q1', 'Test question', 'Test answer', true);

        final pdf = await generator.generate();

        expect(pdf, contains('Metadata:'));
      });
    });

    group('exportToJSON', () {
      test('exports with all answers by default', () async {
        generator.addQuestion('q1', 'Q1', 'A1', true);
        generator.addQuestion('q2', 'Q2', 'A2', true);

        final result = await generator.exportToJSON();

        expect(result['includeAnswers'], isTrue);
        expect(result['totalQuestions'], 2);
        expect(result['metadata'], isA<Map>());
        expect(result['generatedAt'], isA<String>());
        expect(result['questions'], isA<List>());
      });

      test('exports without answers when includeAnswers is false', () async {
        generator.addQuestion('q1', 'Q1', 'A1', true);

        final result = await generator.exportToJSON(includeAnswers: false);

        expect(result['includeAnswers'], isFalse);
      });

      test('exports with subjectId filter returns zero when no match', () async {
        generator.addQuestion('q1', 'Q1', 'A1', true);

        final result = await generator.exportToJSON(subjectId: 'math');

        expect(result['totalQuestions'], 0);
        expect(result['questions'], isEmpty);
      });

      test('returns empty metadata when none set', () async {
        final result = await generator.exportToJSON();

        expect(result['metadata'], {});
      });

      test('exports zero questions when empty', () async {
        final result = await generator.exportToJSON();

        expect(result['totalQuestions'], 0);
        expect(result['questions'], isEmpty);
      });
    });

    group('exportToCSV', () {
      test('exports CSV with header and questions', () async {
        generator.addQuestion('q1', 'What is 2+2?', '4', true);
        generator.addQuestion('q2', 'What is 3+3?', '6', true);

        final csv = await generator.exportToCSV();
        final lines = csv.split('\n');

        expect(lines[0], 'ID,Question,Answer,Markscheme');
        expect(lines[1], contains('q1'));
        expect(lines[1], contains('What is 2+2?'));
        expect(lines[1], contains('4'));
        expect(lines[2], contains('q2'));
        expect(lines[2], contains('What is 3+3?'));
        expect(lines[2], contains('6'));
      });

      test('escapes commas in question text', () async {
        generator.addQuestion('q1', 'What is 2, 2?', '4', true);

        final csv = await generator.exportToCSV();

        expect(csv, contains('What is 2; 2?'));
      });

      test('exports N/A for null markscheme', () async {
        generator.addQuestion('q1', 'Question only', null, false);

        final csv = await generator.exportToCSV();

        expect(csv, contains('N/A'));
      });

      test('exports empty CSV with only header', () async {
        final csv = await generator.exportToCSV();
        final lines = csv.split('\n').where((l) => l.isNotEmpty).toList();

        expect(lines.length, 1);
        expect(lines[0], 'ID,Question,Answer,Markscheme');
      });
    });

    group('generatePracticePDF', () {
      test('generates practice PDF without answers', () async {
        generator.addQuestion('q1', 'Practice Q1', 'Answer', true);
        generator.addQuestion('q2', 'Practice Q2', 'Answer 2', true);

        final pdf = await generator.generatePracticePDF(
          subjectName: 'Mathematics',
          title: 'Practice Test',
        );

        expect(pdf, contains('PDF QUESTION GENERATOR'));
      });
    });

    group('generateAnswerKeyPDF', () {
      test('generates answer key PDF with answers', () async {
        generator.addQuestion('q1', 'Q1', 'Correct Answer', true);

        final pdf = await generator.generateAnswerKeyPDF(
          subjectName: 'Mathematics',
          title: 'Answer Key',
        );

        expect(pdf, contains('Answer: Correct Answer'));
      });
    });

    group('generateWithAnswers', () {
      test('shows answers when showAnswers is true', () async {
        generator.addQuestion('q1', 'Question', 'Answer', true);

        final pdf = await generator.generateWithAnswers(true);

        expect(pdf, contains('Answer: Answer'));
      });

      test('hides answers when showAnswers is false', () async {
        generator.addQuestion('q1', 'Question', 'Answer', true);

        final pdf = await generator.generateWithAnswers(false);

        expect(pdf, isNot(contains('Answer: Answer')));
      });

      test('clears questions and regenerates', () async {
        generator.addQuestion('q1', 'Q1', 'A1', true);
        generator.addQuestion('q2', 'Q2', 'A2', true);

        await generator.generateWithAnswers(false);

        final result = generator.exportToJSON();
        expect((await result)['totalQuestions'], 2);
      });
    });

    group('clear', () {
      test('clears all questions and metadata', () async {
        generator.addQuestion('q1', 'Q1', 'A1', true);
        generator.setMetadata(title: 'Test');

        generator.clear();

        final result = await generator.exportToJSON();
        expect(result['totalQuestions'], 0);
        expect(result['metadata'], {});
      });

      test('clearing empty generator works', () async {
        generator.clear();

        final result = await generator.exportToJSON();
        expect(result['totalQuestions'], 0);
      });

      test('can add questions after clearing', () async {
        generator.addQuestion('q1', 'Q1', 'A1', true);
        generator.clear();
        generator.addQuestion('q2', 'Q2', 'A2', true);

        final result = await generator.exportToJSON();
        expect(result['totalQuestions'], 1);
        expect(result['questions'][0]['id'], 'q2');
      });
    });

    group('integration workflows', () {
      test('full workflow: add questions, set metadata, generate, export', () async {
        generator.setMetadata(
          title: 'Final Exam',
          author: 'Teacher',
          subject: 'Math',
          keywords: ['exam', 'algebra'],
        );

        generator.addQuestion('q1', 'Solve x + 2 = 5', 'x = 3', true);
        generator.addQuestion('q2', 'Solve 2x = 10', 'x = 5', true);
        generator.addQuestion('q3', 'What is 10 / 2?', '5', false);

        final pdf = await generator.generate();
        final json = await generator.exportToJSON();
        final csv = await generator.exportToCSV();

        expect(pdf, contains('Final Exam'));
        expect(pdf, contains('Total Questions: 3'));
        expect(json['totalQuestions'], 3);
        expect(json['metadata']['title'], 'Final Exam');
        expect(csv, contains('q1'));
        expect(csv, contains('q2'));
        expect(csv, contains('q3'));
      });

      test('practice workflow: generate practice without answers', () async {
        generator.addQuestion('q1', '1 + 1 = ?', '2', true);
        generator.addQuestion('q2', '2 + 2 = ?', '4', true);

        final practicePdf = await generator.generatePracticePDF(
          subjectName: 'Math',
          title: 'Practice Set',
        );

        expect(practicePdf, contains('PDF QUESTION GENERATOR'));
        expect(practicePdf, isNot(contains('Answer: 2')));
      });

      test('answer key workflow: generate answer key with answers', () async {
        generator.addQuestion('q1', '1 + 1 = ?', '2', true);
        generator.addQuestion('q2', '2 + 2 = ?', '4', true);

        final answerKeyPdf = await generator.generateAnswerKeyPDF(
          subjectName: 'Math',
          title: 'Answer Key',
        );

        expect(answerKeyPdf, contains('Answer: 2'));
        expect(answerKeyPdf, contains('Answer: 4'));
      });
    });
  });
}
