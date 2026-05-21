import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/errors/handlers.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/widgets/widgets.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';

class TopicListScreen extends ConsumerStatefulWidget {
  const TopicListScreen({super.key});

  @override
  ConsumerState<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends ConsumerState<TopicListScreen> {
  List<Topic> _topics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    try {
      final repo = ref.read(topicRepositoryProvider);
      final topicsResult = await repo.getAll();
      final topics = topicsResult.data ?? [];
      if (!mounted) return;
      setState(() {
        _topics = topics;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppErrorHandler.handleError(
          context,
          e,
          'Topic Load',
          retry: true,
          retryCallback: _retryLoadTopics,
        );
      }
    }
  }

  Future<void> _retryLoadTopics() => _loadTopics();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.topics)),
        body: const LoadingIndicator(),
      );
    }
    if (_topics.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.folder_off,
        title: l10n.noTopicsYetAddSome,
        actionLabel: l10n.addTopic,
        onAction: () => Navigator.pushNamed(context, AppRoutes.subjectSelection),
      );
    }
    return ListView.builder(
      padding: ResponsiveUtils.listPadding(context),
      itemCount: _topics.length,
      itemBuilder: (context, index) {
        final t = _topics[index];
        return Semantics(
          label: '${l10n.topicTitleLabel}: ${t.title}, ${l10n.topicDescriptionLabel}: ${t.description}',
          button: true,
          child: Card(
            margin: EdgeInsets.only(
              bottom: ResponsiveUtils.verticalSpacing(context) * 0.75,
            ),
            child: ListTile(
              leading: Icon(Icons.folder, color: Theme.of(context).colorScheme.primary),
              title: Text(t.title),
              subtitle: Text(t.description),
              trailing: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.lessonList,
              arguments: LessonListArgs(
                  topicId: t.id, topicTitle: t.title, subjectId: t.subjectId),
              ),
            ),
          ),
        );
      },
    );
  }
}
