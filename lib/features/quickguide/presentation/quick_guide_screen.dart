import 'package:flutter/material.dart';
import 'dart:async';

class QuickGuideScreen extends StatefulWidget {
  const QuickGuideScreen({super.key});

  @override
  State<QuickGuideScreen> createState() => _QuickGuideScreenState();
}

class _QuickGuideScreenState extends State<QuickGuideScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      isUser: false,
      text: 'Hello! I\'m StudyKing\'s Quick Guide. Ask me anything about your studies!',
    ),
  ];
  bool _isTyping = false;

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: text));
      _isTyping = true;
    });

    _textController.clear();
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 1000));

    String response;
    if (text.toLowerCase().contains('explain')) {
      response = 'Sure! I can help explain concepts. What topic would you like me to explain?';
    } else if (text.toLowerCase().contains('question')) {
      response = 'I can help with questions! Ask away and I\'ll do my best.';
    } else {
      response = 'That\'s an interesting question! Let me help you understand it better.';
    }

    setState(() {
      _messages.add(_ChatMessage(isUser: false, text: response));
      _isTyping = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Guide')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('StudyKing is thinking...'),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Ask anything...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final bool isUser;
  final String text;
  _ChatMessage({required this.isUser, required this.text});
}
