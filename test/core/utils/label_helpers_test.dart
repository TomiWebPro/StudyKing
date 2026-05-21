import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/utils/label_helpers.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('questionTypeLabel', () {
    test('returns Multiple Choice for singleChoice', () {
      expect(questionTypeLabel(QuestionType.singleChoice, l10n), 'Multiple Choice');
    });

    test('returns Multiple Select for multiChoice', () {
      expect(questionTypeLabel(QuestionType.multiChoice, l10n), 'Multiple Select');
    });

    test('returns Text Answer for typedAnswer', () {
      expect(questionTypeLabel(QuestionType.typedAnswer, l10n), 'Text Answer');
    });

    test('returns Canvas for canvas', () {
      expect(questionTypeLabel(QuestionType.canvas, l10n), 'Canvas');
    });

    test('returns Essay for essay', () {
      expect(questionTypeLabel(QuestionType.essay, l10n), 'Essay');
    });

    test('returns Step-by-Step for stepByStep', () {
      expect(questionTypeLabel(QuestionType.stepByStep, l10n), 'Step-by-Step');
    });

    test('returns Math for mathExpression', () {
      expect(questionTypeLabel(QuestionType.mathExpression, l10n), 'Math');
    });

    test('returns Graph Drawing for graphDrawing', () {
      expect(questionTypeLabel(QuestionType.graphDrawing, l10n), 'Graph Drawing');
    });

    test('returns File Upload for fileUpload', () {
      expect(questionTypeLabel(QuestionType.fileUpload, l10n), 'File Upload');
    });

    test('returns Audio Recording for audioRecording', () {
      expect(questionTypeLabel(QuestionType.audioRecording, l10n), 'Audio Recording');
    });
  });

  group('sourceTypeLabel', () {
    test('returns PDF for pdf', () {
      expect(sourceTypeLabel(SourceType.pdf, l10n), 'PDF');
    });

    test('returns Syllabus for syllabus', () {
      expect(sourceTypeLabel(SourceType.syllabus, l10n), 'Syllabus');
    });

    test('returns Textbook for textbook', () {
      expect(sourceTypeLabel(SourceType.textbook, l10n), 'Textbook');
    });

    test('returns Video for video', () {
      expect(sourceTypeLabel(SourceType.video, l10n), 'Video');
    });

    test('returns Lecture Notes for lectureNotes', () {
      expect(sourceTypeLabel(SourceType.lectureNotes, l10n), 'Lecture Notes');
    });

    test('returns External Resource for externalResource', () {
      expect(sourceTypeLabel(SourceType.externalResource, l10n), 'External Resource');
    });

    test('returns Image for image', () {
      expect(sourceTypeLabel(SourceType.image, l10n), 'Image');
    });

    test('returns Web Page for webPage', () {
      expect(sourceTypeLabel(SourceType.webPage, l10n), 'Web Page');
    });

    test('returns Audio for audio', () {
      expect(sourceTypeLabel(SourceType.audio, l10n), 'Audio');
    });

    test('returns Document for document', () {
      expect(sourceTypeLabel(SourceType.document, l10n), 'Document');
    });
  });

  group('processingStatusLabel', () {
    test('returns Pending for pending', () {
      expect(processingStatusLabel(ProcessingStatus.pending, l10n), 'Pending');
    });

    test('returns Extracting for extracting', () {
      expect(processingStatusLabel(ProcessingStatus.extracting, l10n), 'Extracting');
    });

    test('returns Processing for classifying', () {
      expect(processingStatusLabel(ProcessingStatus.classifying, l10n), 'Processing');
    });

    test('returns Processing for summarizing', () {
      expect(processingStatusLabel(ProcessingStatus.summarizing, l10n), 'Processing');
    });

    test('returns Generating Questions for generatingQuestions', () {
      expect(processingStatusLabel(ProcessingStatus.generatingQuestions, l10n), 'Generating Questions');
    });

    test('returns Validating... for validating', () {
      expect(processingStatusLabel(ProcessingStatus.validating, l10n), 'Validating...');
    });

    test('returns Completed for completed', () {
      expect(processingStatusLabel(ProcessingStatus.completed, l10n), 'Completed');
    });

    test('returns Failed for failed', () {
      expect(processingStatusLabel(ProcessingStatus.failed, l10n), 'Failed');
    });
  });
}
