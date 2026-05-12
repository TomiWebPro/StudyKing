import 'package:flutter/material.dart';
import '../../models/llm_config.dart';
import '../../providers/llm_engine_provider.dart';
import 'package:provider/provider.dart';

/// Main chat application UI
class LLMApplcationPage extends StatefulWidget {
  final LLMAIEngineProvider engineProvider;

  const LLMApplcationPage({
    super.key,
    required this.engineProvider,
  });

  @override
  State<LLMApplcationPage> createState() => _LLMApplcationPageState();
}

class _LLMApplcationPageState extends State<LLMApplcationPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final bool _autoScroll = true;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<LLMAIEngineProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LLM Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _openFile,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/llm-settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // System prompt section
          Container(
            padding: const EdgeInsets.all(12),
            color: engine.selectedModel == null
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Expanded(
                  child: SelectableText.rich(
                    TextSpan(
                      children: [
                        // Add system prompt widgets here
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<LLMAIEngineProvider>(
              builder: (context, engine, _) {
                return Container(
                  color: engine.selectedModel == null
                      ? Colors.grey[200]
                      : Colors.grey[100],
                  child: _buildAttachedFilesArea(),
                );
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: Consumer<LLMAIEngineProvider>(
              builder: (context, engine, _) {
                return ChatArea(
                  engine: engine,
                  controller: _textController,
                  autoScroll: _autoScroll,
                  onSend: _onSend,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachedFilesArea() {
    return Consumer<LLMAIEngineProvider>(
            builder: (context, engine, _) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (engine.selectedModel != null)
                      Icon(
                        Icons.chat_bubble,
                        size: 64,
                        color: Colors.grey[400],
                      )
                    else
                      const Text(
                        'Select a model to start',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                  ],
                ),
              );
            },
          );
  }

  void _onSend(String message, Function(Map<String, dynamic>)? onSuccess, Function(String)? onError) {
    final engine = Provider.of<LLMAIEngineProvider>(context, listen: false);

    if (_textController.text.trim().isEmpty) return;

    // Scroll to bottom
    _scrollToBottom();

    // Send request
    engine.makeRequest(
      model: engine.selectedModel?.modelName ?? 'anthropic/claude-3.5-sonnet',
      userMessage: message,
      onSuccess: (response) {
        if (response['success'] == true) {
          // Update chat history with assistant response
          setState(() {});
        } else {
          onError?.call(response['error'] ?? 'Unknown error');
        }
      },
      onError: (error) => onError?.call(error),
    );
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients &&
        _scrollController.offset < _scrollController.position.maxScrollExtent) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _openFile() {
    // TODO: P3-2 Implement file open dialog with path picker and validation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File open feature coming soon')),
    );
  }
}

class ChatArea extends StatefulWidget {
  final LLMAIEngineProvider engine;
  final TextEditingController controller;
  final bool autoScroll;
  final Function(String message, Function(Map<String, dynamic>)? onSuccess, Function(String)? onError) onSend;

  const ChatArea({
    super.key,
    required this.engine,
    required this.controller,
    this.autoScroll = true,
    required this.onSend,
  });

  @override
  State<ChatArea> createState() => _ChatAreaState();
}

class _ChatAreaState extends State<ChatArea> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LLMAIEngineProvider>(
      builder: (context, engine, _) {
        return Column(
          children: [
            // Messages list
            Expanded(
              child: Consumer<LLMAIEngineProvider>(
                builder: (context, engine, _) {
                  return StreamBuilder<List<ChatMessage>>(
                    stream: Stream.value(<ChatMessage>[]),
                    builder: (context, snapshot) {
                      final chatMessages = snapshot.data ?? <ChatMessage>[];
                      return ListView.builder(
                        itemCount: chatMessages.length,
                        itemBuilder: (context, index) {
                          final message = chatMessages[index];
                          return ChatBubble(
                            message: message,
                            isUser: message.type == MessageType.user,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // Input field
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (engine.isLoading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => _onSubmit(),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _onSubmit() {
    if (widget.controller.text.trim().isEmpty) return;

    widget.onSend(
      widget.controller.text,
      (response) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request sent')),
      ),
      (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      ),
    );

    widget.controller.clear();
  }
}

enum MessageType { user, assistant }

class ChatMessage {
  final MessageType? type;
  final String content;
  final Map<String, dynamic>? data;
  final bool isLoading;

  ChatMessage({
    required this.type,
    required this.content,
    this.data,
    this.isLoading = false,
  });
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: isUser ? Radius.circular(16) : Radius.circular(8),
            bottomRight: isUser ? Radius.circular(16) : Radius.circular(8),
          ),
        ),
        child: message.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                message.content,
                style: TextStyle(
                  color: isUser
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}

class ModelSelectorWidget extends StatelessWidget {
  final ValueChanged<String> onModelSelected;

  const ModelSelectorWidget({
    super.key,
    required this.onModelSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LLMAIEngineProvider>(
      builder: (context, engine, _) {
        return PopupMenuButton<String>(
          onSelected: onModelSelected,
          itemBuilder: (context) => availableModels.map(
            (model) => PopupMenuItem<String>(
              value: model.modelName,
              child: Text(model.providerDisplayName),
            ),
          ).toList(),
        );
      },
    );
  }

  static const List<LLMModelConfig> availableModels = AvailableModels.openrouterModels;
}
