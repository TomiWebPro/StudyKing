import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/flashcards/data/models/study_guide_model.dart';

void main() {
  group('StudyGuide model', () {
    test('creates with required fields', () {
      final now = DateTime(2026, 7, 23);
      final guide = StudyGuide(
        id: 'sg1',
        sourceId: 's1',
        topicId: 't1',
        subjectId: 'sub1',
        title: 'Study Guide: Biology',
        content: '# Key Concepts',
        createdAt: now,
      );
      expect(guide.id, 'sg1');
      expect(guide.title, contains('Biology'));
      expect(guide.content, contains('Key Concepts'));
    });

    test('toJson and fromJson round-trip', () {
      final now = DateTime(2026, 7, 23);
      final guide = StudyGuide(
        id: 'sg1',
        sourceId: 's1',
        topicId: 't1',
        subjectId: 'sub1',
        title: 'Study Guide',
        content: 'Content here',
        createdAt: now,
      );
      final json = guide.toJson();
      final restored = StudyGuide.fromJson(json);
      expect(restored.id, guide.id);
      expect(restored.sourceId, guide.sourceId);
      expect(restored.topicId, guide.topicId);
      expect(restored.subjectId, guide.subjectId);
      expect(restored.title, guide.title);
      expect(restored.content, guide.content);
      expect(restored.createdAt, guide.createdAt);
    });

    test('fromJson handles missing optional fields with defaults', () {
      final restored = StudyGuide.fromJson({
        'id': 'sg2',
        'createdAt': DateTime(2026, 7, 23).toIso8601String(),
      });
      expect(restored.id, 'sg2');
      expect(restored.sourceId, '');
      expect(restored.title, '');
      expect(restored.content, '');
    });
  });
}
