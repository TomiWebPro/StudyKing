import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';

class _SearchTool extends AgentTool {
  @override
  String get name => 'searchQuestions';
  @override
  String get description => 'Search questions by topic';
  @override
  Map<String, dynamic> get parameters => {'topic': {'type': 'string'}};

  @override
  Future<dynamic> execute(Map<String, dynamic> args) async {
    return {'results': ['Q1', 'Q2'], 'count': 2};
  }
}

void main() {
  group('ToolRegistry integration', () {
    test('searchQuestions tool executes', () async {
      final registry = ToolRegistry();
      final tool = _SearchTool();
      registry.register(tool);

      final retrieved = registry.get('searchQuestions');
      expect(retrieved, isNotNull);

      final result = await retrieved!.execute({'topic': 'physics'});
      expect(result, isA<Map>());
      expect((result as Map)['count'], 2);
    });

    test('unknown tool returns null from registry', () {
      final registry = ToolRegistry();
      expect(registry.get('unknown'), isNull);
    });
  });
}
