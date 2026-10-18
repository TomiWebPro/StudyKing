// Enums file with proper TypeAdapters

enum QuestionType {
  singleChoice,
  multiChoice,
  typedAnswer,
  canvas,
  essay,
  stepByStep,
  mathExpression,
  graphDrawing,
  fileUpload,
  audioRecording,
}

enum SourceType {
  pdf,
  syllabus,
  textbook,
  video,
  lectureNotes,
  externalResource,
  image,
  webPage,
  audio,
  document,
}

enum ProcessingStatus {
  pending,
  extracting,
  classifying,
  summarizing,
  generatingQuestions,
  generatingFlashcards,
  validating,
  completed,
  failed,
}

enum LessonBlockType {
  text,
  example,
  exercise,
  slide,
  quiz,
  summary,
  visual,
  analogy,
}

enum SlideType {
  title,
  concept,
  definition,
  formula,
  example,
  summary,
  quiz,
  reference,
  tableOfContents,
}

enum GeneratedBy {
  ai,
  manual,
  hybrid,
}

/// Validation status for AI-generated artefacts (vision_next_term.md §4.3:
/// "every auto-created artefact is marked `ai-generated + validation status`
/// until human/validator approves").
///
/// - `pending`: artefact was auto-created and has not yet been reviewed/approved.
/// - `approved`: artefact has been validated and is trustworthy.
enum ValidationStatus {
  pending,
  approved,
}
