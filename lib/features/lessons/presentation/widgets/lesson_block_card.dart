import 'package:flutter/material.dart';
import '../../../../core/data/enums.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/core/utils/string_extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';

class LessonBlockCard extends StatefulWidget {
  final LessonBlock block;
  final VoidCallback? onStartTutor;
  final List<LessonBlock>? allBlocks;
  final int? blockIndex;

  const LessonBlockCard({
    super.key,
    required this.block,
    this.onStartTutor,
    this.allBlocks,
    this.blockIndex,
  });

  @override
  State<LessonBlockCard> createState() => _LessonBlockCardState();
}

class _LessonBlockCardState extends State<LessonBlockCard> {
  String _quizAnswer = '';
  bool _quizSubmitted = false;
  bool _quizCorrect = false;
  String _exerciseAnswer = '';
  bool _exerciseSubmitted = false;

  @override
  Widget build(BuildContext context) {
    switch (widget.block.type) {
      case LessonBlockType.slide:
        return _buildSlideCard(context);
      case LessonBlockType.quiz:
        return _buildQuizCard(context);
      case LessonBlockType.exercise:
        return _buildExerciseCard(context);
      case LessonBlockType.example:
        return _buildExampleCard(context);
      case LessonBlockType.summary:
        return _buildSummaryCard(context);
      case LessonBlockType.text:
        return _buildTextCard(context);
    }
  }

  Widget _buildSlideCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: () => _showSlideFullScreenDialog(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primaryContainer, cs.secondaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.slideshow, size: 48, color: cs.onPrimaryContainer),
                    const SizedBox(height: 16),
                    Text(
                      widget.block.content,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fullscreen, size: 16, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.blockTypeSlide,
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSlideFullScreenDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final blocks = widget.allBlocks ?? [widget.block];
    final startIndex = widget.blockIndex ?? 0;
    final pageController = PageController(initialPage: startIndex);

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (ctx, animation, secondaryAnimation) => Scaffold(
          appBar: AppBar(
            title: Text(l10n.blockTypeSlide),
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: l10n.close,
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: pageController,
                  itemCount: blocks.length,
                  itemBuilder: (context, i) {
                    final block = blocks[i];
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          Text(
                            l10n.pageIndicator(i + 1, blocks.length),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            block.content,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (blocks.length > 1)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_right : Icons.chevron_left),
                          onPressed: () {
                            final current = pageController.page?.round() ?? 0;
                            if (current > 0) {
                              pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        ListenableBuilder(
                          listenable: pageController,
                          builder: (context, _) {
                            final current = (pageController.page?.round() ?? 0) + 1;
                            return Text(
                              l10n.pageIndicator(current, blocks.length),
                              style: Theme.of(context).textTheme.bodyMedium,
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right),
                          onPressed: () {
                            final current = pageController.page?.round() ?? 0;
                            if (current < blocks.length - 1) {
                              pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cs = theme.colorScheme;
    final isShortAnswer = !widget.block.content.contains('\n?');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.quiz, color: cs.tertiary),
                const SizedBox(width: 8),
                Text(
                  l10n.blockTypeQuiz,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.block.content,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            if (!_quizSubmitted) ...[
              if (isShortAnswer)
                TextField(
                  decoration: InputDecoration(
                    hintText: l10n.yourAnswer,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _quizAnswer = v),
                )
              else
                ..._buildQuizOptions(context),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _quizAnswer.isEmpty ? null : _submitQuiz,
                child: Text(l10n.submitAnswer),
              ),
            ] else ...[
              Icon(
                _quizCorrect ? Icons.check_circle : Icons.cancel,
                color: _quizCorrect ? cs.primary : cs.error,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                _quizCorrect ? l10n.correct : l10n.incorrectAnswer,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: _quizCorrect ? cs.primary : cs.error,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.onStartTutor != null)
                OutlinedButton.icon(
                  onPressed: widget.onStartTutor,
                  icon: const Icon(Icons.smart_toy, size: 16),
                  label: Text(l10n.aiTutor),
                ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQuizOptions(BuildContext context) {
    final lines = widget.block.content.split('\n');
    final options = lines.where((l) => l.trim().startsWith('-')).toList();
    if (options.isEmpty) return [];

    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((opt) {
          final clean = opt.replaceFirst(RegExp(r'^-\s*'), '');
          final selected = _quizAnswer == clean;
          return ChoiceChip(
            label: Text(clean),
            selected: selected,
            onSelected: (v) => setState(() => _quizAnswer = v ? clean : ''),
          );
        }).toList(),
      ),
    ];
  }

  void _submitQuiz() {
    final answer = _quizAnswer.trim();
    final answerKey = widget.block.answerKey;
    bool correct;
    if (answerKey.isNotEmpty) {
      final keys = answerKey.split('||').map((k) => k.normalized);
      correct = keys.any((k) => answer.normalized == k);
    } else {
      final content = widget.block.content.normalized;
      final ansLower = answer.normalized;
      final idx = content.indexOf('answer:');
      correct = idx >= 0 && content.substring(idx).contains(ansLower);
    }
    setState(() {
      _quizSubmitted = true;
      _quizCorrect = correct;
    });
  }

  Widget _buildExerciseCard(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: cs.secondary),
                const SizedBox(width: 8),
                Text(
                  l10n.blockTypeExercise,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.block.content,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            if (!_exerciseSubmitted) ...[
              TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: l10n.yourAnswer,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                onChanged: (v) => setState(() => _exerciseAnswer = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton(
                    onPressed: _exerciseAnswer.isEmpty ? null : _submitExercise,
                    child: Text(l10n.submitAnswer),
                  ),
                  const SizedBox(width: 12),
                  if (widget.onStartTutor != null)
                    OutlinedButton.icon(
                      onPressed: widget.onStartTutor,
                      icon: const Icon(Icons.smart_toy, size: 16),
                      label: Text(l10n.aiTutor),
                    ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.yourAnswer, style: theme.textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(_exerciseAnswer, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _submitExercise() {
    setState(() => _exerciseSubmitted = true);
  }

  Widget _buildExampleCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      color: cs.tertiaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: cs.tertiary, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.blockTypeExample,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onTertiaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.block.content,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: cs.onTertiaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      color: cs.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.checklist, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.blockTypeSummary,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.block.content,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: cs.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.blockTypeExplanation,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(widget.block.content, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
