import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/errors/handlers.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/services/answer_validation_service.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/core/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/core/data/repositories/question_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/practice/presentation/models/practice_models.dart';
import 'package:studyking/features/practice/presentation/services/practice_session_service.dart';
import 'package:studyking/features/sessions/services/session_plan_integration_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/practice/presentation/practice_results_screen.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_feedback_widget.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_session_stats_bar.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_session_question_card.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_session_nav_buttons.dart';
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
  List<Question> _questions = [];
  int _currentIndex = 0;
  String? _currentAnswer;
  bool _isSubmitted = false;
  bool _isFeedbackVisible = false;
  bool _isSessionComplete = false;
  bool _sessionAutoSaved = false;
  int _correctAnswers = 0;
  Timer? _displayTimer;
  String? _elapsedTimeFormatted;
  final List<PracticeAnswerRecord> _answerRecords = [];
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _questionRepo = ref.read(questionRepositoryProvider);
    _srRepo = ref.read(spacedRepetitionRepositoryProvider);
    final sessionRepo = ref.read(studySessionRepositoryProvider);
    _sessionService = PracticeSessionService(
      sessionRepo: sessionRepo,
      srRepo: _srRepo,
      subjectId: widget.args.subjectId,
    );
    _loadQuestions();
    _startDisplayTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _validationService = AnswerValidationService(
      messages: ValidationMessages.fromLocalizations(AppLocalizations.of(context)!),
    );
  }

  void _startDisplayTimer() {
    _displayTimer?.cancel();
    _displayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        final elapsed = DateTime.now().difference(_sessionService.sessionStartTime);
        _elapsedTimeFormatted = formatDurationFromContext(context, elapsed);
      });
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
    if (mounted) setState(() {});
  }

  void _showNoQuestionsDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.noQuestionsAvailable),
        content: Text(l10n.noQuestionsForSelectedSubject),
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

  void _submitAnswer() {
    if (_currentAnswer == null || _questions.isEmpty) return;
    final question = _questions[_currentIndex];
    final isCorrect = _validateAnswer(question, _currentAnswer!);
    if (isCorrect) _correctAnswers++;
    _answerRecords.add(PracticeAnswerRecord(
      questionId: question.id,
      questionType: question.type,
      isCorrect: isCorrect,
      timeSpent: const Duration(seconds: 0),
      userAnswer: _currentAnswer!,
    ));
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
        _currentIndex++;
        _currentAnswer = null;
        _isSubmitted = false;
        _isFeedbackVisible = false;
      });
    } else {
      _completeSession();
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) setState(() => _currentIndex--);
  }

  Future<void> _completeSession() async {
    _displayTimer?.cancel();
    if (!_sessionAutoSaved) {
      _sessionAutoSaved = true;
      await _sessionService.autoSaveSession(
        questionsAnswered: _questions.length,
        correctAnswers: _correctAnswers,
      );
    }
    _recordAdherence();
    if (!mounted) return;
    setState(() => _isSessionComplete = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pop(context, PracticeSessionResult(
          questionsAnswered: _questions.length,
          correctAnswers: _correctAnswers,
        ));
      }
    });
  }

  Future<void> _recordAdherence() async {
    final elapsedMinutes = DateTime.now()
        .difference(_sessionService.sessionStartTime)
        .inMinutes;
    final integrationService = SessionPlanIntegrationService(
      fixedStudentId: StudentIdService().getStudentId(),
    );
    await integrationService.recordPracticeSessionCompletion(
      actualQuestions: _questions.length,
      elapsedMinutes: elapsedMinutes,
    );
  }

  void _restartSession() {
    setState(() {
      _currentIndex = 0;
      _correctAnswers = 0;
      _answerRecords.clear();
      _isSessionComplete = false;
      _currentAnswer = null;
      _isSubmitted = false;
      _isFeedbackVisible = false;
    });
    _loadQuestions();
    _startDisplayTimer();
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
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
      );
    }

    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.args.isSpacedRepetition
            ? AppLocalizations.of(context)!.practiceModeType(AppLocalizations.of(context)!.spacedRepetitionMode, question.type.localizedLabel(AppLocalizations.of(context)!))
            : AppLocalizations.of(context)!.practiceModeType(AppLocalizations.of(context)!.practice, question.type.localizedLabel(AppLocalizations.of(context)!))),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: progress),
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
                      const SizedBox(height: 24),
                      if (!_isSubmitted)
                        FocusTraversalOrder(
                          order: const NumericFocusOrder(4),
                          child: Semantics(
                            label: AppLocalizations.of(context)!.submitAnswer,
                            child: FilledButton(
                              onPressed: _currentAnswer != null ? _submitAnswer : null,
                              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                              child: Text(AppLocalizations.of(context)!.submitAnswer),
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
                            const SizedBox(height: 16),
                            PracticeSessionNavButtons(
                              onPrevious: _previousQuestion,
                              onNext: _nextQuestion,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
