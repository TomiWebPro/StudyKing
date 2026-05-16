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
  generatingQuestions,
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
}

enum GeneratedBy {
  ai,
  manual,
  hybrid,
}
