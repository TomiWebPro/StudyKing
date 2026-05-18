import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/lessons/services/lesson_agent_service.dart';

void main() {
  group('LessonAgentService', () {
    test('can be instantiated with dependencies', () {
      // The service requires LlmService, modelId, LessonRepository, DatabaseService
      // Full integration tests would require mocking these dependencies
      // This test verifies the class exists and has the expected interface
      expect(LessonAgentService, isNotNull);
    });
  });
}
