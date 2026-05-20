import 'package:studyking/core/data/enums.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

String questionTypeLabel(QuestionType type, AppLocalizations l10n) {
  switch (type) {
    case QuestionType.singleChoice:
      return l10n.multipleChoice;
    case QuestionType.multiChoice:
      return l10n.multipleSelect;
    case QuestionType.typedAnswer:
      return l10n.textAnswer;
    case QuestionType.canvas:
      return l10n.canvas;
    case QuestionType.essay:
      return l10n.essay;
    case QuestionType.stepByStep:
      return l10n.stepByStep;
    case QuestionType.mathExpression:
      return l10n.math;
    case QuestionType.graphDrawing:
      return l10n.graphDrawing;
    case QuestionType.fileUpload:
      return l10n.fileUpload;
    case QuestionType.audioRecording:
      return l10n.audioRecording;
  }
}

String sourceTypeLabel(SourceType type, AppLocalizations l10n) {
  switch (type) {
    case SourceType.pdf:
      return l10n.pdfLabel;
    case SourceType.syllabus:
      return l10n.syllabusLabel;
    case SourceType.textbook:
      return l10n.textbookLabel;
    case SourceType.video:
      return l10n.videoLabel;
    case SourceType.lectureNotes:
      return l10n.lectureNotesLabel;
    case SourceType.externalResource:
      return l10n.externalResourceLabel;
    case SourceType.image:
      return l10n.imageLabel;
    case SourceType.webPage:
      return l10n.webPageLabel;
    case SourceType.audio:
      return l10n.audioLabel;
    case SourceType.document:
      return l10n.documentLabel;
  }
}

String processingStatusLabel(ProcessingStatus status, AppLocalizations l10n) {
  switch (status) {
    case ProcessingStatus.pending:
      return l10n.pending;
    case ProcessingStatus.extracting:
      return l10n.extracting;
    case ProcessingStatus.classifying:
      return l10n.processing;
    case ProcessingStatus.summarizing:
      return l10n.processing;
    case ProcessingStatus.generatingQuestions:
      return l10n.generatingQuestions;
    case ProcessingStatus.validating:
      return l10n.validating;
    case ProcessingStatus.completed:
      return l10n.completed;
    case ProcessingStatus.failed:
      return l10n.failed;
  }
}
