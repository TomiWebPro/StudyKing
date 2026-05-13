import 'graph_type_detector.dart';

class LessonSchedulerCommands {
  final Map<String, int> mcqOptionsRange = {};

  int getMcqOptionsCount(String lessonType) {
    return 5;
  }

  Future<void> fetchMcqOptionsRange() async {
    // stub - no-op
  }

  Future<Map<String, dynamic>> generateMcqQuestion({
    required String question,
    required String sourceMaterial,
    int? numOptions,
  }) async {
    return {
      'question': question,
      'options': <String>['Option A', 'Option B', 'Option C'],
      'answer': 'Option A',
      'topic': 'dynamic_topic',
    };
  }

  Future<String> generateOption({String? text, String? answer}) async {
    return text ?? 'Option';
  }
}

class GraphRenderingService {
  Future<Map<String, dynamic>> generateGraphFromStory({
    required String story,
    required String theme,
  }) async {
    throw GraphError('API failure');
  }
}
