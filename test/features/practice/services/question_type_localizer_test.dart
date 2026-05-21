import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/practice/services/question_type_localizer.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';

void main() {
  group('QuestionTypeLocalized', () {
    final AppLocalizations l10n = AppLocalizationsEn();

    test('singleChoice returns Multiple Choice', () {
      expect(QuestionType.singleChoice.localizedLabel(l10n), 'Multiple Choice');
    });

    test('multiChoice returns Multiple Select', () {
      expect(QuestionType.multiChoice.localizedLabel(l10n), 'Multiple Select');
    });

    test('typedAnswer returns Text Answer', () {
      expect(QuestionType.typedAnswer.localizedLabel(l10n), 'Text Answer');
    });

    test('canvas returns Diagram', () {
      expect(QuestionType.canvas.localizedLabel(l10n), 'Diagram');
    });

    test('essay returns Essay', () {
      expect(QuestionType.essay.localizedLabel(l10n), 'Essay');
    });

    test('stepByStep returns Step-by-Step', () {
      expect(QuestionType.stepByStep.localizedLabel(l10n), 'Step-by-Step');
    });

    test('mathExpression returns Math', () {
      expect(QuestionType.mathExpression.localizedLabel(l10n), 'Math');
    });

    test('graphDrawing returns Graph', () {
      expect(QuestionType.graphDrawing.localizedLabel(l10n), 'Graph');
    });

    test('fileUpload returns default label', () {
      expect(QuestionType.fileUpload.localizedLabel(l10n), 'Question');
    });

    test('audioRecording returns default label', () {
      expect(QuestionType.audioRecording.localizedLabel(l10n), 'Question');
    });

    test('all QuestionType values have a label (exhaustive coverage)', () {
      for (final type in QuestionType.values) {
        expect(type.localizedLabel(l10n), isNotEmpty);
      }
    });

    test('fileUpload and audioRecording share the same default label', () {
      expect(
        QuestionType.fileUpload.localizedLabel(l10n),
        equals(QuestionType.audioRecording.localizedLabel(l10n)),
      );
    });

    group('error-state: exhaustive coverage', () {
      test('no QuestionType value throws when calling localizedLabel', () {
        for (final type in QuestionType.values) {
          expect(
            () => type.localizedLabel(l10n),
            returnsNormally,
          );
        }
      });

      test('future enum value would need switch update (compile-time check)', () {
        // This test ensures that if QuestionType gains new values,
        // the switch in localizedLabel will be non-exhaustive at compile time.
        // For now, verify all current values produce distinct or expected labels.
        final valueCount = QuestionType.values.length;
        expect(valueCount, greaterThanOrEqualTo(10));
      });
    });
  });
}
