import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/services/answer_validation_service.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/practice/services/exam_session_service.dart';
import 'package:studyking/features/practice/services/mastery_recorder.dart';
import 'package:studyking/features/practice/services/mistake_review_service.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_feedback_widget.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_session_question_card.dart';
import 'package:studyking/features/practice/presentation/widgets/mistake_review_widget.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_session_nav_buttons.dart';

class ExamSessionScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String subjectName;

  const ExamSessionScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  ConsumerState<ExamSessionScreen> createState() => _ExamSessionScreenState();
}

class _ExamSessionScreenState extends ConsumerState<ExamSessionScreen> {
  late ExamSessionService _examService;
  late AnswerValidationService _validationService;
  late QuestionRepository _questionRepo;
  late MasteryRecorder _masteryRecorder;
  late StudentIdService _studentIdService;

  ExamConfig? _config;
  List<Question> _questions = [];
  int _currentIndex = 0;
  String? _currentAnswer;
  bool _isSubmitted = false;
  bool _isFeedbackVisible = false;
  bool _isCorrect = false;
  bool _examFinished = false;
  bool _isLoadingConfig = true;
  bool _isReloadingQuestions = false;
  bool _isExamActive = false;

  final List<ExamQuestionResult> _results = [];
  ExamResult? _examResult;
  DateTime? _questionStartTime;

  int _durationMinutes = 30;
  int _questionCount = 10;

  @override
  void initState() {
    super.initState();
    _examService = ref.read(examSessionServiceProvider);
    _questionRepo = ref.read(questionRepositoryProvider);
    _masteryRecorder = ref.read(masteryRecorderProvider);
    _studentIdService = ref.read(studentIdServiceProvider);
    _examService.timeRemainingNotifier.addListener(_onTimeChanged);
    _loadQuestions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _validationService = AnswerValidationService(
      messages: ValidationMessages.fromLocalizations(AppLocalizations.of(context)!),
    );
  }

  @override
  void dispose() {
    _examService.timeRemainingNotifier.removeListener(_onTimeChanged);
    _examService.dispose();
    super.dispose();
  }

  void _onTimeChanged() {
    if (!mounted) return;
    if (_examService.isTimeUp() && _isExamActive) {
      _autoSubmitExam();
    }
    setState(() {});
  }

