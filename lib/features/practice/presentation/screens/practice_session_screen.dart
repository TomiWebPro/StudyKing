import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/errors/handlers.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/services/answer_validation_service.dart';
import 'package:studyking/core/providers/service_providers.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider, sourceRepositoryProvider;
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/features/practice/services/practice_session_service.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider;
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/practice/presentation/widgets/confidence_selector.dart';
import 'package:studyking/features/practice/data/models/practice_models.dart';
import 'package:studyking/core/utils/difficulty_controller.dart';
import 'package:studyking/features/practice/services/mastery_recorder.dart';
import 'package:studyking/features/practice/services/mistake_review_service.dart';
import 'package:studyking/core/utils/id_generator.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/utils/label_helpers.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/practice/presentation/screens/practice_results_screen.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_feedback_widget.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_session_stats_bar.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_session_question_card.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_session_nav_buttons.dart';
import 'package:studyking/features/practice/presentation/widgets/mistake_review_widget.dart';
import 'package:studyking/features/practice/services/question_type_localizer.dart';
import 'package:studyking/core/widgets/loading_indicator.dart';
import 'package:studyking/core/utils/logger.dart';

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
  static final Logger _logger = const Logger('PracticeSessionScreen');
  late QuestionRepository _questionRepo;
  late SpacedRepetitionService _srService;
  late PracticeSessionService _sessionService;
  late AnswerValidationService _validationService;
  late final StudentIdService _studentIdService;
  late final MasteryRecorder _masteryRecorder;
  late final MistakeReviewService _mistakeReviewService;
  late final DifficultyController _difficultyAdapter;
  late final TopicRepository _topicRepo;
  late final SourceRepository _sourceRepo;
  List<Topic> _topics = [];
  List<Source> _sources = [];
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
  StreamSubscription<String>? _voiceSubscription;
  Timer? _voiceTimeout;
  String? _voiceTranscriptionPreview;

  @override
  void initState() {
    super.initState();
    _questionRepo = ref.read(questionRepositoryProvider);
    _srService = ref.read(spacedRepetitionServiceProvider);
    _studentIdService = ref.read(studentIdServiceProvider);
    _masteryRecorder = ref.read(masteryRecorderProvider);
    _mistakeReviewService = ref.read(mistakeReviewServiceProvider);
    _difficultyAdapter = DifficultyController();
    _topicRepo = ref.read(topicRepositoryProvider);
    _sourceRepo = ref.read(sourceRepositoryProvider);
    final sessionRepo = ref.read(sessionRepositoryProvider);
    _sessionService = PracticeSessionService(
      sessionRepo: sessionRepo,
      srService: _srService,
      studentIdService: _studentIdService,
      subjectId: widget.args.subjectId,
    );
    _loadQuestions();
    _loadTopicsAndSources();
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

  Future<void> _loadTopicsAndSources() async {
    try {
      await _topicRepo.init();
      await _sourceRepo.init();
      final topicsResult = await _topicRepo.getBySubject(widget.args.subjectId);
      final sourcesResult = await _sourceRepo.getAll();
      if (mounted) {
        setState(() {
          _topics = topicsResult.data ?? [];
          _sources = sourcesResult.data ?? [];
        });
      }
    } catch (e) {
      _logger.w('Failed to load topics and sources for create dialog', e);
    }
  }

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

    setState(() {
      _isSubmitted = true;
      _isFeedbackVisible = true;
    });
  }

  void _reorderRemainingByDifficulty() {
    final targetDifficulty = _difficultyAdapter.currentDifficulty;
    if (_currentIndex >= _questions.length - 1) return;
    final remaining = _questions.sublist(_currentIndex + 1);
    remaining.sort((a, b) {
      final aMatch = a.difficulty == targetDifficulty ? 0 : 1;
      final bMatch = b.difficulty == targetDifficulty ? 0 : 1;
      final diff = aMatch - bMatch;
      if (diff != 0) return diff;
      return a.difficulty.compareTo(b.difficulty);
    });
    _questions
      ..removeRange(_currentIndex + 1, _questions.length)
      ..addAll(remaining);
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _reorderRemainingByDifficulty();
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
    final mistakesResult = await _mistakeReviewService.getMistakesFromSession(
      studentId: _studentIdService.getStudentId(),
      subjectId: widget.args.subjectId,
      after: _sessionService.sessionStartTime,
    );
    final mistakes = mistakesResult.data ?? [];
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

    if (!voiceService.isAvailable) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.micPermissionDenied)),
      );
      return;
    }

    if (voiceService.isListening) {
      voiceService.stopListening();
      _voiceSubscription?.cancel();
      _voiceSubscription = null;
      _voiceTimeout?.cancel();
      _voiceTimeout = null;
      if (_voiceTranscriptionPreview != null && _voiceTranscriptionPreview!.isNotEmpty) {
        _onAnswerSelected(_voiceTranscriptionPreview);
      }
      _voiceTranscriptionPreview = null;
      if (mounted) setState(() {});
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    voiceService.startListening(localeName: l10n.localeName);

    _voiceSubscription?.cancel();
    _voiceSubscription = voiceService.transcribedText.listen((text) {
      if (_isSubmitted) return;
      if (mounted) {
        setState(() => _voiceTranscriptionPreview = text);
      }
    });

    _voiceTimeout?.cancel();
    _voiceTimeout = Timer(Timeouts.voicePracticeListen, () {
      if (mounted) {
        voiceService.stopListening();
        _voiceSubscription?.cancel();
        _voiceSubscription = null;
        if (_voiceTranscriptionPreview != null && _voiceTranscriptionPreview!.isNotEmpty) {
          _onAnswerSelected(_voiceTranscriptionPreview);
        }
        _voiceTranscriptionPreview = null;
        _voiceTimeout = null;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _voiceSubscription?.cancel();
    _voiceTimeout?.cancel();
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
      floatingActionButton: FloatingActionButton.small(
        onPressed: _showCreateQuestionDialog,
        tooltip: l10n.createQuestion,
        child: const Icon(Icons.add),
      ),
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
                                          return Semantics(
                                            label: vs.isAvailable ? l10n.voiceInput : l10n.voiceInputNotAvailable,
                                            button: true,
                                            child: IconButton(
                                              icon: Icon(
                                                vs.isListening ? Icons.mic : Icons.mic_none,
                                                color: vs.isListening
                                                    ? Theme.of(context).colorScheme.error
                                                    : vs.isAvailable ? null : Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                              tooltip: vs.isAvailable ? l10n.voiceInput : l10n.voiceInputNotAvailable,
                                              onPressed: vs.isAvailable ? _useVoiceInput : null,
                                            ),
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
    return ConfidenceSelector(
      value: _currentConfidence,
      onChanged: (rating) => setState(() => _currentConfidence = rating),
    );
  }

  Future<void> _showCreateQuestionDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final textController = TextEditingController();
    final explanationController = TextEditingController();
    final optionControllers = <TextEditingController>[];
    String selectedType = QuestionType.singleChoice.name;
    String selectedTopicId = '';
    String selectedDifficulty = 'easy';
    int? selectedCorrectOption;
    final selectedCorrectOptions = <int>{};
    final selectedSourceIds = <String>{};

    optionControllers.add(TextEditingController());
    optionControllers.add(TextEditingController());

    List<Topic> topicsForSubject() {
      if (widget.args.subjectId.isEmpty) return _topics;
      return _topics.where((t) => t.subjectId == widget.args.subjectId).toList();
    }

    List<Source> sourcesForSubject() {
      if (widget.args.subjectId.isEmpty) return _sources;
      return _sources.where((s) => s.subjectId == widget.args.subjectId).toList();
    }

    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setInnerState) => AlertDialog(
            title: Text(l10n.createQuestion),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    decoration: InputDecoration(labelText: l10n.questionText, border: const OutlineInputBorder()),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: InputDecoration(labelText: l10n.type, border: const OutlineInputBorder()),
                    items: QuestionType.values.map((t) => DropdownMenuItem(
                      value: t.name,
                      child: Text(questionTypeLabel(t, l10n)),
                    )).toList(),
                    onChanged: (v) {
                      selectedType = v ?? QuestionType.singleChoice.name;
                      setInnerState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedTopicId.isEmpty ? null : selectedTopicId,
                    decoration: InputDecoration(
                      labelText: l10n.topics,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: '', child: Text(l10n.none)),
                      ...topicsForSubject().map((t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(t.title),
                      )),
                    ],
                    onChanged: (v) {
                      selectedTopicId = v ?? '';
                      setInnerState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDifficulty,
                    decoration: InputDecoration(
                      labelText: l10n.difficulty,
                      border: const OutlineInputBorder(),
                    ),
                    items: ['easy', 'medium', 'hard'].map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(d[0].toUpperCase() + d.substring(1)),
                    )).toList(),
                    onChanged: (v) => selectedDifficulty = v ?? 'easy',
                  ),
                  if (sourcesForSubject().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: l10n.sources,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: '', child: Text(l10n.none)),
                        ...sourcesForSubject().map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.title),
                        )),
                      ],
                      onChanged: (v) {
                        if (v != null && v.isNotEmpty) {
                          setInnerState(() {
                            if (selectedSourceIds.contains(v)) {
                              selectedSourceIds.remove(v);
                            } else {
                              selectedSourceIds.add(v);
                            }
                          });
                        }
                      },
                    ),
                    if (selectedSourceIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: selectedSourceIds.map((sid) {
                            final name = _sourceName(sid) ?? sid;
                            return Chip(
                              label: Text(name, style: const TextStyle(fontSize: 12)),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => setInnerState(() => selectedSourceIds.remove(sid)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                  if (selectedType == QuestionType.singleChoice.name ||
                      selectedType == QuestionType.multiChoice.name) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    Text(l10n.answerOptions, style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (selectedType == QuestionType.singleChoice.name)
                      RadioGroup<int?>(
                        groupValue: selectedCorrectOption,
                        onChanged: (v) => setInnerState(() => selectedCorrectOption = v),
                        child: Column(
                          children: List.generate(optionControllers.length, (i) {
                            final controller = optionControllers[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Radio<int?>(value: i),
                                  Expanded(child: TextField(controller: controller, decoration: InputDecoration(hintText: '${l10n.addOption} ${i + 1}', border: const OutlineInputBorder(), isDense: true))),
                                  if (optionControllers.length > 2)
                                    IconButton(
                                      icon: Icon(Icons.remove_circle_outline, color: Theme.of(ctx).colorScheme.error, size: 20),
                                      tooltip: l10n.delete,
                                      onPressed: () {
                                        setInnerState(() {
                                          controller.dispose();
                                          optionControllers.removeAt(i);
                                          if (selectedCorrectOption == i) {
                                            selectedCorrectOption = null;
                                          } else if (selectedCorrectOption != null && selectedCorrectOption! > i) {
                                            selectedCorrectOption = selectedCorrectOption! - 1;
                                          }
                                        });
                                      },
                                    ),
                                ],
                              ),
                            );
                          }),
                        ),
                      )
                    else
                      ...List.generate(optionControllers.length, (i) {
                        final controller = optionControllers[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Checkbox(
                                value: selectedCorrectOptions.contains(i),
                                onChanged: (v) => setInnerState(() {
                                  if (v == true) { selectedCorrectOptions.add(i); } else { selectedCorrectOptions.remove(i); }
                                }),
                              ),
                              Expanded(child: TextField(controller: controller, decoration: InputDecoration(hintText: '${l10n.addOption} ${i + 1}', border: const OutlineInputBorder(), isDense: true))),
                              if (optionControllers.length > 2)
                                IconButton(
                                  icon: Icon(Icons.remove_circle_outline, color: Theme.of(ctx).colorScheme.error, size: 20),
                                  tooltip: l10n.delete,
                                  onPressed: () {
                                    setInnerState(() {
                                      controller.dispose();
                                      optionControllers.removeAt(i);
                                      if (selectedCorrectOption == i) {
                                        selectedCorrectOption = null;
                                      } else if (selectedCorrectOption != null && selectedCorrectOption! > i) {
                                        selectedCorrectOption = selectedCorrectOption! - 1;
                                      }
                                    });
                                  },
                                ),
                            ],
                          ),
                        );
                      }),
                    TextButton.icon(onPressed: () => setInnerState(() => optionControllers.add(TextEditingController())), icon: const Icon(Icons.add, size: 18), label: Text(l10n.addOption)),
                    const Divider(),
                  ],
                  const SizedBox(height: 12),
                  TextField(controller: explanationController, decoration: InputDecoration(labelText: l10n.explanation, border: const OutlineInputBorder()), maxLines: 2),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
              FilledButton(
                onPressed: () {
                  if (textController.text.trim().isEmpty) return;
                  if ((selectedType == QuestionType.singleChoice.name ||
                      selectedType == QuestionType.multiChoice.name) &&
                      optionControllers.any((c) => c.text.trim().isEmpty)) {
                    return;
                  }
                  Navigator.pop(ctx, {
                    'text': textController.text.trim(),
                    'type': selectedType,
                    'topicId': selectedTopicId,
                    'difficulty': selectedDifficulty,
                    'options': optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(),
                    'correctOption': selectedCorrectOption,
                    'correctOptions': selectedCorrectOptions.toList(),
                    'explanation': explanationController.text.trim(),
                    'sourceIds': selectedSourceIds.toList(),
                  });
                },
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      );

      if (result == null || !mounted) return;

      int difficultyValue;
      switch (selectedDifficulty) {
        case 'easy':
          difficultyValue = 1;
        case 'medium':
          difficultyValue = 2;
        case 'hard':
          difficultyValue = 3;
        default:
          difficultyValue = 1;
      }

      final options = (result['options'] as List<dynamic>?)?.cast<String>() ?? <String>[];
      final correctOption = result['correctOption'] as int?;
      final correctOptions = (result['correctOptions'] as List<dynamic>?)?.cast<int>();
      final sourceIds = (result['sourceIds'] as List<dynamic>?)?.cast<String>() ?? selectedSourceIds.toList();

      Markscheme? markscheme;
      if (correctOption != null && correctOption < options.length) {
        markscheme = Markscheme(correctAnswer: options[correctOption]);
      } else if (correctOptions != null && correctOptions.isNotEmpty) {
        final correctTexts = correctOptions.where((i) => i < options.length).map((i) => options[i]).toList();
        if (correctTexts.isNotEmpty) {
          markscheme = Markscheme(correctAnswer: correctTexts.first, acceptableAnswers: correctTexts.skip(1).toList());
        }
      }

      final question = Question(
        id: IdGenerator.generate('question'),
        text: result['text'] as String,
        subjectId: widget.args.subjectId,
        topicId: result['topicId'] as String? ?? '',
        type: QuestionType.values.firstWhere((t) => t.name == result['type'], orElse: () => QuestionType.singleChoice),
        difficulty: difficultyValue,
        options: options,
        sourceIds: sourceIds,
        markscheme: markscheme,
        explanation: (result['explanation'] as String?)?.isNotEmpty == true ? result['explanation'] as String : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final saveResult = await _questionRepo.create(question);
      if (saveResult.isSuccess && mounted) {
        setState(() {
          _questions.insert(_currentIndex + 1, question);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.questionCreated)),
        );
      }
    } finally {
      textController.dispose();
      explanationController.dispose();
      for (final c in optionControllers) { c.dispose(); }
    }
  }

  String? _sourceName(String sourceId) {
    return _sources.where((s) => s.id == sourceId).firstOrNull?.title;
  }
}
