import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/services/answer_validation_service.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_type.dart';
import 'package:studyking/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/practice/services/mastery_recorder.dart';
import 'package:studyking/features/practice/data/models/practice_models.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_session_question_card.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_feedback_widget.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/string_extensions.dart';
import 'package:studyking/core/widgets/widgets.dart';
import 'package:studyking/core/providers/service_providers.dart' show studentIdValueProvider;
import 'package:studyking/l10n/generated/app_localizations.dart';

class InlinePracticeWidget extends ConsumerStatefulWidget {
  final String? subjectId;
  final String? topicId;
  final int questionCount;
  final FocusSessionType sessionType;
  final void Function(int correct, int total, Map<String, SubjectAccuracy> perSubjectAccuracies) onComplete;

  const InlinePracticeWidget({
    super.key,
    this.subjectId,
    this.topicId,
    this.questionCount = 10,
    this.sessionType = FocusSessionType.spacedRepetition,
    required this.onComplete,
  });

  bool get isQuickPractice => sessionType == FocusSessionType.quickPractice;

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
  static final Logger _logger = const Logger('InlinePracticeWidget');
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
      final studentId = ref.read(studentIdValueProvider);
      final focusPracticeService = ref.read(focusPracticeServiceProvider);
      final subjectIds = widget.subjectId != null && widget.subjectId!.isNotEmpty
          ? [widget.subjectId!]
          : null;

      final questions = await focusPracticeService.getQuestionsForSessionType(
        sessionType: widget.sessionType,
        studentId: studentId,
        subjectIds: subjectIds,
        limit: widget.questionCount,
      );

      var selected = questions.toList();
      if (widget.topicId != null && widget.topicId!.isNotEmpty) {
        selected = selected.where((q) => q.topicId == widget.topicId).toList();
      }

      if (selected.isEmpty && widget.sessionType == FocusSessionType.weakAreaAttack) {
        final srService = ref.read(spacedRepetitionServiceProvider);
        final dueResult = await srService.getQuestionsDueForReview();
        var fallback = dueResult.data ?? [];
        if (widget.subjectId != null && widget.subjectId!.isNotEmpty) {
          fallback = fallback.where((q) => q.subjectId == widget.subjectId).toList();
        }
        fallback.shuffle();
        selected = fallback.take(widget.questionCount).toList();
      }

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
    try {
      final question = _questions[_currentIndex];
      final studentId = ref.read(studentIdValueProvider);
      await _masteryRecorder.recordAttempt(
        questionId: question.id,
        studentId: studentId,
        subjectId: question.subjectId,
        topicId: question.topicId,
        isCorrect: _isCorrect,
        timeSpentMs: 0,
        confidence: _isCorrect ? 4 : 2,
        userAnswer: _currentAnswer ?? '',
      );
    } catch (e) {
      _logger.w('Failed to record attempt in inline practice', e);
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
    setState(() => _isComplete = true);
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
              Text('${formatDecimal(_correctCount.toDouble(), l10n.localeName, minFractionDigits: 0)} / ${formatDecimal(_questions.length.toDouble(), l10n.localeName, minFractionDigits: 0)} ${l10n.correct.normalized}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _correctCount == _questions.length ? theme.colorScheme.primary : null,
                )),
              if (perSubjectAccuracies.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...perSubjectAccuracies.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${formatDecimal(e.value.correct.toDouble(), l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0)}/${formatDecimal(e.value.total.toDouble(), l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0)} (${formatPercent(e.value.accuracyPercent, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0)})',
                    style: theme.textTheme.bodyMedium),
                )),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => widget.onComplete(_correctCount, _questions.length, _perSubjectAccuracies),
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
            Text('$_correctCount ${l10n.correct.normalized}',
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
