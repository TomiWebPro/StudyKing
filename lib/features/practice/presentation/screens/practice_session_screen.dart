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
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/features/practice/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/features/practice/services/mastery_recorder.dart';
import 'package:studyking/features/practice/services/mistake_review_service.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider;
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/practice/data/models/practice_models.dart';
import 'package:studyking/features/practice/services/practice_session_service.dart';
import 'package:studyking/core/services/plan_adapter.dart';
import 'package:studyking/features/practice/presentation/screens/practice_results_screen.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_feedback_widget.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_session_stats_bar.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_session_question_card.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_session_nav_buttons.dart';
import 'package:studyking/features/practice/presentation/widgets/mistake_review_widget.dart';
import 'package:studyking/features/practice/services/question_type_localizer.dart';

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
  late SpacedRepetitionRepository _srRepo;
  late PracticeSessionService _sessionService;
  late final AnswerValidationService _validationService;
  late final StudentIdService _studentIdService;
  late final MasteryRecorder _masteryRecorder;
  late final MistakeReviewService _mistakeReviewService;
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
    _srRepo = ref.read(spacedRepetitionRepositoryProvider);
    _studentIdService = ref.read(studentIdServiceProvider);
    _masteryRecorder = ref.read(masteryRecorderProvider);
    _mistakeReviewService = ref.read(mistakeReviewServiceProvider);
    final sessionRepo = ref.read(sessionRepositoryProvider);
    _sessionService = PracticeSessionService(
      sessionRepo: sessionRepo,
      srRepo: _srRepo,
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
            onPressed: () => Navigator.pop(context),
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
    await _finalizeSession();
    if (!mounted) return;
    if (_mistakeQuestionIds.isNotEmpty) {
      _showMistakeReview();
    } else {
      _navigateToResults();
    }
  }

  void _showMistakeReview() async {
    final mistakes = await _mistakeReviewService.getMistakesFromSession(
      studentId: _studentIdService.getStudentId(),
      subjectId: widget.args.subjectId,
      after: _sessionService.sessionStartTime,
    );
    if (!mounted || mistakes.isEmpty) {
      _navigateToResults();
      return;
    }
    MistakeReviewWidget.show(
      context,
      mistakes: mistakes,
      onRedo: () {
        Navigator.pop(context);
        _startMistakeRedo(mistakes);
      },
      onDismiss: () {
        Navigator.pop(context);
        _navigateToResults();
      },
    );
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
    final planAdapter = PlanAdapter();
    await planAdapter.recordFromPracticeSession(
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isSessionComplete) {
      return PracticeResultsScreen(
        totalQuestions: _questions.length,
        correctAnswers: _correctAnswers,
        onPracticeAgain: _restartSession,
        topicBreakdown: _computeTopicBreakdown(),
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
                                  child: Semantics(
                                    label: l10n.submitAnswer,
                                    child: FilledButton(
                                      onPressed: _currentAnswer != null ? _submitAnswer : null,
                                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                                      child: Text(l10n.submitAnswer),
                                    ),
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
                selected: isSelected,
                child: InkWell(
                  onTap: () => setState(() => _currentConfidence = rating),
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: ResponsiveUtils.minTouchTarget,
                    height: ResponsiveUtils.minTouchTarget,
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
