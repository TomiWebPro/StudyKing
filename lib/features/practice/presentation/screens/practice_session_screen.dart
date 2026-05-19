import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/errors/handlers.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/services/answer_validation_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/services/voice_service.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider;
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/features/practice/services/practice_session_service.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider;
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/practice/data/models/practice_models.dart';
import 'package:studyking/features/practice/services/difficulty_controller.dart';
import 'package:studyking/features/practice/services/mastery_recorder.dart';
import 'package:studyking/features/practice/services/mistake_review_service.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/practice/presentation/screens/practice_results_screen.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_feedback_widget.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_session_stats_bar.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_session_question_card.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_session_nav_buttons.dart';
import 'package:studyking/features/practice/presentation/widgets/mistake_review_widget.dart';
import 'package:studyking/features/practice/services/question_type_localizer.dart';
import 'package:studyking/core/widgets/loading_indicator.dart';

class PracticeSessionScreen extends ConsumerStatefulWidget {
  final PracticeSessionArgs args;

  const PracticeSessionScreen({
    super.key,
    required this.args,
  });

  @override
  ConsumerState<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends ConsumerState<PracticeSessionScreen> {
  late QuestionRepository _questionRepo;
  late SpacedRepetitionService _srService;
  late PracticeSessionService _sessionService;
  late AnswerValidationService _validationService;
  late final StudentIdService _studentIdService;
  late final MasteryRecorder _masteryRecorder;
  late final MistakeReviewService _mistakeReviewService;
  late final DifficultyController _difficultyAdapter;
  List<Question> _questions = [];
  int _currentIndex = 0;
  int _previousIndex = 0;
  String? _currentAnswer;
  bool _isSubmitted = false;
  bool _isFeedbackVisible = false;
  bool _isSessionComplete = false;
  bool _sessionAutoSaved = false;
  int _correctAnswers = 0;
  String? _elapsedTimeFormatted;
  final List<PracticeAnswerRecord> _answerRecords = [];
  final List<String> _mistakeQuestionIds = [];
  bool _isCorrect = false;
  int _currentConfidence = 3;
  DateTime? _questionStartTime;

  @override
  void initState() {
    super.initState();
    _questionRepo = ref.read(questionRepositoryProvider);
    _srService = ref.read(spacedRepetitionServiceProvider);
    _studentIdService = ref.read(studentIdServiceProvider);
    _masteryRecorder = ref.read(masteryRecorderProvider);
    _mistakeReviewService = ref.read(mistakeReviewServiceProvider);
    _difficultyAdapter = DifficultyController();
    final sessionRepo = ref.read(sessionRepositoryProvider);
    _sessionService = PracticeSessionService(
      sessionRepo: sessionRepo,
      srService: _srService,
      studentIdService: _studentIdService,
      subjectId: widget.args.subjectId,
    );
    _loadQuestions();
    _sessionService.startTimer();
    _sessionService.elapsedNotifier.addListener(_onElapsedChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _validationService = AnswerValidationService(
      messages: ValidationMessages.fromLocalizations(AppLocalizations.of(context)!),
    );
  }

  void _onElapsedChanged() {
    if (!mounted) return;
    setState(() {
      _elapsedTimeFormatted = formatDurationFromContext(context, _sessionService.elapsedNotifier.value);
    });
  }

  Future<void> _loadQuestions() async {
    try {
      if (widget.args.orderedQuestionIds != null &&
          widget.args.orderedQuestionIds!.isNotEmpty) {
        await _loadOrderedQuestions();
        return;
      }

      if (widget.args.isSpacedRepetition) {
        await _loadSrDueQuestions();
        return;
      }

      final result = await _questionRepo.getBySubject(widget.args.subjectId);
      if (result.isFailure || result.data == null) {
        if (mounted) setState(() => _questions = []);
        _showNoQuestionsDialog();
        return;
      }
      var filteredQuestions = result.data!;
      if (widget.args.topicId != null && widget.args.topicId!.isNotEmpty) {
        filteredQuestions = filteredQuestions.where((q) => q.topicId == widget.args.topicId).toList();
      }
      if (filteredQuestions.isEmpty) {
        if (mounted) setState(() => _questions = []);
        _showNoQuestionsDialog();
        return;
      }
      final shuffled = List<Question>.from(filteredQuestions)..shuffle();
      final count = (widget.args.questionCount ?? shuffled.length).clamp(1, shuffled.length);
      if (mounted) {
        setState(() => _questions = shuffled.take(count).toList());
        _initializeSession();
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(context, e, 'Questions Load', retry: true, retryCallback: _retryLoadQuestions);
      }
    }
  }

  Future<void> _loadOrderedQuestions() async {
    try {
      final result = await _questionRepo.getBySubject(widget.args.subjectId);
      if (result.isFailure || result.data == null) {
        if (mounted) setState(() => _questions = []);
        _showNoQuestionsDialog();
        return;
      }
      final questionMap = {for (final q in result.data!) q.id: q};
      final ordered = widget.args.orderedQuestionIds!
          .map((id) => questionMap[id])
          .whereType<Question>()
          .toList();
      if (ordered.isEmpty) {
        if (mounted) setState(() => _questions = []);
        _showNoQuestionsDialog();
        return;
      }
      final count = (widget.args.questionCount ?? ordered.length).clamp(1, ordered.length);
      if (mounted) {
        setState(() => _questions = ordered.take(count).toList());
        _initializeSession();
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(context, e, 'Questions Load', retry: true, retryCallback: _retryLoadQuestions);
      }
    }
  }

  Future<void> _loadSrDueQuestions() async {
    try {
      final result = await _srService.getPracticeQuestions(widget.args.subjectId);
      if (result.isFailure || result.data == null || result.data!.isEmpty) {
        if (mounted) setState(() => _questions = []);
        _showNoQuestionsDialog();
        return;
      }
      var dueQuestions = result.data!;
      dueQuestions.sort((a, b) => (a.nextReview ?? DateTime.now())
          .compareTo(b.nextReview ?? DateTime.now()));
      final count = (widget.args.questionCount ?? dueQuestions.length).clamp(1, dueQuestions.length);
      if (mounted) {
        setState(() => _questions = dueQuestions.take(count).toList());
        _initializeSession();
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(context, e, 'Questions Load', retry: true, retryCallback: _retryLoadQuestions);
      }
    }
  }

  Future<void> _retryLoadQuestions() => _loadQuestions();

  void _initializeSession() {
    if (_questions.isEmpty) {
      _showNoQuestionsDialog();
      return;
    }
    _currentAnswer = null;
    _isSubmitted = false;
    _isFeedbackVisible = false;
    _currentConfidence = 3;
    _questionStartTime = DateTime.now();
    if (mounted) setState(() {});
  }

  void _showNoQuestionsDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        semanticLabel: l10n.noQuestionsAvailable,
        title: Text(l10n.noQuestionsAvailable),
        content: Text(l10n.noQuestionsForSelectedSubject),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.upload,
                  arguments: widget.args.subjectId);
            },
            child: Text(l10n.uploadMaterials),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) Navigator.of(context).pop();
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  void _onAnswerSelected(String? answer) {
    setState(() => _currentAnswer = answer);
  }

  bool _validateAnswer(Question question, String answer) {
    if (question.markscheme == null || question.markscheme!.correctAnswer.isEmpty) {
      setState(() => _isCorrect = false);
      return false;
    }
    final result = _validationService.validateAnswerForQuestion(question, answer);
    setState(() => _isCorrect = result.isCorrect);
    return result.isCorrect;
  }

  Future<void> _submitAnswer() async {
    if (_currentAnswer == null || _questions.isEmpty) return;
    final question = _questions[_currentIndex];
    final isCorrect = _validateAnswer(question, _currentAnswer!);
    if (isCorrect) _correctAnswers++;
    final timeSpentMs = _questionStartTime != null
        ? DateTime.now().difference(_questionStartTime!).inMilliseconds
        : 0;
    _answerRecords.add(PracticeAnswerRecord(
      questionId: question.id,
      questionType: question.type,
      isCorrect: isCorrect,
      timeSpent: Duration(milliseconds: timeSpentMs),
      userAnswer: _currentAnswer!,
    ));
    if (!isCorrect) {
      _mistakeQuestionIds.add(question.id);
    }

    await _masteryRecorder.recordAttempt(
      studentId: _studentIdService.getStudentId(),
      questionId: question.id,
      subjectId: question.subjectId,
      topicId: question.topicId,
      isCorrect: isCorrect,
      timeSpentMs: timeSpentMs,
      confidence: _currentConfidence,
      userAnswer: _currentAnswer!,
    );

    _difficultyAdapter.recordResult(isCorrect);
    _difficultyAdapter.suggestNextDifficulty();

    if (widget.args.isSpacedRepetition) {
      _updateNextReview(question.id, isCorrect);
    }
    setState(() {
      _isSubmitted = true;
      _isFeedbackVisible = true;
    });
  }

  Future<void> _updateNextReview(String questionId, bool isCorrect) async {
    await _sessionService.updateNextReview(questionId, isCorrect);
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex++;
        _currentAnswer = null;
        _isSubmitted = false;
        _isFeedbackVisible = false;
        _currentConfidence = 3;
        _questionStartTime = DateTime.now();
      });
    } else {
      _completeSession();
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex--;
      });
    }
  }

  Future<void> _completeSession() async {
    if (_mistakeQuestionIds.isNotEmpty) {
      // Save session data before showing the review
      if (!_sessionAutoSaved) {
        _sessionAutoSaved = true;
        await _sessionService.autoSaveSession(
          questionsAnswered: _questions.length,
          correctAnswers: _correctAnswers,
        );
      }
      await _recordAdherence();

      final shouldFinalize = await _showMistakeReview();
      if (!shouldFinalize) return;
      if (!mounted) return;
      final breakdown = _computeTopicBreakdown();
      Navigator.pop(context, PracticeSessionResult(
        questionsAnswered: _questions.length,
        correctAnswers: _correctAnswers,
        topicBreakdown: breakdown,
      ));
    } else {
      await _finalizeSession();
      if (!mounted) return;
      _navigateToResults();
    }
  }

  Future<bool> _showMistakeReview() async {
    final mistakes = await _mistakeReviewService.getMistakesFromSession(
      studentId: _studentIdService.getStudentId(),
      subjectId: widget.args.subjectId,
      after: _sessionService.sessionStartTime,
    );
    if (!mounted || mistakes.isEmpty) return true;
    final completer = Completer<bool>();
    MistakeReviewWidget.show(
      context,
      mistakes: mistakes,
      onRedo: () {
        Navigator.pop(context);
        _startMistakeRedo(mistakes);
        completer.complete(false);
      },
      onDismiss: () {
        Navigator.pop(context);
        completer.complete(true);
      },
    );
    return completer.future;
  }

  void _startMistakeRedo(List<MistakeEntry> mistakes) {
    final redoQuestions = mistakes.map((m) => m.question).toList();
    setState(() {
      _questions = redoQuestions..shuffle();
      _currentIndex = 0;
      _correctAnswers = 0;
      _mistakeQuestionIds.clear();
      _answerRecords.clear();
      _isSessionComplete = false;
      _sessionAutoSaved = false;
      _currentAnswer = null;
      _isSubmitted = false;
      _isFeedbackVisible = false;
    });
    _sessionService.startTimer();
  }

  Map<String, double> _computeTopicBreakdown() {
    final topicMap = <String, List<bool>>{};
    for (final record in _answerRecords) {
      final question = _questions.where((q) => q.id == record.questionId).firstOrNull;
      if (question == null) continue;
      final topicKey = question.topic ?? question.topicId;
      topicMap.putIfAbsent(topicKey, () => []);
      topicMap[topicKey]!.add(record.isCorrect);
    }
    final breakdown = <String, double>{};
    for (final entry in topicMap.entries) {
      final correct = entry.value.where((v) => v).length;
      breakdown[entry.key] = entry.value.isEmpty
          ? 0.0
          : correct / entry.value.length;
    }
    return breakdown;
  }

  List<QuestionReviewData> _buildReviewData() {
    return _questions.map((q) {
      final record = _answerRecords.where((r) => r.questionId == q.id).firstOrNull;
      return QuestionReviewData(
        question: q,
        userAnswer: record?.userAnswer,
        correctAnswer: q.markscheme?.correctAnswer,
        isCorrect: record?.isCorrect ?? false,
      );
    }).toList();
  }

  void _navigateToResults() {
    final breakdown = _computeTopicBreakdown();
    Future.delayed(Timeouts.ms500, () {
      if (mounted) {
        Navigator.pop(context, PracticeSessionResult(
          questionsAnswered: _questions.length,
          correctAnswers: _correctAnswers,
          topicBreakdown: breakdown,
        ));
      }
    });
  }

  Future<void> _recordAdherence() async {
    final elapsedMinutes = DateTime.now()
        .difference(_sessionService.sessionStartTime)
        .inMinutes;
    final planOrchestrator = PlanAdherenceOrchestrator();
    await planOrchestrator.recordActivity(
      studentId: _studentIdService.getStudentId(),
      actualQuestions: _questions.length,
      actualMinutes: elapsedMinutes.clamp(1, 480),
    );
  }

  Future<void> _finalizeSession() async {
    if (_isSessionComplete) return;
    _sessionService.cancelTimer();
    if (!_sessionAutoSaved) {
      _sessionAutoSaved = true;
      await _sessionService.autoSaveSession(
        questionsAnswered: _questions.length,
        correctAnswers: _correctAnswers,
      );
    }
    _recordAdherence();
    if (mounted) {
      setState(() => _isSessionComplete = true);
    }
  }

  Future<bool> _onWillPop() async {
    if (_isSessionComplete) return true;
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmExitPractice),
        content: Text(l10n.confirmExitPracticeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.stay),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.exit),
          ),
        ],
      ),
    );
    if (result == true) {
      await _finalizeSession();
      return false;
    }
    return false;
  }

  void _restartSession() {
    setState(() {
      _currentIndex = 0;
      _correctAnswers = 0;
      _answerRecords.clear();
      _mistakeQuestionIds.clear();
      _isSessionComplete = false;
      _currentAnswer = null;
      _isSubmitted = false;
      _isFeedbackVisible = false;
      _sessionAutoSaved = false;
    });
    _loadQuestions();
    _sessionService.startTimer();
  }

  void _useVoiceInput() {
    final voiceService = ref.read(voiceServiceProvider);
    if (!voiceService.isAvailable) return;
    final l10n = AppLocalizations.of(context)!;
    voiceService.startListening(localeName: l10n.localeName);
    voiceService.transcribedText.listen((text) {
      _onAnswerSelected(text);
    });
  }

  @override
  void dispose() {
    _sessionService.elapsedNotifier.removeListener(_onElapsedChanged);
    _sessionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty && !_isSessionComplete) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.args.isSpacedRepetition
              ? AppLocalizations.of(context)!.spacedRepetitionMode
              : AppLocalizations.of(context)!.practice),
        ),
        body: const LoadingIndicator(),
      );
    }

    if (_isSessionComplete) {
      return PracticeResultsScreen(
        totalQuestions: _questions.length,
        correctAnswers: _correctAnswers,
        onPracticeAgain: _restartSession,
        topicBreakdown: _computeTopicBreakdown(),
        reviewQuestions: _buildReviewData(),
      );
    }

    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(widget.args.isSpacedRepetition
            ? l10n.practiceModeType(l10n.spacedRepetitionMode, question.type.localizedLabel(l10n))
            : l10n.practiceModeType(l10n.practice, question.type.localizedLabel(l10n))),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Semantics(
            liveRegion: true,
            label: l10n.sessionProgressLabel(_currentIndex + 1, _questions.length),
            child: LinearProgressIndicator(value: progress),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: PracticeSessionStatsBar(
                elapsedTime: _elapsedTimeFormatted ?? formatDurationFromContext(context, Duration.zero),
                correctAnswers: _correctAnswers,
                currentIndex: _currentIndex,
              ),
            ),
            Expanded(
              child: FocusTraversalGroup(
                child: Padding(
                  padding: ResponsiveUtils.screenPadding(context),
                  child: ListView(
                    children: [
                      Consumer(
                        builder: (context, ref, _) {
                          final reduceMotion = ref.watch(settingsProvider).reduceMotion;
                          final child = Column(
                            key: ValueKey('question_$_currentIndex'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(2),
                                child: PracticeSessionQuestionCard(
                                  question: question,
                                  currentAnswer: _currentAnswer,
                                  isSubmitted: _isSubmitted,
                                  isFeedbackVisible: _isFeedbackVisible,
                                  onAnswerSelected: _onAnswerSelected,
                                ),
                              ),
                              SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
                              if (!_isSubmitted)
                                FocusTraversalOrder(
                                  order: const NumericFocusOrder(3),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Semantics(
                                          label: l10n.submitAnswer,
                                          child: FilledButton(
                                            onPressed: _currentAnswer != null ? _submitAnswer : null,
                                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                                            child: Text(l10n.submitAnswer),
                                          ),
                                        ),
                                      ),
                                      Consumer(
                                        builder: (_, ref, __) {
                                          final vs = ref.watch(voiceServiceProvider);
                                          if (!vs.isAvailable) return const SizedBox.shrink();
                                          return IconButton(
                                            icon: Icon(
                                              vs.isListening ? Icons.mic : Icons.mic_none,
                                              color: vs.isListening ? Theme.of(context).colorScheme.error : null,
                                            ),
                                            tooltip: l10n.voiceInput,
                                            onPressed: _useVoiceInput,
                                          );
                                        },
                                      ),
                                      if (_currentAnswer == null) ...[
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Semantics(
                                            label: l10n.skip,
                                            child: OutlinedButton(
                                              onPressed: () => _nextQuestion(),
                                              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                                              child: Text(l10n.skip),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              if (_isSubmitted)
                                Column(
                                  children: [
                                    PracticeFeedbackWidget(
                                      isCorrect: _isCorrect,
                                      explanation: question.explanation,
                                    ),
                                    SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
                                    _buildConfidenceSelector(),
                                    SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
                                    PracticeSessionNavButtons(
                                      onPrevious: _previousQuestion,
                                      onNext: _nextQuestion,
                                    ),
                                  ],
                                ),
                            ],
                          );
                          if (reduceMotion) return child;
                          return Semantics(
                            liveRegion: true,
                            child: AnimatedSwitcher(
              duration: Timeouts.ms100,
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
                              transitionBuilder: (child, animation) {
                                final isForward = _currentIndex > _previousIndex;
                                final offset = isForward ? const Offset(0.15, 0.0) : const Offset(-0.15, 0.0);
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: offset,
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: FadeTransition(opacity: animation, child: child),
                                );
                              },
                              child: child,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildConfidenceSelector() {
    final l10n = AppLocalizations.of(context)!;
    final currentLabel = _getConfidenceLabel(l10n, _currentConfidence);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.howConfident,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveUtils.verticalSpacing(context) / 2),
        Semantics(
          label: '${l10n.howConfident}: $_currentConfidence ${l10n.confidenceRatingOf} 5, $currentLabel',
          child: Wrap(
            spacing: ResponsiveUtils.horizontalSpacing(context),
            runSpacing: ResponsiveUtils.verticalSpacing(context) / 2,
            alignment: WrapAlignment.center,
            children: List.generate(5, (index) {
              final rating = index + 1;
              final isSelected = _currentConfidence == rating;
              return Semantics(
                button: true,
                selected: isSelected,
                  child: InkWell(
                  onTap: () => setState(() => _currentConfidence = rating),
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: (MediaQuery.sizeOf(context).width / 6).clamp(32.0, ResponsiveUtils.minTouchTarget),
                    height: (MediaQuery.sizeOf(context).width / 6).clamp(32.0, ResponsiveUtils.minTouchTarget),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getConfidenceColor(rating).withValues(alpha: 0.2)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? _getConfidenceColor(rating)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$rating',
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? _getConfidenceColor(rating)
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        SizedBox(height: ResponsiveUtils.verticalSpacing(context) / 2),
        Center(
          child: Text(
            currentLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor(int rating) {
    final cs = Theme.of(context).colorScheme;
    switch (rating) {
      case 1:
        return cs.error;
      case 2:
        return cs.tertiary;
      case 3:
        return cs.tertiary;
      case 4:
        return cs.primary;
      case 5:
        return cs.primary;
      default:
        return cs.onSurfaceVariant;
    }
  }

  String _getConfidenceLabel(AppLocalizations l10n, int rating) {
    switch (rating) {
      case 1:
        return l10n.notConfidentAtAll;
      case 2:
        return l10n.slightlyConfident;
      case 3:
        return l10n.moderatelyConfident;
      case 4:
        return l10n.quiteConfident;
      case 5:
        return l10n.veryConfident;
      default:
        return '';
    }
  }
}
