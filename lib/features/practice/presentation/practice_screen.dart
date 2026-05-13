import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/errors/handlers.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/subjects/models/subject_model.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/practice/presentation/practice_session_screen.dart';
import 'package:studyking/core/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/core/data/repositories/question_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';

/// Production Practice Screen - Shows practice modes and allows selecting subjects
class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  List<Subject> _subjects = [];
  bool _isLoading = true;
  Map<String, int> _dueCounts = {};
  bool _isLoadingDueCounts = false;
  late SpacedRepetitionRepository _srRepo;
  late QuestionRepository _questionRepo;

  @override
  void initState() {
    super.initState();
    _srRepo = ref.read(spacedRepetitionRepositoryProvider);
    _questionRepo = ref.read(questionRepositoryProvider);
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final subjects = await _fetchSubjects();
      if (mounted) {
        setState(() {
          _subjects = subjects;
          _isLoading = false;
        });
        _loadDueCounts();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppErrorHandler.handleError(
          context,
          e,
          'Subjects Load',
          retry: true,
          retryCallback: _retryLoadSubjects,
        );
      }
    }
  }

  Future<void> _retryLoadSubjects() => _loadSubjects();

  Future<void> _loadDueCounts() async {
    if (_subjects.isEmpty) return;
    
    setState(() => _isLoadingDueCounts = true);
    
    try {
      final dueCounts = <String, int>{};
      for (final subject in _subjects) {
        final result = await _srRepo.getSubjectDueCount(subject.id);
        if (result.isSuccess && result.data != null) {
          dueCounts[subject.id] = result.data!;
        } else {
          dueCounts[subject.id] = 0;
        }
      }
      if (mounted) {
        setState(() {
          _dueCounts = dueCounts;
          _isLoadingDueCounts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDueCounts = false);
      }
    }
  }

  Future<List<Subject>> _fetchSubjects() async {
    final repo = await ref.read(subjectsRepositoryProvider.future);
    return repo.getAll();
  }

  void _startPractice(Subject subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PracticeSessionScreen(
          subjectId: subject.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.practiceMode),
        actions: [
          if (_subjects.isNotEmpty)
            Semantics(
              label: AppLocalizations.of(context)!.practiceOptions,
              child: IconButton(
                icon: const Icon(Icons.tune),
                onPressed: () {
                  _showPracticeModeDialog();
                },
                tooltip: AppLocalizations.of(context)!.practiceOptions,
              ),
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _subjects.isEmpty
            ? null
            : () {
                if (_subjects.length == 1) {
                  _startPractice(_subjects.first);
                } else {
                  _showSubjectSelector();
                }
              },
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.play_arrow),
        label: Text(_subjects.isEmpty ? AppLocalizations.of(context)!.noSubjects : AppLocalizations.of(context)!.practice),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_subjects.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _loadSubjects,
      child: ListView(
        padding: ResponsiveUtils.listPadding(context),
        children: [
          _buildModeSection(context),
          const SizedBox(height: 24),
          _buildSubjectSection(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: ResponsiveUtils.screenPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_online_outlined,
              size: ResponsiveUtils.emptyStateIconSize(context),
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noPracticeSessionsYet,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.addSubjectsAndQuestionsToStartPracticing,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.addSubjectsFromSubjectsTab)),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.addSubject),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.practiceModes,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: ResponsiveUtils.gridCrossAxisCount(context).toInt(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2 / MediaQuery.textScalerOf(context).scale(1.0),
          children: [
            _PracticeModeCard(
              icon: Icons.flash_on,
              title: l10n.quickPractice,
              subtitle: l10n.randomQuestions(10),
              color: Colors.blue,
              onTap: () => _showPracticeModeDialog(),
            ),
            _PracticeModeCard(
              icon: Icons.schedule,
              title: l10n.spacedRepetition,
              subtitle: _isLoadingDueCounts 
                  ? l10n.comingSoon 
                  : _getSpacedRepetitionSubtitle(l10n),
              color: Colors.orange,
              onTap: _dueCounts.values.any((c) => c > 0) 
                  ? () => _showSpacedRepetitionSubjectSelector()
                  : null,
              badge: () {
                  final total = _dueCounts.values.fold(0, (a, b) => a + b);
                  return total > 0 ? total : null;
                }(),
            ),
            _PracticeModeCard(
              icon: Icons.category,
              title: l10n.topicFocus,
              subtitle: l10n.practiceSpecificTopics,
              color: Colors.purple,
              onTap: () => _showTopicSelector(),
            ),
            _PracticeModeCard(
              icon: Icons.bar_chart,
              title: l10n.weakAreas,
              subtitle: l10n.focusOnMistakes,
              color: Colors.red,
              onTap: _subjects.isNotEmpty ? () => _startWeakAreasPractice() : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubjectSection(BuildContext context) {
    if (_subjects.length == 1) {
      final subject = _subjects.first;
      return _buildSingleSubjectCard(context, subject);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.yourSubjects,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._subjects.map((subject) => _buildSubjectPracticeCard(context, subject)),
      ],
    );
  }

  Widget _buildSingleSubjectCard(BuildContext context, Subject subject) {
    return Card(
      child: InkWell(
        onTap: () => _startPractice(subject),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: ResponsiveUtils.cardPadding(context),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.school,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.readyForPractice,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectPracticeCard(BuildContext context, Subject subject) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _startPractice(subject),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: ResponsiveUtils.cardPadding(context),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getSubjectColor(subject.name).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.school,
                  color: _getSubjectColor(subject.name),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subject.code != null)
                      Text(
                        subject.code ?? '',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.quiz,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)!.practiceAvailable,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.play_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSubjectColor(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    return colors[name.codeUnits.fold(0, (h, c) => h * 31 + c) % colors.length];
  }

  void _showSubjectSelector() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Container(
        padding: ResponsiveUtils.screenPadding(sheetContext),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.selectSubject,
              style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._subjects.map((subject) => Semantics(
              label: '${l10n.selectSubject} ${subject.name}',
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getSubjectColor(subject.name).withValues(alpha: 0.1),
                  child: Icon(
                    Icons.school,
                    color: _getSubjectColor(subject.name),
                  ),
                ),
                title: Text(subject.name),
                subtitle: subject.code != null ? Text(subject.code ?? '') : null,
                onTap: () {
                  Navigator.pop(context);
                  _startPractice(subject);
                },
              ),
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPracticeModeDialog() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Container(
        padding: ResponsiveUtils.screenPadding(sheetContext),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.practiceModeTitle,
              style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_subjects.length == 1)
              _PracticeModeOption(
                icon: Icons.auto_fix_high,
                title: l10n.autoSelect,
                subtitle: l10n.aiPicksOptimalQuestions,
                onTap: () {
                  Navigator.pop(context);
                  _startPractice(_subjects.first);
                },
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.chooseSubject,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._subjects.map((subject) => _PracticeModeOption(
                    icon: Icons.school,
                    title: subject.name,
                    subtitle: subject.code ?? l10n.noCode,
                    onTap: () {
                      Navigator.pop(context);
                      _startPractice(subject);
                    },
                  )),
                ],
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showTopicSelector() async {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      final result = await _questionRepo.getAll();
      if (result.isFailure || result.data == null || result.data!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noTopicsAvailable)),
          );
        }
        return;
      }

      final questions = result.data!;
      final topics = questions
          .where((q) => q.topic != null && q.topic!.isNotEmpty)
          .map((q) => q.topic!)
          .toSet()
          .toList();

      if (topics.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noTopicsAvailable)),
          );
        }
        return;
      }

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) => Container(
          padding: ResponsiveUtils.screenPadding(sheetContext),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.selectTopic,
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...topics.map((topic) => Semantics(
                label: '${l10n.selectTopic} $topic',
                child: ListTile(
                  leading: const Icon(Icons.topic),
                  title: Text(topic),
                  onTap: () {
                    Navigator.pop(context);
                    _startTopicPractice(topic);
                  },
                ),
              )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noTopicsAvailable)),
        );
      }
    }
  }

  void _startTopicPractice(String topic) async {
    try {
      final result = await _questionRepo.getAll();
      if (result.isFailure || result.data == null) return;

      final topicQuestions = result.data!
          .where((q) => q.topic == topic)
          .toList();

      if (topicQuestions.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.noQuestionsAvailable)),
        );
        return;
      }

      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PracticeSessionScreen(
            subjectId: topicQuestions.first.subjectId,
            topicId: topicQuestions.first.topicId,
            questionCount: topicQuestions.length,
          ),
        ),
      );
    } catch (e) {
      // Handle error silently
    }
  }

  String _getSpacedRepetitionSubtitle(AppLocalizations l10n) {
    final totalDue = _dueCounts.values.fold(0, (a, b) => a + b);
    if (totalDue == 0) {
      return l10n.noReviewsScheduled;
    }
    return l10n.dueQuestionsCount(totalDue);
  }

  void _showSpacedRepetitionSubjectSelector() {
    final l10n = AppLocalizations.of(context)!;
    
    final subjectsWithDue = _subjects
        .where((s) => (_dueCounts[s.id] ?? 0) > 0)
        .toList();

    if (subjectsWithDue.isEmpty) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) => Container(
          padding: ResponsiveUtils.screenPadding(sheetContext),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 64,
                color: Colors.green.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.allCaughtUp,
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.noReviewsScheduled,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Container(
        padding: ResponsiveUtils.screenPadding(sheetContext),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.selectSubject,
              style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...subjectsWithDue.map((subject) => Semantics(
              label: '${l10n.selectSubject} ${subject.name}',
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getSubjectColor(subject.name).withValues(alpha: 0.1),
                  child: Icon(
                    Icons.school,
                    color: _getSubjectColor(subject.name),
                  ),
                ),
                title: Text(subject.name),
                subtitle: Text(l10n.dueQuestionsCount(_dueCounts[subject.id] ?? 0)),
                onTap: () {
                  Navigator.pop(context);
                  _startSpacedRepetitionSession(subject);
                },
              ),
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _startWeakAreasPractice() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final masteryService = MasteryGraphService();
      await masteryService.init();

      if (_subjects.isEmpty) return;

      if (_subjects.length == 1) {
        await _launchWeakAreasForSubject(masteryService, _subjects.first, l10n);
        return;
      }

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) => Container(
          padding: ResponsiveUtils.screenPadding(sheetContext),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.selectSubject,
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._subjects.map((subject) => Semantics(
                label: '${l10n.selectSubject} ${subject.name}',
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getSubjectColor(subject.name).withValues(alpha: 0.1),
                    child: Icon(Icons.school, color: _getSubjectColor(subject.name)),
                  ),
                  title: Text(subject.name),
                  onTap: () {
                    Navigator.pop(context);
                    _launchWeakAreasForSubject(masteryService, subject, l10n);
                  },
                ),
              )),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noWeakAreasFound)),
        );
      }
    }
  }

  Future<void> _launchWeakAreasForSubject(
    MasteryGraphService masteryService,
    Subject subject,
    AppLocalizations l10n,
  ) async {
    try {
      final weakTopicsResult = await masteryService.getWeakTopics('anonymous');
      if (weakTopicsResult.isFailure || weakTopicsResult.data == null || weakTopicsResult.data!.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noWeakAreasFound)),
        );
        return;
      }

      final weakTopicIds = weakTopicsResult.data!.map((s) => s.topicId).toSet();

      final questionsResult = await _questionRepo.getAll();
      if (questionsResult.isFailure || questionsResult.data == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noQuestionsAvailable)),
        );
        return;
      }

      final weakQuestions = questionsResult.data!
          .where((q) => weakTopicIds.contains(q.topicId))
          .toList();

      if (weakQuestions.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noWeakAreasQuestions)),
        );
        return;
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PracticeSessionScreen(
            subjectId: subject.id,
            questionCount: weakQuestions.length,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noWeakAreasFound)),
        );
      }
    }
  }

  void _startSpacedRepetitionSession(Subject subject) async {
    try {
      final result = await _srRepo.getPracticeQuestions(subject.id);
      
      if (result.isFailure || result.data == null || result.data!.isEmpty) {
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (sheetContext) => Container(
            padding: ResponsiveUtils.screenPadding(sheetContext),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.green.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.allCaughtUp,
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.noReviewsScheduled,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
        return;
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PracticeSessionScreen(
            subjectId: subject.id,
            questionCount: result.data!.length,
            isSpacedRepetition: true,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.noQuestionsAvailable)),
        );
      }
    }
  }
}

class _PracticeModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final int? badge;

  const _PracticeModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = onTap != null;
    return Card(
      child: Semantics(
        label: '$title, $subtitle',
        child: InkWell(
          onTap: isAvailable ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isAvailable ? color.withValues(alpha: 0.1) : Colors.grey.shade100,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: isAvailable ? color : Colors.grey.shade400,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isAvailable ? color : Colors.grey.shade400,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isAvailable ? color : Colors.grey.shade400,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (badge != null && badge! > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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
}

class _PracticeModeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _PracticeModeOption({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
