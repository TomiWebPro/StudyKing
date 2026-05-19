import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider;
import 'package:studyking/core/providers/llm_agent_providers.dart' show llmAgentProvider;
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/services/voice_service.dart';
import 'package:studyking/core/widgets/conversation_input.dart';
import 'package:studyking/core/widgets/loading_indicator.dart';
import 'package:studyking/core/services/prerequisite_check_service.dart';
import 'package:studyking/features/teaching/providers/teaching_providers.dart' show tutorServiceProvider;
import '../../../l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';
import '../services/conversation_manager.dart';
import '../services/conversation_phase.dart';
import '../services/tutor_service.dart';
import '../data/models/lesson_plan_model.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/lesson_progress_bar.dart';
import 'widgets/voice_bar.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/lessons/presentation/widgets/lesson_block_card.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/focus_mode/presentation/focus_timer_screen.dart';

class TutorScreen extends ConsumerStatefulWidget {
  final String topicId;
  final String topicTitle;
  final String subjectId;
  final int durationMinutes;
  final TutorService? tutorService;
  final String? scheduledSessionId;

  const TutorScreen({
    super.key,
    required this.topicId,
    required this.topicTitle,
    required this.subjectId,
    this.durationMinutes = 45,
    this.tutorService,
    this.scheduledSessionId,
  });

