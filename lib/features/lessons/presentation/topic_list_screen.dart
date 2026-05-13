import 'package:flutter/material.dart';
import 'package:studyking/core/errors/handlers.dart';
import '../../../core/data/models/topic_model.dart';
import '../../../main.dart' show database;
import '../../../l10n/generated/app_localizations.dart';
import 'lesson_list_screen.dart';
import 'package:studyking/core/utils/responsive.dart';

class TopicListScreen extends StatefulWidget {
  const TopicListScreen({super.key});

  @override
  State<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends State<TopicListScreen> {
  List<Topic> _topics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    try {
      final topics = await database.topicRepository.getAll();
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
            label: t.title,
            child: Card(
            margin: EdgeInsets.only(bottom: ResponsiveUtils.verticalSpacing(context) * 0.75),
          child: ListTile(
            leading: const Icon(Icons.folder, color: Colors.blue),
            title: Text(t.title),
            subtitle: Text(t.description),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => LessonListScreen(topicId: t.id, topicTitle: t.title),
            )),
          ),
        ),
        );
      },
    );
  }
}
