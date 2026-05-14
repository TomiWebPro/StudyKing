import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/repositories/study_session_repository.dart';
import 'package:studyking/features/questions/ui/widgets/single_answer_widget.dart';
import 'package:studyking/features/questions/ui/widgets/canvas_drawing_widget.dart';
import 'package:studyking/features/questions/ui/widgets/math_expression_widget.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/errors/handlers.dart';
import 'package:studyking/core/services/answer_validation_service.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/core/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/core/data/repositories/question_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider;
import '../../../../core/utils/logger.dart';

/// Practice Session Screen - Complete practice flow with progress tracking
class PracticeSessionScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String? topicId;
  final int? questionCount;
  final bool isSpacedRepetition;

  const PracticeSessionScreen({
    super.key,
    required this.subjectId,
    this.topicId,
    this.questionCount = 10,
    this.isSpacedRepetition = false,
  });

  @override
  ConsumerState<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends ConsumerState<PracticeSessionScreen> {
  final Logger _logger = const Logger('PracticeSessionScreen');
  late QuestionRepository _questionRepo;
  late SpacedRepetitionRepository _srRepo;
  late StudySessionRepository _sessionRepo;
  final AnswerValidationService _validationService = AnswerValidationService();
  List<Question> _questions = [];
  int _currentIndex = 0;
  String? _currentAnswer;
  bool _isSubmitted = false;
  bool _isFeedbackVisible = false;
  bool _isSessionComplete = false;
  bool _sessionAutoSaved = false;

  // Tracking
  int _correctAnswers = 0;
  Timer? _timer;
  DateTime _sessionStartTime = DateTime.now();
  String? _elapsedTimeFormatted;

  // Results tracking
  final List<PracticeAnswerRecord> _answerRecords = [];

  // Feedback state
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _questionRepo = ref.read(questionRepositoryProvider);
    _srRepo = ref.read(spacedRepetitionRepositoryProvider);
    _sessionRepo = ref.read(studySessionRepositoryProvider);
    _loadQuestions();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        final elapsed = DateTime.now().difference(_sessionStartTime);
        _elapsedTimeFormatted = formatDurationFromContext(context, elapsed);
      });
    });
  }
  
  Future<void> _loadQuestions() async {
    try {
      final result = await _questionRepo.getBySubject(widget.subjectId);
      if (result.isFailure || result.data == null) {
        if (mounted) {
          setState(() => _questions = []);
          _showNoQuestionsDialog();
        }
        return;
      }
      final questions = result.data!;

      List<Question> filteredQuestions = questions;
      if (widget.topicId != null && widget.topicId!.isNotEmpty) {
        filteredQuestions = questions.where((q) => q.topicId == widget.topicId).toList();
      }

      if (filteredQuestions.isEmpty) {
        if (mounted) {
          setState(() => _questions = []);
          _showNoQuestionsDialog();
        }
        return;
      }

      final shuffled = List<Question>.from(filteredQuestions)..shuffle();
      final count = (widget.questionCount ?? shuffled.length)
          .clamp(1, shuffled.length);

      if (mounted) {
        setState(() {
          _questions = shuffled.take(count).toList();
        });
        _initializeSession();
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(
          context,
          e,
          'Questions Load',
          retry: true,
          retryCallback: _retryLoadQuestions,
        );
      }
    }
  }
  
  Future<void> _retryLoadQuestions() => _loadQuestions();

  void _initializeSession() {
    if (_questions.isEmpty) {
      _showNoQuestionsDialog();
      return;
    }
    
    // Check if there's an existing session for this
    _currentAnswer = null;
    _isSubmitted = false;
    _isFeedbackVisible = false;
    
    if (mounted) {
      setState(() {});
    }
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
    setState(() {
      _currentAnswer = answer;
    });
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
    
    if (isCorrect) {
      _correctAnswers++;
    }
    
    _answerRecords.add(PracticeAnswerRecord(
      questionId: question.id,
      questionType: question.type,
      isCorrect: isCorrect,
      timeSpent: const Duration(seconds: 0),
      userAnswer: _currentAnswer!,
    ));

    if (widget.isSpacedRepetition) {
      _updateNextReview(question.id, isCorrect);
    }
    
    setState(() {
      _isSubmitted = true;
      _isFeedbackVisible = true;
    });
  }

  Future<void> _updateNextReview(String questionId, bool isCorrect) async {
    try {
      final masteryLevel = isCorrect ? 0.8 : 0.2;
      await _srRepo.updateNextReviewDate(questionId, masteryLevel);
    } catch (e) {
      _logger.e('Error updating next review date', e);
    }
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
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  Future<void> _completeSession() async {
    _timer?.cancel();

    if (!_sessionAutoSaved) {
      _sessionAutoSaved = true;
      try {
        await _sessionRepo.init();
        final endTime = DateTime.now();
        final startTime = _sessionStartTime;
        final duration = endTime.difference(startTime).inMilliseconds;
        final id = '${endTime.millisecondsSinceEpoch}_${Random().nextInt(99999)}';

        await _sessionRepo.create(StudySession(
          id: id,
          startTime: startTime,
          endTime: endTime,
          timeSpentMs: duration,
          questionsAnswered: _questions.length,
          correctAnswers: _correctAnswers,
          studentId: StudentIdService().getStudentId(),
          subjectId: widget.subjectId,
        ));
      } catch (e) {
        _logger.e('Failed to auto-save session', e);
      }
    }

    if (!mounted) return;

    setState(() {
      _isSessionComplete = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pop(context, PracticeSessionResult(
          questionsAnswered: _questions.length,
          correctAnswers: _correctAnswers,
        ));
      }
    });
  }

  void _restartSession() {
    setState(() {
      _currentIndex = 0;
      _correctAnswers = 0;
      _answerRecords.clear();
      _sessionStartTime = DateTime.now();
      _isSessionComplete = false;
      _currentAnswer = null;
      _isSubmitted = false;
      _isFeedbackVisible = false;
    });
    
    _loadQuestions();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty && !_isSessionComplete) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isSpacedRepetition 
              ? AppLocalizations.of(context)!.spacedRepetitionMode 
              : AppLocalizations.of(context)!.practice),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isSessionComplete) {
      return _buildResultsScreen();
    }

    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSpacedRepetition 
            ? AppLocalizations.of(context)!.practiceModeType(AppLocalizations.of(context)!.spacedRepetitionMode, question.type.name)
            : AppLocalizations.of(context)!.practiceModeType(AppLocalizations.of(context)!.practice, question.type.name)),
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
              child: Container(
                padding: ResponsiveUtils.cardPadding(context),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                      Semantics(
                      label: '${AppLocalizations.of(context)!.time}: ${_elapsedTimeFormatted ?? formatDurationFromContext(context, Duration.zero)}',
                      child: _buildMiniStat(
                        context,
                        AppLocalizations.of(context)!.time,
                        _elapsedTimeFormatted ?? formatDurationFromContext(context, Duration.zero),
                        Icons.access_time,
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Semantics(
                      label: '${AppLocalizations.of(context)!.score}: ${(_correctAnswers / (_currentIndex + 1) * 100).toStringAsFixed(0)}%',
                      child: _buildMiniStat(
                        context,
                        AppLocalizations.of(context)!.score,
                        '${(_correctAnswers / (_currentIndex + 1) * 100).toStringAsFixed(0)}%',
                        Icons.star,
                        _getColorForScore(_correctAnswers / (_currentIndex + 1)),
                      ),
                    ),
                    Semantics(
                      label: '${AppLocalizations.of(context)!.correct}: $_correctAnswers',
                      child: _buildMiniStat(
                        context,
                        AppLocalizations.of(context)!.correct,
                        _correctAnswers.toString(),
                        Icons.check_circle,
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Question Card
            Expanded(
              child: FocusTraversalGroup(
                child: Padding(
                  padding: ResponsiveUtils.screenPadding(context),
                  child: ListView(
                    children: [
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(2),
                        child: Container(
                          padding: ResponsiveUtils.cardPadding(context),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      question.type.name,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                question.text,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Question Widget
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(3),
                        child: _buildQuestionWidget(question),
                      ),
                      const SizedBox(height: 24),

                      // Submit button
                      if (!_isSubmitted)
                        FocusTraversalOrder(
                          order: const NumericFocusOrder(4),
                          child: Semantics(
                            label: AppLocalizations.of(context)!.submitAnswer,
                            child: FilledButton(
                              onPressed: _currentAnswer != null ? _submitAnswer : null,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                              child: Text(AppLocalizations.of(context)!.submitAnswer),
                            ),
                          ),
                        ),

                      // Feedback and navigation
                      if (_isSubmitted)
                        Column(
                          children: [
                            _buildFeedback(context, question),
                            const SizedBox(height: 16),
                            _buildNavigationButtons(context),
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

  Widget _buildQuestionWidget(Question question) {
    // Render different question types
    switch (question.type) {
      case QuestionType.singleChoice:
      case QuestionType.multiChoice:
        final correctAnswer = question.markscheme?.correctAnswer ?? '';
        final l10n = AppLocalizations.of(context)!;
        final fallbackOptions = [1, 2, 3, 4].map((i) => l10n.fallbackOption(i)).toList();
        final options = question.type == QuestionType.singleChoice 
            ? question.options.isEmpty ? fallbackOptions : question.options
            : question.options.isEmpty ? fallbackOptions : question.options;
        
        return SingleAnswerWidget(
          options: options,
          correctAnswer: correctAnswer,
          selectedAnswer: _currentAnswer,
          isSubmitted: _isSubmitted,
          isFeedbackVisible: _isFeedbackVisible,
          onAnswerSelected: _onAnswerSelected,
          reduceMotion: ref.watch(settingsProvider).reduceMotion,
        );

      case QuestionType.mathExpression:
        return MathExpressionWidget(
          expression: question.text,
          isSolution: false,
        );

      case QuestionType.canvas:
        return CanvasDrawingWidget(
          instruction: question.text,
          onDrawingComplete: (data) => _onAnswerSelected(AppLocalizations.of(context)!.drawingSubmitted),
          initialDrawing: null,
          largeTouchTargets: ref.watch(settingsProvider).largeTouchTargets,
        );

      case QuestionType.typedAnswer:
        return _buildTypedAnswerWidget(question);

      case QuestionType.essay:
        return _buildEssayWidget(question);

      default:
        return _buildFallbackWidget(question);
    }
  }

  Widget _buildTypedAnswerWidget(Question question) {
    return TextField(
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.yourAnswer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      maxLines: 3,
      keyboardType: TextInputType.multiline,
      onChanged: _onAnswerSelected,
    );
  }

  Widget _buildEssayWidget(Question question) {
    return TextField(
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.yourAnswerCharacters(_currentAnswer?.length ?? 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      maxLines: 5,
      keyboardType: TextInputType.multiline,
      onChanged: _onAnswerSelected,
    );
  }

  Widget _buildFallbackWidget(Question question) {
    final l10n = AppLocalizations.of(context)!;
    return Text(l10n.unsupportedQuestionType(question.type.name));
  }

  Widget _buildFeedback(BuildContext context, Question question) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: ResponsiveUtils.cardPadding(context),
      decoration: BoxDecoration(
        color: _isCorrect
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isCorrect ? Icons.check_circle : Icons.error_outline,
                color: _isCorrect ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                _isCorrect ? l10n.correctFeedback : l10n.incorrectFeedback,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isCorrect ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (question.explanation != null && question.explanation!.isNotEmpty)
            Text(
              question.explanation!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        FocusTraversalOrder(
          order: const NumericFocusOrder(5),
          child: Semantics(
            label: l10n.previous,
            child: ElevatedButton.icon(
              onPressed: _previousQuestion,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.previous),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FocusTraversalOrder(
          order: const NumericFocusOrder(6),
          child: Semantics(
            label: l10n.next,
            child: ElevatedButton.icon(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.arrow_forward),
              label: Text(l10n.next),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(BuildContext context, String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color ?? Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getColorForScore(double score) {
    final cs = Theme.of(context).colorScheme;
    if (score >= 0.8) return cs.primary;
    if (score >= 0.5) return cs.tertiary;
    return cs.error;
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildResultsScreen() {
    final l10n = AppLocalizations.of(context)!;
    final accuracy = _questions.isEmpty
        ? 0.0
        : (_correctAnswers / _questions.length) * 100;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sessionResults)),
      body: Padding(
        padding: ResponsiveUtils.screenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.practiceComplete,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow(l10n.totalQuestions, _questions.length.toString()),
            const SizedBox(height: 12),
            _buildStatRow(l10n.correctAnswers, '$_correctAnswers/${_questions.length}'),
            const SizedBox(height: 12),
            _buildStatRow(l10n.accuracy, '${accuracy.toStringAsFixed(0)}%'),
            const SizedBox(height: 24),
            Center(
              child: Semantics(
                label: l10n.practiceAgain,
                child: ElevatedButton.icon(
                  onPressed: _restartSession,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.practiceAgain),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Record of a single answer during a practice session
class PracticeAnswerRecord {
  final String questionId;
  final QuestionType questionType;
  final bool isCorrect;
  final Duration timeSpent;
  final String userAnswer;

  PracticeAnswerRecord({
    required this.questionId,
    required this.questionType,
    required this.isCorrect,
    required this.timeSpent,
    required this.userAnswer,
  });
}

class PracticeSessionResult {
  final int questionsAnswered;
  final int correctAnswers;

  PracticeSessionResult({required this.questionsAnswered, required this.correctAnswers});
}
