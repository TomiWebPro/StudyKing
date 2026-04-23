import 'package:flutter/material.dart';
import '../../../core/data/models/topic_model.dart';
import '../../../../main.dart' show database;
import 'lesson_list_screen.dart';

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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_topics.isEmpty) {
      return const Center(child: Text('No topics yet - add some!'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _topics.length,
      itemBuilder: (context, index) {
        final t = _topics[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.folder, color: Colors.blue),
            title: Text(t.title),
            subtitle: Text(t.description),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => LessonListScreen(topicId: t.id, topicTitle: t.title),
            )),
          ),
        );
      },
    );
  }
}
