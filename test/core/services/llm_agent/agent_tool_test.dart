import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';

class _TestTool extends AgentTool {
  @override
  String get name => 'test_tool';

  @override
  String get description => 'A test tool';

  @override
  Map<String, dynamic> get parameters => {'param1': {'type': 'string'}};

  @override
  Future<dynamic> execute(Map<String, dynamic> args) async {
    return 'executed ${args['param1']}';
  }
}

void main() {
  group('ToolRegistry', () {
    test('registers and retrieves a tool', () {
      final registry = ToolRegistry();
      registry.register(_TestTool());
      final tool = registry.get('test_tool');
      expect(tool, isNotNull);
      expect(tool!.name, 'test_tool');
    });

    test('returns null for unregistered tool', () {
      final registry = ToolRegistry();
      expect(registry.get('nonexistent'), isNull);
    });

    test('toolDescriptions returns correct format', () {
      final registry = ToolRegistry();
      registry.register(_TestTool());
      final descriptions = registry.toolDescriptions;
      expect(descriptions.length, 1);
      expect(descriptions[0]['name'], 'test_tool');
      expect(descriptions[0]['description'], 'A test tool');
      expect(descriptions[0]['parameters'], {'param1': {'type': 'string'}});
    });

    test('toolNames contains registered tool names', () {
      final registry = ToolRegistry();
      registry.register(_TestTool());
      expect(registry.toolNames, contains('test_tool'));
    });

    test('overwrites tool when re-registering same name', () {
      final registry = ToolRegistry();
      registry.register(_TestTool());
      registry.register(_TestTool());
      expect(registry.toolNames.length, 1);
    });
  });
}
