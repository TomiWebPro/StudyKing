import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/handlers.dart';
import '../../../core/data/models/topic_model.dart';
import '../../../core/routes/app_router.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/utils/responsive.dart';
import '../../subjects/providers/topic_repository_provider.dart';

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
      final topics = await repo.getAll();
      if (!mounted) return;
      setState(() {
        _topics = topics;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_topics.isEmpty) {
      return Center(child: Text(l10n.noTopicsYetAddSome));
    }
    return ListView.builder(
      padding: ResponsiveUtils.listPadding(context),
      itemCount: _topics.length,
      itemBuilder: (context, index) {
        final t = _topics[index];
        return Semantics(
          label: '${t.title}, ${t.description}',
          button: true,
          child: Card(
            margin: EdgeInsets.only(
              bottom: ResponsiveUtils.verticalSpacing(context) * 0.75,
            ),
            child: ListTile(
              leading: Icon(Icons.folder, color: Theme.of(context).colorScheme.primary),
              title: Text(t.title),
              subtitle: Text(t.description),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.lessonList,
                arguments: LessonListArgs(
                    topicId: t.id, topicTitle: t.title),
              ),
            ),
          ),
        );
      },
    );
  }
}
