import 'dart:async';

abstract class AgentTool {
  String get name;
  String get description;
  Map<String, dynamic> get parameters;

  Future<dynamic> execute(Map<String, dynamic> args);
}

class ToolRegistry {
  final Map<String, AgentTool> _tools = {};

  void register(AgentTool tool) {
    _tools[tool.name] = tool;
  }

  AgentTool? get(String name) => _tools[name];

  List<Map<String, dynamic>> get toolDescriptions => _tools.values.map((t) => {
    'name': t.name,
    'description': t.description,
    'parameters': t.parameters,
  }).toList();

  Set<String> get toolNames => _tools.keys.toSet();
}