  @override
  ConsumerState<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends ConsumerState<TutorScreen> with AutomaticKeepAliveClientMixin {
  late final TutorService _tutorService;
  late final TextEditingController _textController;
  late final ScrollController _scrollController;
  late final FocusNode _inputFocusNode;
  ConversationManager? _manager;
  bool _isInitialized = false;
  bool _showSlides = false;
  int _currentSlideIndex = 0;
  late final PageController _pageController;
  bool _isSending = false;
  bool _initError = false;
  String _initErrorMessage = '';
  Timer? _timer;
  int _elapsedMinutes = 0;
  LessonPlan? _lessonPlan;
  bool _voiceOutputEnabled = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _scrollController = ScrollController();
    _inputFocusNode = FocusNode();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeTutor();
    });
  }

  Future<void> _initializeTutor() async {
    if (widget.tutorService != null) {
      _tutorService = widget.tutorService!;
    } else {
      _tutorService = ref.read(tutorServiceProvider);
    }

    final studentId = StudentIdService().getStudentId();
    final agent = ref.read(llmAgentProvider(studentId));
    _tutorService.llmAgent = agent;

    if (widget.topicId.isNotEmpty) {
      final prereqCheck = PrerequisiteCheckService();
      final prereqResult = await prereqCheck.checkPrerequisites(
        topicId: widget.topicId,
        studentId: StudentIdService().getStudentId(),
      );
      if (prereqResult.isSuccess &&
          !prereqResult.data!.isReady &&
          prereqResult.data!.unmetPrerequisiteTopics.isNotEmpty &&
          mounted) {
        final shouldContinue = await PrerequisiteCheckService.showPrerequisiteDialog(
          context,
          unmetTopics: prereqResult.data!.unmetPrerequisiteTopics,
        );
        if (!shouldContinue) {
          if (!mounted) return;
          Navigator.pop(context);
          return;
        }
      }
    }

    _startLesson();
  }

  Future<void> _startLesson() async {
    try {
      final studentId = ref.read(studentIdValueProvider);
      final l10n = AppLocalizations.of(context)!;
      final manager = await _tutorService.startLesson(
        studentId: studentId,
        subjectId: widget.subjectId,
        topicId: widget.topicId,
        topicTitle: widget.topicTitle,
        durationMinutes: widget.durationMinutes,
        scheduledSessionId: widget.scheduledSessionId,
        localeName: l10n.localeName,
      );

      _lessonPlan = manager.lessonPlan;

      _timer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsedMinutes++);
        if (_elapsedMinutes >= widget.durationMinutes && _manager != null) {
          _manager!.transitionToClosing();
        }
      });

      if (mounted) {
        setState(() {
          _manager = manager;
          _manager!.enableVoiceOutput = _voiceOutputEnabled;
          _isInitialized = true;
          _initError = false;
        });

        _sendInitialGreeting();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _initError = true;
          _initErrorMessage = l10n.tutorInitFailed('');
        });
      }
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

  Future<void> _pickImage() async {
    if (_manager == null || _isSending) return;

    final l10n = AppLocalizations.of(context)!;
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.captureImage),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            child: ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.camera),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            child: ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.gallery),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );

    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (pickedFile == null || !mounted) return;

    setState(() => _isSending = true);

    final bytes = await pickedFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    await for (final _ in _manager!.processImage(base64Image)) {
      setState(() {});
      _scrollToBottom();
    }

    if (mounted) setState(() => _isSending = false);
    _scrollToBottom();
  }

  void _onTranscriptionSubmitted(String text) {
    _textController.text = text;
    _sendMessage();
  }

  void _clearConversation() {
    if (_manager == null) return;
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearConversation),
        content: Text(l10n.clearConversation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _manager!.clearMessages();
              setState(() {});
            },
            child: Text(l10n.clearConversation),
          ),
        ],
      ),
    );
  }

  void _showEndLessonConfirmation() {
    if (_manager == null) return;
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.endLesson),
        content: Text(l10n.endLessonConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.continueLesson),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _endLesson();
            },
            child: Text(l10n.endLesson),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBackNavigation() async {
    if (_manager == null) {
      Navigator.of(context).pop();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.endLesson),
        content: Text(l10n.backNavigationConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: Text(l10n.continueLesson),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: Text(l10n.discardAndExit),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: Text(l10n.saveAndExit),
          ),
        ],
      ),
    );
    if (result == 'cancel' || result == null) return;
    if (result == 'discard') {
      _manager = null;
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (result == 'save') {
      await _endLessonInternal();
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _endLesson() async {
    await _endLessonInternal();
    if (!mounted) return;
    _showSummaryDialog();
  }

  Future<String> _endLessonInternal() async {
    if (_manager == null) return '';
    final summary = await _manager!.generateSummary();
    await _tutorService.endLesson();
    _timer?.cancel();
    return summary;
  }

  Future<void> _startFocusModePractice() async {
    if (!mounted) return;
    Navigator.of(context).pop();
    await Navigator.pushNamed(
      context,
      AppRoutes.focusMode,
      arguments: FocusTimerScreen(
        preselectedSubjectId: widget.subjectId,
        preselectedTopicId: widget.topicId,
        defaultDurationMinutes: 15,
      ),
    );
  }

  Future<void> _startPostLessonPractice({int questionCount = 5}) async {
    if (!mounted) return;
    Navigator.of(context).pop();
    await Navigator.pushNamed(
      context,
      AppRoutes.practiceSession,
      arguments: PracticeSessionArgs(
        subjectId: widget.subjectId,
        topicId: widget.topicId,
        questionCount: questionCount,
      ),
    );
  }

  void _showSummaryDialog() {
    final l10n = AppLocalizations.of(context)!;
    final manager = _manager;
    if (manager == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.lessonComplete),
        content: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.lessonSavedMessage),
              const SizedBox(height: 16),
              _buildSummaryStats(ctx),
              const SizedBox(height: 16),
              const Divider(),
              Text(l10n.practiceAgain,
                style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _startFocusModePractice();
                  },
                  icon: const Icon(Icons.timer, size: 18),
                  label: Text('${l10n.quickPractice} (Focus)'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _startPostLessonPractice(questionCount: 20);
                  },
                  icon: const Icon(Icons.playlist_add_check, size: 18),
                  label: Text(l10n.practiceMode),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Future.delayed(const Duration(milliseconds: 200), () {
                if (mounted) Navigator.of(context).pop();
              });
            },
            child: Text(l10n.done),
          ),
        ],
      ),
    );
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
              _statChip(context, Icons.check_circle_outline, l10n.correctCount(manager.correctCount), color: Theme.of(context).colorScheme.primary),
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
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final reduceMotion = ref.read(settingsProvider).reduceMotion;
        if (reduceMotion) {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Timeouts.ms100,
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final remaining = widget.durationMinutes - _elapsedMinutes;
    final isEnding = remaining <= 0;
    final voiceController = ref.watch(voiceServiceProvider);

    return PopScope(
      canPop: !_isInitialized,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.topicTitle),
          actions: [
            if (_isInitialized && _manager != null) ...[
              if (_tutorService.currentLessonBlocks != null && _tutorService.currentLessonBlocks!.isNotEmpty)
                IconButton(
                  icon: Icon(_showSlides ? Icons.chat_bubble_outline : Icons.slideshow),
                  tooltip: _showSlides ? l10n.chat : l10n.slides,
                  onPressed: () => setState(() => _showSlides = !_showSlides),
                ),
              if (_isInitialized && _manager != null)
                IconButton(
                  icon: Icon(_voiceOutputEnabled ? Icons.volume_up : Icons.volume_off),
                  tooltip: l10n.voiceInput,
                  onPressed: () {
                    setState(() {
                      _voiceOutputEnabled = !_voiceOutputEnabled;
                      _manager!.enableVoiceOutput = _voiceOutputEnabled;
                    });
                  },
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: l10n.moreOptions,
                onSelected: (value) {
                  if (value == 'clear') {
                    _clearConversation();
                  } else if (value == 'end') {
                    _showEndLessonConfirmation();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'end',
                    child: ListTile(
                      leading: const Icon(Icons.stop_circle_outlined),
                      title: Text(l10n.endLesson),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear',
                    child: ListTile(
                      leading: const Icon(Icons.refresh),
                      title: Text(l10n.clearConversation),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        body: Column(
          children: [
            if (_isInitialized && _manager != null)
              Column(
                children: [
                  LessonProgressBar(
                    elapsedMinutes: _elapsedMinutes,
                    plannedDurationMinutes: widget.durationMinutes,
                    exerciseCount: _manager!.exerciseCount,
                    correctCount: _manager!.correctCount,
                    topicTitle: widget.topicTitle,
                    lessonPlan: _lessonPlan,
                  ),
                  _buildPhaseIndicator(),
                ],
              ),
            if (_initError)
              _buildInitErrorCard(l10n)
            else
              Expanded(
                child: _isInitialized && _manager != null
                    ? (_showSlides && _tutorService.currentLessonBlocks != null && _tutorService.currentLessonBlocks!.isNotEmpty
                        ? _buildSlidesView()
                        : _buildMessageList(l10n, isEnding, ref.watch(settingsProvider).reduceMotion))
                    : _buildInitLoading(l10n),
              ),
            if (isEnding && _isInitialized && _manager != null)
              _buildTimeEndedBanner(l10n),
            if (!_showSlides)
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
                    VoiceBar(
                      controller: voiceController,
                      onTranscriptionSubmitted: _onTranscriptionSubmitted,
                      isEnabled: _isInitialized && !_isSending,
                      reduceMotion: ref.watch(settingsProvider).reduceMotion,
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
      ),
    );
  }

  Widget _buildInitLoading(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LoadingIndicator(),
          const SizedBox(height: 24),
          Text(
            l10n.startingLesson,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.loading}...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            label: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator() {
    if (_manager == null) return const SizedBox.shrink();
    final phase = _manager!.phase;
    final theme = Theme.of(context);
    IconData icon;
    Color color;
    switch (phase) {
      case ConversationPhase.greeting:
        icon = Icons.waving_hand_outlined;
        color = theme.colorScheme.tertiary;
        break;
      case ConversationPhase.teaching:
        icon = Icons.school_outlined;
        color = theme.colorScheme.primary;
        break;
      case ConversationPhase.exercise:
        icon = Icons.quiz_outlined;
        color = theme.colorScheme.secondary;
        break;
      case ConversationPhase.feedback:
        icon = Icons.feedback_outlined;
        color = theme.colorScheme.tertiary;
        break;
      case ConversationPhase.adaptiveReview:
        icon = Icons.psychology_outlined;
        color = theme.colorScheme.secondary;
        break;
      case ConversationPhase.closing:
        icon = Icons.summarize_outlined;
        color = theme.colorScheme.onSurfaceVariant;
        break;
    }
    final l10n = AppLocalizations.of(context)!;
    final phaseLabel = switch (phase) {
      ConversationPhase.greeting => l10n.phaseGreeting,
      ConversationPhase.teaching => l10n.phaseTeaching,
      ConversationPhase.exercise => l10n.phaseExercise,
      ConversationPhase.feedback => l10n.phaseFeedback,
      ConversationPhase.adaptiveReview => l10n.phaseAdaptiveReview,
      ConversationPhase.closing => l10n.phaseClosing,
    };
    return Semantics(
      label: phaseLabel,
      header: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              phaseLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitErrorCard(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: ResponsiveUtils.screenPadding(context),
        child: Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _initErrorMessage,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.apiConfig),
                      icon: const Icon(Icons.settings),
                      label: Text(l10n.goToSettings),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _initError = false;
                          _initErrorMessage = '';
                        });
                        _initializeTutor();
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeEndedBanner(AppLocalizations l10n) {
    return Semantics(
      label: l10n.lessonTimeEnded,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Row(
          children: [
            Icon(Icons.access_alarm, size: 18, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.lessonTimeEnded,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
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
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isTutor = msg.role == MessageRole.tutor;
        final child = ChatBubble(
          message: msg,
          reduceMotion: reduceMotion,
          onSpeak: isTutor && _voiceOutputEnabled && !msg.isStreaming && msg.content.isNotEmpty
              ? () => ref.read(voiceServiceProvider).speak(msg.content, localeName: l10n.localeName)
              : null,
        );
        if (reduceMotion) return child;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, child) => Opacity(opacity: value, child: child),
          child: child,
        );
      },
    );
  }

  List<LessonBlock> get _lessonBlocks => _tutorService.currentLessonBlocks ?? [];

  Widget _buildSlidesView() {
    final blocks = _lessonBlocks;
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentSlideIndex = i),
            itemCount: blocks.length,
            itemBuilder: (context, index) {
              return SingleChildScrollView(
                padding: ResponsiveUtils.screenPadding(context),
                physics: const AlwaysScrollableScrollPhysics(),
                child: LessonBlockCard(block: blocks[index]),
              );
            },
          ),
        ),
        _buildSlideNavigation(blocks.length),
      ],
    );
  }

  Widget _buildSlideNavigation(int total) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: l10n.previous,
            onPressed: _currentSlideIndex > 0
                ? () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                : null,
          ),
          Text('${_currentSlideIndex + 1} / $total'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: l10n.next,
            onPressed: _currentSlideIndex < total - 1
                ? () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                : null,
          ),
        ],
      ),
    );
  }
}
