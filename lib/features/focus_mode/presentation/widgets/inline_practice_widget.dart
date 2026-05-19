import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/services/answer_validation_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider;
import 'package:studyking/features/practice/services/mastery_recorder.dart';
import 'package:studyking/features/practice/data/models/practice_models.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_session_question_card.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_feedback_widget.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/widgets/widgets.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class InlinePracticeWidget extends ConsumerStatefulWidget {
  final String? subjectId;
  final String? topicId;
  final int questionCount;
  final void Function(int correct, int total, Map<String, SubjectAccuracy> perSubjectAccuracies) onComplete;

  const InlinePracticeWidget({
    super.key,
    this.subjectId,
    this.topicId,
    this.questionCount = 10,
    required this.onComplete,
  });

  @override
  ConsumerState<InlinePracticeWidget> createState() => _InlinePracticeWidgetState();
}

class SubjectAccuracy {
  final int correct;
  final int total;
  final double accuracyPercent;

  SubjectAccuracy({
    required this.correct,
    required this.total,
    required this.accuracyPercent,
  });
}

class _InlinePracticeWidgetState extends ConsumerState<InlinePracticeWidget> {
  final _logger = const Logger('InlinePracticeWidget');
  List<Question> _questions = [];
  int _currentIndex = 0;
  String? _currentAnswer;
  bool _isSubmitted = false;
  bool _isCorrect = false;
  bool _isLoading = true;
  bool _isComplete = false;
  int _correctCount = 0;
  final _perSubjectCorrect = <String, int>{};
  final _perSubjectTotal = <String, int>{};
  final _answerRecords = <PracticeAnswerRecord>[];
  late AnswerValidationService _validationService;
  late final MasteryRecorder _masteryRecorder;

  @override
  void initState() {
    super.initState();
    _masteryRecorder = ref.read(masteryRecorderProvider);
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final questionRepo = ref.read(questionRepositoryProvider);
      final allResult = await questionRepo.getAll();
      final all = allResult.data ?? [];

      var filtered = all.toList();
      if (widget.subjectId != null && widget.subjectId!.isNotEmpty) {
        filtered = filtered.where((q) => q.subjectId == widget.subjectId).toList();
      }
      if (widget.topicId != null && widget.topicId!.isNotEmpty) {
        filtered = filtered.where((q) => q.topicId == widget.topicId).toList();
      }

      filtered.shuffle();
      final selected = filtered.take(widget.questionCount).toList();

      if (mounted) {
        setState(() {
          _questions = selected;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.w('Failed to load questions for inline practice', e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _validationService = AnswerValidationService(
      messages: ValidationMessages.fromLocalizations(AppLocalizations.of(context)!),
    );
  }

  void _submitAnswer() {
    if (_currentAnswer == null || _currentAnswer!.isEmpty) return;

    final question = _questions[_currentIndex];
    final result = _validationService.validateAnswerForQuestion(question, _currentAnswer!);
    final isCorrect = result.isCorrect;

    setState(() {
      _isSubmitted = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) _correctCount++;

    final subjectId = question.subjectId;
    _perSubjectCorrect[subjectId] = (_perSubjectCorrect[subjectId] ?? 0) + (isCorrect ? 1 : 0);
    _perSubjectTotal[subjectId] = (_perSubjectTotal[subjectId] ?? 0) + 1;

    _answerRecords.add(PracticeAnswerRecord(
      questionId: question.id,
      questionType: question.type,
      userAnswer: _currentAnswer!,
      isCorrect: isCorrect,
      timeSpent: Duration.zero,
    ));
  }

  Future<void> _nextQuestion() async {
    if (_isSubmitted && _isCorrect) {
      try {
        final question = _questions[_currentIndex];
        await _masteryRecorder.recordAttempt(
          questionId: question.id,
          studentId: StudentIdService().getStudentId(),
          subjectId: question.subjectId,
          topicId: question.topicId,
          isCorrect: true,
          timeSpentMs: 0,
          confidence: 3,
          userAnswer: _currentAnswer ?? '',
        );
      } catch (_) {}
    }

    if (_currentIndex + 1 >= _questions.length) {
      _finish();
      return;
    }

    setState(() {
      _currentIndex++;
      _currentAnswer = null;
      _isSubmitted = false;
      _isCorrect = false;
    });
  }

  void _finish() {
    final perSubjectAccuracies = <String, SubjectAccuracy>{};
    for (final subjectId in _perSubjectTotal.keys) {
      final total = _perSubjectTotal[subjectId] ?? 0;
      final correct = _perSubjectCorrect[subjectId] ?? 0;
      perSubjectAccuracies[subjectId] = SubjectAccuracy(
        correct: correct,
        total: total,
        accuracyPercent: total > 0 ? (correct / total) * 100 : 0,
      );
    }

    setState(() => _isComplete = true);
    widget.onComplete(_correctCount, _questions.length, perSubjectAccuracies);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_isLoading) {
      return const LoadingIndicator();
    }

    if (_questions.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.quiz_outlined, size: 48, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(l10n.noQuestionsAvailable, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(l10n.addSubjectsAndQuestionsToStartPracticing,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (_isComplete) {
      final perSubjectAccuracies = _perSubjectAccuracies;
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(l10n.correctFeedback, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('${formatDecimal(_correctCount.toDouble(), l10n.localeName, minFractionDigits: 0)} / ${formatDecimal(_questions.length.toDouble(), l10n.localeName, minFractionDigits: 0)} ${l10n.correct.toLowerCase()}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _correctCount == _questions.length ? theme.colorScheme.primary : null,
                )),
              if (perSubjectAccuracies.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...perSubjectAccuracies.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${e.value.correct}/${e.value.total} (${formatPercent(e.value.accuracyPercent, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0)})',
                    style: theme.textTheme.bodyMedium),
                )),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {},
                child: Text(l10n.close),
              ),
            ],
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];
    final progress = '${_currentIndex + 1} / ${_questions.length}';

    return Column(
      children: [
        LinearProgressIndicator(
          value: (_currentIndex + 1) / _questions.length,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$_correctCount ${l10n.correct.toLowerCase()}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
            Text(progress, style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 12),
        PracticeSessionQuestionCard(
          question: question,
          currentAnswer: _currentAnswer,
          isSubmitted: _isSubmitted,
          isFeedbackVisible: _isSubmitted,
          onAnswerSelected: (answer) {
            if (!_isSubmitted) {
              setState(() => _currentAnswer = answer);
            }
          },
        ),
        const SizedBox(height: 12),
        if (_isSubmitted) ...[
          PracticeFeedbackWidget(
            isCorrect: _isCorrect,
            explanation: question.markscheme?.explanation,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _nextQuestion,
              icon: Icon(_currentIndex + 1 >= _questions.length ? Icons.check : Icons.arrow_forward),
              label: Text(_currentIndex + 1 >= _questions.length ? l10n.done : l10n.next),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _currentAnswer != null ? _submitAnswer : null,
              icon: const Icon(Icons.check),
              label: Text(l10n.submitAnswer),
            ),
          ),
        ],
      ],
    );
  }

  Map<String, SubjectAccuracy> get _perSubjectAccuracies {
    final result = <String, SubjectAccuracy>{};
    for (final subjectId in _perSubjectTotal.keys) {
      final total = _perSubjectTotal[subjectId] ?? 0;
      final correct = _perSubjectCorrect[subjectId] ?? 0;
      result[subjectId] = SubjectAccuracy(
        correct: correct,
        total: total,
        accuracyPercent: total > 0 ? (correct / total) * 100 : 0,
      );
    }
    return result;
  }
}
