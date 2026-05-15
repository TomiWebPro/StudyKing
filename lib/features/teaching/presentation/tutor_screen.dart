import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/mastery_graph_service.dart';
import '../../../core/services/student_id_service.dart';
import '../../../core/widgets/conversation_input.dart';
import 'package:studyking/core/providers/app_providers.dart' show database, settingsProvider;
import 'package:studyking/core/providers/llm_providers.dart' show llmServiceProvider;
import '../../../l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';
import '../services/conversation_manager.dart';
import '../services/tutor_service.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/lesson_progress_bar.dart';

class TutorScreen extends ConsumerStatefulWidget {
  final String topicId;
  final String topicTitle;
  final String subjectId;
  final int durationMinutes;
  final TutorService? tutorService;

  const TutorScreen({
    super.key,
    required this.topicId,
    required this.topicTitle,
    required this.subjectId,
    this.durationMinutes = 45,
    this.tutorService,
  });

  @override
  ConsumerState<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends ConsumerState<TutorScreen> {
  late final TutorService _tutorService;
  late final TextEditingController _textController;
  late final ScrollController _scrollController;
  late final FocusNode _inputFocusNode;
  ConversationManager? _manager;
  bool _isInitialized = false;
  bool _isSending = false;
  bool _isVoiceListening = false;
  Timer? _timer;
  int _elapsedMinutes = 0;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _scrollController = ScrollController();
    _inputFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeTutor();
    });
  }

  void _initializeTutor() {
    if (widget.tutorService != null) {
      _tutorService = widget.tutorService!;
    } else {
      final llmService = ref.read(llmServiceProvider);
      final masteryService = MasteryGraphService();
      final modelId = 'openai/gpt-4o-mini';

      _tutorService = TutorService(
        database: database,
        llmService: llmService,
        masteryService: masteryService,
        modelId: modelId,
      );
    }

    _startLesson();
  }

  Future<void> _startLesson() async {
    final studentId = StudentIdService().getStudentId();
    final l10n = AppLocalizations.of(context)!;
    final manager = await _tutorService.startLesson(
      studentId: studentId,
      subjectId: widget.subjectId,
      topicId: widget.topicId,
      topicTitle: widget.topicTitle,
      durationMinutes: widget.durationMinutes,
      correctKeywords: l10n.correctAnswerKeywords.split(',').map((s) => s.trim()).toList(),
      incorrectKeywords: l10n.incorrectAnswerKeywords.split(',').map((s) => s.trim()).toList(),
      exerciseKeywords: l10n.exerciseKeywords.split(',').map((s) => s.trim()).toList(),
    );

    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _elapsedMinutes++);
    });

    if (mounted) {
      setState(() {
        _manager = manager;
        _isInitialized = true;
      });

      _sendInitialGreeting();
    }
  }

  Future<void> _sendInitialGreeting() async {
    if (_manager == null) return;

    setState(() => _isSending = true);
    final buffer = StringBuffer();

    final l10n = AppLocalizations.of(context)!;
    await for (final chunk in _manager!.sendMessage(
        l10n.readyToLearnAbout(widget.topicTitle))) {
      buffer.write(chunk);
      setState(() {});
      _scrollToBottom();
    }

    if (mounted) setState(() => _isSending = false);
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending || _manager == null) return;

    _textController.clear();
    setState(() => _isSending = true);

    final buffer = StringBuffer();
    await for (final chunk in _manager!.sendMessage(text)) {
      buffer.write(chunk);
      setState(() {});
      _scrollToBottom();
    }

    if (mounted) setState(() => _isSending = false);
    _scrollToBottom();
    _inputFocusNode.requestFocus();
  }

  void _toggleVoiceInput() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.comingSoon)),
    );
    setState(() => _isVoiceListening = !_isVoiceListening);
  }

  Future<void> _pickImage() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.comingSoon)),
    );
  }

  Future<void> _endLesson() async {
    if (_manager == null) return;

    final summary = await _manager!.generateSummary();
    await _tutorService.endLesson();

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(ctx)!.lessonComplete),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(summary),
                const SizedBox(height: 16),
                _buildSummaryStats(ctx),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(ctx)!.done),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSummaryStats(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final manager = _manager!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.sessionDurationMinutes(_elapsedMinutes),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
          Row(
            children: [
              _statChip(context, Icons.quiz_outlined, l10n.questionsCountLabel(manager.exerciseCount)),
              const SizedBox(width: 8),
              _statChip(context, Icons.check_circle_outline, l10n.correctCount(manager.correctCount), color: Colors.green),
              const SizedBox(width: 8),
              _statChip(context, Icons.speed, l10n.paceLabel((manager.adaptivePace * 100).round())),
            ],
          ),
      ],
    );
  }

  Widget _statChip(BuildContext context, IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color ?? Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final remaining = widget.durationMinutes - _elapsedMinutes;
    final isEnding = remaining <= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topicTitle),
        actions: [
          if (_isInitialized)
            TextButton.icon(
              onPressed: _endLesson,
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(l10n.endLesson),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isInitialized && _manager != null)
            LessonProgressBar(
              elapsedMinutes: _elapsedMinutes,
              plannedDurationMinutes: widget.durationMinutes,
              exerciseCount: _manager!.exerciseCount,
              correctCount: _manager!.correctCount,
              topicTitle: widget.topicTitle,
            ),
          Expanded(
            child: _isInitialized && _manager != null
                ? _buildMessageList(l10n, isEnding, ref.watch(settingsProvider).reduceMotion)
                : const Center(child: CircularProgressIndicator()),
          ),
          ConversationInput(
            controller: _textController,
            focusNode: _inputFocusNode,
            isEnabled: _isInitialized,
            isLoading: _isSending,
            hintText: l10n.typeYourMessage,
            sendTooltip: l10n.send,
            onSend: _sendMessage,
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _isVoiceListening ? Icons.mic : Icons.mic_none,
                    color: _isVoiceListening ? Colors.red : null,
                  ),
                  onPressed: _isInitialized && !_isSending ? _toggleVoiceInput : null,
                  tooltip: l10n.voiceInput,
                ),
                IconButton(
                  icon: const Icon(Icons.image_outlined),
                  onPressed: _isInitialized && !_isSending ? _pickImage : null,
                  tooltip: l10n.captureImage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(AppLocalizations l10n, bool isEnding, bool reduceMotion) {
    final messages = _manager!.messages;
    if (messages.isEmpty) {
      return Center(
        child: Text(l10n.startingLesson),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: ResponsiveUtils.listPadding(context),
      itemCount: messages.length + (isEnding ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                l10n.lessonTimeEnded,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          );
        }
        return ChatBubble(message: messages[index], reduceMotion: reduceMotion);
      },
    );
  }
}
