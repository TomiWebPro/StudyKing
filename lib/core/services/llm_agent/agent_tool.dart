import 'dart:async';

abstract class AgentTool {
  String get name;
  String get description;
  Map<String, dynamic> get parameters;

  Future<dynamic> execute(Map<String, dynamic> args);

  /// Tolerantly parse an integer tool argument.
  ///
  /// LLMs routinely emit JSON strings for numeric parameters despite the
  /// `"type": "integer"` schema (e.g. `{"days": "30"}`). Accept a `num`
  /// or a numeric string; return null when the argument is absent or
  /// unparseable. Untrusted LLM input must never be downcast with
  /// `as num?` — that throws on a string.
  static int? intArg(Map<String, dynamic> args, String key) {
    final value = args[key];
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
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
