import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/utils/label_helpers.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('questionTypeLabel', () {
    for (final type in QuestionType.values) {
      test('returns non-null label for QuestionType.$type', () {
        expect(questionTypeLabel(type, l10n), isNotNull);
      });
    }
  });

  group('sourceTypeLabel', () {
    for (final type in SourceType.values) {
      test('returns non-null label for SourceType.$type', () {
        expect(sourceTypeLabel(type, l10n), isNotNull);
      });
    }
  });

  group('processingStatusLabel', () {
    for (final status in ProcessingStatus.values) {
      test('returns non-null label for ProcessingStatus.$status', () {
        expect(processingStatusLabel(status, l10n), isNotNull);
      });
    }
  });
}
