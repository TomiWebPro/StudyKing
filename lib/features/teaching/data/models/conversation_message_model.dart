import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

enum MessageRole { system, tutor, student, mentor }

enum MessageType { text, exercise, quiz, feedback, plan, system, toolCall, toolResult }

@HiveType(typeId: 27)
class ConversationMessage extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String sessionId;

  @HiveField(2)
  final MessageRole role;

  @HiveField(3)
  final MessageType type;

  @HiveField(4)
  final String content;

  @HiveField(5)
  final String? metadataJson;

  @HiveField(6)
  final DateTime timestamp;

  @HiveField(7)
  final int tokenCount;

  @HiveField(8)
  final bool isStreaming;

  @HiveField(9)
  final String? toolCallId;

  @HiveField(10)
  final String? toolName;

  @HiveField(11)
  final String? toolArguments;

  @HiveField(12)
  final String? toolResult;

  final bool isEvaluation;

  ConversationMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.type,
    required this.content,
    this.metadataJson,
    required this.timestamp,
    this.tokenCount = 0,
    this.isStreaming = false,
    this.toolCallId,
    this.toolName,
    this.toolArguments,
    this.toolResult,
    bool? isEvaluation,
  }) : isEvaluation = isEvaluation ?? _computeIsEvaluation(content);

  static bool _computeIsEvaluation(String content) {
    try {
      final data = jsonDecode(content) as Map<String, dynamic>;
      return data['type'] == 'evaluation';
    } catch (_) {
      return false;
    }
  }

  ConversationMessage copyWith({
    String? id,
    String? sessionId,
    MessageRole? role,
    MessageType? type,
    String? content,
    String? metadataJson,
    DateTime? timestamp,
    int? tokenCount,
    bool? isStreaming,
    String? toolCallId,
    String? toolName,
    String? toolArguments,
    String? toolResult,
  }) {
    return ConversationMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      type: type ?? this.type,
      content: content ?? this.content,
      metadataJson: metadataJson ?? this.metadataJson,
      timestamp: timestamp ?? this.timestamp,
      tokenCount: tokenCount ?? this.tokenCount,
      isStreaming: isStreaming ?? this.isStreaming,
      toolCallId: toolCallId ?? this.toolCallId,
      toolName: toolName ?? this.toolName,
      toolArguments: toolArguments ?? this.toolArguments,
      toolResult: toolResult ?? this.toolResult,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'role': role.name,
    'type': type.name,
    'content': content,
    'metadataJson': metadataJson,
    'timestamp': timestamp.toIso8601String(),
    'tokenCount': tokenCount,
    'isStreaming': isStreaming,
    'toolCallId': toolCallId,
    'toolName': toolName,
    'toolArguments': toolArguments,
    'toolResult': toolResult,
  };

  factory ConversationMessage.fromJson(Map<String, dynamic> json) => ConversationMessage(
    id: json['id'],
    sessionId: json['sessionId'],
    role: MessageRole.values.firstWhere((r) => r.name == json['role']),
    type: MessageType.values.firstWhere((t) => t.name == json['type']),
    content: json['content'],
    metadataJson: json['metadataJson'],
    timestamp: DateTime.parse(json['timestamp']),
    tokenCount: json['tokenCount'] ?? 0,
    isStreaming: json['isStreaming'] ?? false,
    toolCallId: json['toolCallId'],
    toolName: json['toolName'],
    toolArguments: json['toolArguments'],
    toolResult: json['toolResult'],
  );
}
