import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/mentor/services/mentor_keywords.dart';

void main() {
  group('MentorKeywords', () {
    test('extractKeywordsByLocale has entries for en, es, fr, de', () {
      expect(MentorKeywords.extractKeywordsByLocale.containsKey('en'), isTrue);
      expect(MentorKeywords.extractKeywordsByLocale.containsKey('es'), isTrue);
      expect(MentorKeywords.extractKeywordsByLocale.containsKey('fr'), isTrue);
      expect(MentorKeywords.extractKeywordsByLocale.containsKey('de'), isTrue);
    });

    test('extractKeywordsByLocale lists are non-empty', () {
      for (final entry in MentorKeywords.extractKeywordsByLocale.entries) {
        expect(entry.value, isNotEmpty);
      }
    });

    test('extractKeywordsByLocale contains expected entries', () {
      final en = MentorKeywords.extractKeywordsByLocale['en']!;
      expect(en, contains('study '));
      expect(en, contains('learn '));
      expect(en, contains('review '));
      expect(en, contains('practice '));
    });

    test('extractTopicKeywordsByLocale has expected content', () {
      final en = MentorKeywords.extractTopicKeywordsByLocale['en']!;
      expect(en, contains('topic '));
      expect(en, contains('subject '));
      expect(en, contains('lesson '));

      final es = MentorKeywords.extractTopicKeywordsByLocale['es']!;
      expect(es, contains('tema '));
      expect(es, contains('materia '));
      expect(es, contains('lección '));
    });

    test('extractTopicKeywordsByLocale lists are non-empty', () {
      for (final entry in MentorKeywords.extractTopicKeywordsByLocale.entries) {
        expect(entry.value, isNotEmpty);
      }
    });

    test('scheduleKeywordsByLocale exists for en and es', () {
      expect(MentorKeywords.scheduleKeywordsByLocale.containsKey('en'), isTrue);
      expect(MentorKeywords.scheduleKeywordsByLocale.containsKey('es'), isTrue);
    });

    test('scheduleKeywordsByLocale lists are non-empty', () {
      for (final entry in MentorKeywords.scheduleKeywordsByLocale.entries) {
        expect(entry.value, isNotEmpty);
      }
    });

    test('rescheduleKeywordsByLocale exists for en and es', () {
      expect(MentorKeywords.rescheduleKeywordsByLocale.containsKey('en'), isTrue);
      expect(MentorKeywords.rescheduleKeywordsByLocale.containsKey('es'), isTrue);
    });

    test('rescheduleKeywordsByLocale lists are non-empty', () {
      for (final entry in MentorKeywords.rescheduleKeywordsByLocale.entries) {
        expect(entry.value, isNotEmpty);
      }
    });

    test('planKeywordsByLocale exists for en and es', () {
      expect(MentorKeywords.planKeywordsByLocale.containsKey('en'), isTrue);
      expect(MentorKeywords.planKeywordsByLocale.containsKey('es'), isTrue);
    });

    test('planKeywordsByLocale lists are non-empty', () {
      for (final entry in MentorKeywords.planKeywordsByLocale.entries) {
        expect(entry.value, isNotEmpty);
      }
    });

    test('planKeywordsByLocale contains expected entries', () {
      final en = MentorKeywords.planKeywordsByLocale['en']!;
      expect(en, contains('plan'));
      expect(en, contains('roadmap'));
      expect(en, contains('milestone'));

      final es = MentorKeywords.planKeywordsByLocale['es']!;
      expect(es, contains('plan'));
      expect(es, contains('planificar'));
    });
  });
}