  Future<void> _loadQuestions() async {
    try {
      final result = await _questionRepo.getBySubject(widget.subjectId);
      if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
        _config = ExamConfig(
          durationMinutes: _durationMinutes,
          questionCount: _questionCount,
          subjectId: widget.subjectId,
        );
        final selected = _examService.selectQuestions(
          pool: result.data!,
          config: _config!,
        );
        setState(() {
          _questions = selected;
          _isLoadingConfig = false;
          _isReloadingQuestions = false;
        });
      } else {
        setState(() {
          _isLoadingConfig = false;
          _isReloadingQuestions = false;
        });
        _showNoQuestionsDialog();
      }
    } catch (e) {
      setState(() {
        _isLoadingConfig = false;
        _isReloadingQuestions = false;
      });
      _showNoQuestionsDialog();
    }
  }

  void _showNoQuestionsDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.noQuestionsAvailable),
        content: Text(l10n.noQuestionsForSelectedSubject),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  void _startExam() {
    if (_config == null || _questions.isEmpty) return;
    _examService.startExam(_config!);
    setState(() {
      _isExamActive = true;
      _currentIndex = 0;
      _currentAnswer = null;
      _isSubmitted = false;
      _isFeedbackVisible = false;
      _questionStartTime = DateTime.now();
    });
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
    final timeSpentMs = _computeTimeSpent();

    _results.add(ExamQuestionResult(
      question: question,
      userAnswer: _currentAnswer,
      isCorrect: isCorrect,
      timeSpentMs: timeSpentMs,
      wasSkipped: false,
    ));

    await _masteryRecorder.recordAttempt(
      studentId: _studentIdService.getStudentId(),
      questionId: question.id,
      subjectId: question.subjectId,
      topicId: question.topicId,
      isCorrect: isCorrect,
      timeSpentMs: timeSpentMs,
      confidence: isCorrect ? 4 : 2,
      userAnswer: _currentAnswer!,
    );

    setState(() {
      _isSubmitted = true;
      _isFeedbackVisible = true;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _currentAnswer = null;
        _isSubmitted = false;
        _isFeedbackVisible = false;
        _questionStartTime = DateTime.now();
      });
    } else {
      _finishExam();
    }
  }

  Future<void> _finishExam() async {
    if (_config == null) return;
    final result = await _examService.finishExam(
      config: _config!,
      questionResults: _results,
      autoSubmitted: false,
    );
    if (!mounted) return;
    setState(() {
      _examResult = result;
      _examFinished = true;
      _isExamActive = false;
    });
  }

  Future<void> _autoSubmitExam() async {
    if (_config == null || !_isExamActive) return;

    for (final q in _questions.skip(_currentIndex)) {
      _results.add(ExamQuestionResult(
        question: q,
        userAnswer: null,
        isCorrect: false,
        timeSpentMs: 0,
        wasSkipped: true,
      ));
    }

    final result = await _examService.finishExam(
      config: _config!,
      questionResults: _results,
      autoSubmitted: true,
    );
    if (!mounted) return;
    setState(() {
      _examResult = result;
      _examFinished = true;
      _isExamActive = false;
    });
  }

  void _showMistakeReview() {
    final mistakes = _results
        .where((r) => !r.isCorrect && !r.wasSkipped)
        .map((r) => MistakeEntry(
              question: r.question,
              correctAnswer: r.question.markscheme?.correctAnswer ?? '',
              explanation: r.question.explanation,
            ))
        .toList();
    if (mistakes.isEmpty) return;
    MistakeReviewWidget.show(
      context,
      mistakes: mistakes,
      onDismiss: () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoadingConfig) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.practiceMode)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isExamActive && !_examFinished) {
      return _buildConfigScreen(l10n);
    }

    if (_examFinished) {
      return _buildResultsScreen(l10n);
    }

    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;
    final timeRemaining = _examService.timeRemainingNotifier.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.practiceMode),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Semantics(
            liveRegion: true,
            label: l10n.examProgressLabel(_currentIndex + 1, _questions.length),
            child: LinearProgressIndicator(value: progress),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_currentIndex + 1}/${_questions.length}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: timeRemaining.inMinutes < 5
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatDurationFromContext(context, timeRemaining),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: timeRemaining.inMinutes < 5
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: ResponsiveUtils.screenPadding(context),
                children: [
                  PracticeSessionQuestionCard(
                    question: question,
                    currentAnswer: _currentAnswer,
                    isSubmitted: _isSubmitted,
                    isFeedbackVisible: _isFeedbackVisible,
                    onAnswerSelected: _onAnswerSelected,
                  ),
                  SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
                  if (!_isSubmitted)
                    FilledButton(
                      onPressed: _currentAnswer != null ? _submitAnswer : null,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      child: Text(l10n.submitAnswer),
                    ),
                  if (_isSubmitted)
                    Column(
                      children: [
                        PracticeFeedbackWidget(
                          isCorrect: _isCorrect,
                          explanation: question.explanation,
                        ),
                        SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
                        PracticeSessionNavButtons(
                          onPrevious: null,
                          onNext: _nextQuestion,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigScreen(AppLocalizations l10n) {
    return Scaffold(
      appBar: AppBar(title: Text('${l10n.practiceMode} - ${widget.subjectName}')),
      body: Stack(
        children: [
          SingleChildScrollView(
        padding: ResponsiveUtils.screenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.examConfiguration,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
            _buildDurationSelector(),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
            _buildQuestionCountSelector(),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 3),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _questions.isEmpty || _isReloadingQuestions ? null : _startExam,
                icon: _isReloadingQuestions
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(l10n.startExam),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ),
          ],
        ),
      ),
          if (_isReloadingQuestions)
            const LinearProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildDurationSelector() {
    final l10n = AppLocalizations.of(context)!;
    const durations = [15, 30, 45, 60];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.examDuration, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
        Wrap(
          spacing: 8,
          children: durations.map((d) => ChoiceChip(
            label: Text(l10n.durationMinutes(d)),
            selected: _durationMinutes == d,
            onSelected: (_) => setState(() => _durationMinutes = d),
            visualDensity: VisualDensity.compact,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildQuestionCountSelector() {
    final l10n = AppLocalizations.of(context)!;
    const counts = [5, 10, 15, 20, 30];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.numberOfQuestions, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
        Wrap(
          spacing: 8,
          children: counts.map((c) => ChoiceChip(
            label: Text('$c'),
            selected: _questionCount == c,
            onSelected: (_) => {
              setState(() {
                _questionCount = c;
                _isReloadingQuestions = true;
              }),
              _loadQuestions(),
            },
            visualDensity: VisualDensity.compact,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildResultsScreen(AppLocalizations l10n) {
    final result = _examResult!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sessionResults)),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.screenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.practiceComplete,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
            _buildResultRow(l10n.totalQuestions, formatDecimal(result.questionResults.length.toDouble(), l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0)),
            _buildResultRow(l10n.correctAnswers, formatDecimal(result.totalCorrect.toDouble(), l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0)),
            _buildResultRow(l10n.incorrectLabel, formatDecimal(result.totalIncorrect.toDouble(), l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0)),
            _buildResultRow(l10n.skippedLabel, formatDecimal(result.totalSkipped.toDouble(), l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0)),
            _buildResultRow(
              l10n.accuracy,
              formatPercent(result.accuracy * 100, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0),
            ),
            if (result.wasAutoSubmitted)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.examAutoSubmitted,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
            if (result.topicBreakdown.isNotEmpty) ...[
              Text(
                l10n.topicBreakdown,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
              ...result.topicBreakdown.entries.map((e) => _buildResultRow(
                e.key,
                formatPercent(e.value * 100, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0),
              )),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
            ],
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.home),
                    label: Text(l10n.done),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showMistakeReview,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.practiceAgain),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _computeTimeSpent() {
    if (_questionStartTime == null) return 0;
    return DateTime.now().difference(_questionStartTime!).inMilliseconds;
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
