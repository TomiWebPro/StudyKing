import 'package:flutter/material.dart';
import '../../../core/data/models/lesson_model.dart';
import '../../../../main.dart' show database;
import 'lesson_detail_screen.dart';

class LessonListScreen extends StatefulWidget {
  final String topicId;
  final String topicTitle;
  const LessonListScreen({super.key, required this.topicId, required this.topicTitle});

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  List<Lesson> _lessons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    try {
      final all = await database.lessonRepository.getAll();
      setState(() {
        _lessons = all.where((l) => l.topicId == widget.topicId).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_lessons.isEmpty) {
      return const Center(child: Text('No lessons - use Planner to generate!'));
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.topicTitle)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _lessons.length,
        itemBuilder: (context, index) {
          final l = _lessons[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.book),
              title: Text(l.title),
              subtitle: Text('${l.blocks.length} blocks'),
              trailing: const Icon(Icons.play_arrow),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => LessonDetailScreen(lessonId: l.id, topicId: widget.topicId, topicTitle: widget.topicTitle),
              )),
            ),
          );
        },
      ),
    );
  }
}
