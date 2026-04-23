import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/core/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/study_session_repository.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/questions/ui/widgets/single_answer_widget.dart';
import 'package:studyking/features/questions/ui/widgets/canvas_drawing_widget.dart';
import 'package:studyking/features/questions/ui/widgets/math_expression_widget.dart';

/// Practice Session Screen - Complete practice flow with progress tracking
class PracticeSessionScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String? topicId;
  final int? questionCount;

  const PracticeSessionScreen({
    super.key,
    required this.subjectId,
    this.topicId,
    this.questionCount = 10,
  });

  @override
  ConsumerState<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends ConsumerState<PracticeSessionScreen> {
  late QuestionRepository _questionRepo;
  late StudySessionRepository _sessionRepo;
  List<Question> _questions = [];
  int _currentIndex = 0;
  String? _currentAnswer;
  bool _isSubmitted = false;
  bool _isFeedbackVisible = false;
  bool _isSessionComplete = false;
  
  // Tracking
  int _correctAnswers = 0;
  Timer? _timer;
  DateTime _sessionStartTime = DateTime.now();
  String? _sessionEndTime;
  
  // Results tracking
  final List<PracticeAnswerRecord> _answerRecords = [];

  @override
  void initState() {
    super.initState();
    _questionRepo = QuestionRepository();
    _sessionRepo = StudySessionRepository();
    _loadQuestions();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {});
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await _questionRepo.getBySubject(widget.subjectId);
      
      // Filter by topic if specified
      List<Question> filteredQuestions = questions;
      if (widget.topicId != null && widget.topicId!.isNotEmpty) {
        filteredQuestions = questions.where((q) => q.topicId == widget.topicId).toList();
      }
      
      // Take requested number or all available
      final count = widget.questionCount!.clamp(1, filteredQuestions.length);
      
      if (mounted) {
        setState(() {
          _questions = filteredQuestions.take(count).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading questions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load questions: $e')),
        );
      }
    }
    
    if (mounted) {
      _initializeSession();
    }
  }

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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Questions Available'),
        content: const Text('There are no questions for the selected subject/topic. Start creating questions!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Back to Lessons'),
          ),
        ],
      ),
    );
  }

  void _onAnswerSelected(String? answer) {
    setState(() {
      _currentAnswer = answer;
    });
  }

  void _submitAnswer() {
    if (_currentAnswer == null) return;
    
    final question = _questions[_currentIndex];
    final isCorrect = _validateAnswer(question, _currentAnswer!);
    
    if (isCorrect) {
      _correctAnswers++;
    }
    
    _answerRecords.add(PracticeAnswerRecord(
      questionId: question.id,
      questionType: question.type,
      isCorrect: isCorrect,
      timeSpent: const Duration(seconds: 5), // Would track actual time
      userAnswer: _currentAnswer!,
    ));
    
    setState(() {
      _isSubmitted = true;
      _isFeedbackVisible = true;
    });
  }

  bool _validateAnswer(Question question, String answer) {
    // Simple validation for now - should integrate with Markscheme
    switch (question.type) {
      case QuestionType.singleChoice:
      case QuestionType.multiChoice:
        // markscheme is a String, handle it appropriately
        final correctAnswer = question.markscheme ?? '';
        return answer.toLowerCase() == correctAnswer.toLowerCase();
      
      case QuestionType.typedAnswer:
        // For typed answers, we'd need AI validation
        // For now, consider any answer as valid
        return answer.isNotEmpty;
      
      default:
        return answer.isNotEmpty;
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

  void _completeSession() {
    _timer?.cancel();
    _sessionEndTime = DateTime.now().toIso8601String();
    
    // Update UI to show results
    setState(() {
      _isSessionComplete = true;
    });
    
    // Save session to database
    final totalTime = DateTime.parse(_sessionEndTime!).difference(_sessionStartTime).inMilliseconds;
    
    _sessionRepo.create(StudySession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: _sessionStartTime,
      endTime: DateTime.parse(_sessionEndTime!),
      timeSpentMs: totalTime,
      questionsAnswered: _questions.length,
      correctAnswers: _correctAnswers,
      studentId: 'anonymous',
      subjectId: widget.subjectId,
    ));
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
        appBar: AppBar(title: const Text('Practice')),
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
        title: Text('Practice - ${question.type.name}'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: progress),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress info
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMiniStat(
                    context,
                    'Question',
                    '${_currentIndex + 1}/${_questions.length}',
                    Icons.numbers,
                  ),
                  _buildMiniStat(
                    context,
                    'Score',
                    '${(_correctAnswers / (_currentIndex + 1) * 100).toStringAsFixed(0)}%',
                    Icons.star,
                    color: _getColorForScore(_correctAnswers / (_currentIndex + 1)),
                  ),
                  _buildMiniStat(
                    context,
                    'Correct',
                    _correctAnswers.toString(),
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                ],
              ),
            ),

            // Question Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    // Question text
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
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
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  question.type.name,
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
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
                    const SizedBox(height: 24),

                    // Question Widget
                    _buildQuestionWidget(question),
                    const SizedBox(height: 24),

                    // Submit button
                    if (!_isSubmitted)
                      FilledButton(
                        onPressed: _currentAnswer != null ? _submitAnswer : null,
                        child: const Text('Submit Answer'),
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
        // For MCQs, we'll use placeholder options for now
        // In production, options would be stored in the question
        return SingleAnswerWidget(
          questionText: '',
          options: ['Answer A', 'Answer B', 'Answer C', 'Answer D'],
          correctAnswer: question.markscheme ?? 'Answer A',
          selectedAnswer: _currentAnswer,
          isSubmitted: _isSubmitted,
          isFeedbackVisible: _isFeedbackVisible,
          onAnswerSelected: _onAnswerSelected,
        );

      case QuestionType.mathExpression:
        return MathExpressionWidget(
          expression: question.text,
          isSolution: false,
        );

      case QuestionType.canvas:
        return CanvasDrawingWidget(
          instruction: question.text,
          onDrawingComplete: (data) => _onAnswerSelected('Drawing submitted'),
          initialDrawing: null,
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
        labelText: 'Your Answer',
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
        labelText: 'Your Answer (${_currentAnswer?.length ?? 0} characters)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        counterText: '',
      ),
      maxLines: 10,
      keyboardType: TextInputType.multiline,
      onChanged: _onAnswerSelected,
    );
  }

  Widget _buildFallbackWidget(Question question) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 64),
            const SizedBox(height: 16),
            Text(
              'Question type "${question.type.name}" not fully implemented yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedback(BuildContext context, Question question) {
    final isCorrect = _validateAnswer(question, _currentAnswer!);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect 
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.red,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.error_outline,
            color: isCorrect ? Colors.green : Colors.red,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? 'Correct!' : 'Incorrect',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                ),
                // markscheme is a String now, not an object
                if (question.markscheme != null && 
                    question.type == QuestionType.singleChoice) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Answer: ${question.markscheme}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    final theme = Theme.of(context);
    final canGoBack = _currentIndex > 0;
    final canGoNext = _currentIndex < _questions.length - 1;

    return Row(
      children: [
        if (canGoBack)
          OutlinedButton.icon(
            onPressed: _previousQuestion,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.primaryColor,
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            onPressed: canGoNext ? _nextQuestion : _completeSession,
            icon: Icon(canGoNext ? Icons.arrow_forward : Icons.celebration),
            label: Text(canGoNext ? 'Next' : 'See Results'),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(BuildContext context, String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Theme.of(context).primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? Theme.of(context).primaryColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Color _getColorForScore(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.5) return Colors.orange;
    return Colors.red;
  }

  Widget _buildResultsScreen() {
    final theme = Theme.of(context);
    final score = _correctAnswers / _questions.length * 100;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Complete'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Score Circle
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      score >= 80 ? Colors.green : Colors.orange,
                      score >= 80 ? Colors.green.withOpacity(0.5) : Colors.orange.withOpacity(0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${score.toStringAsFixed(1)}%',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Your Score',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildResultsStat(
                      context,
                      'Questions',
                      '${_questions.length}',
                      Icons.question_answer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildResultsStat(
                      context,
                      'Correct',
                      '${_correctAnswers}',
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildResultsStat(
                      context,
                      'Incorrect',
                      '${_questions.length - _correctAnswers}',
                      Icons.clear,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildResultsStat(
                      context,
                      'Accuracy',
                      '${score.toStringAsFixed(0)}%',
                      Icons.sticky_note_2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Detailed Analysis
              if (_answerRecords.isNotEmpty) ...[
                _buildSectionHeader('Answer Details'),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _answerRecords.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final record = _answerRecords[index];
                    return ListTile(
                      leading: Icon(
                        record.isCorrect ? Icons.check : Icons.clear,
                        color: record.isCorrect ? Colors.green : Colors.red,
                      ),
                      title: Text('Question ${index + 1}'),
                      subtitle: Text(record.questionType.name),
                      trailing: Text(
                        record.isCorrect ? 'Correct' : 'Incorrect',
                        style: TextStyle(
                          color: record.isCorrect ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 32),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _restartSession,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Restart'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsStat(BuildContext context, String label, String value, IconData icon, {Color? color}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (color ?? theme.primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (color ?? theme.primaryColor).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color ?? theme.primaryColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color ?? theme.primaryColor,
            ),
          ),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

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
