import 'package:studyking/core/data/enums.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

extension QuestionTypeLocalized on QuestionType {
  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
      QuestionType.singleChoice => l10n.multipleChoice,
      QuestionType.multiChoice => l10n.multipleSelect,
      QuestionType.typedAnswer => l10n.textAnswer,
      QuestionType.canvas => l10n.diagram,
      QuestionType.essay => l10n.essay,
      QuestionType.stepByStep => l10n.stepByStep,
      QuestionType.mathExpression => l10n.math,
      QuestionType.graphDrawing => l10n.graphQuestion,
      QuestionType.fileUpload => l10n.questionTypeDefault,
      QuestionType.audioRecording => l10n.questionTypeDefault,
    };
  }
}
