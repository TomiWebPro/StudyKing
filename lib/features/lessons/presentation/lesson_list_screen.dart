import 'package:flutter/material.dart';
import '../../../core/data/models/lesson_model.dart';
import '../../../../main.dart' show database;
import '../../../l10n/generated/app_localizations.dart';
import 'lesson_detail_screen.dart';
import 'package:studyking/core/utils/responsive.dart';

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
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_lessons.isEmpty) {
      return Center(child: Text(l10n.noLessonsUsePlanner));
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.topicTitle)),
      body: ListView.builder(
        padding: ResponsiveUtils.listPadding(context),
        itemCount: _lessons.length,
        itemBuilder: (context, index) {
          final l = _lessons[index];
          return Semantics(
            label: l.title,
            child: Card(
            margin: EdgeInsets.only(bottom: ResponsiveUtils.verticalSpacing(context) * 0.75),
            child: ListTile(
              leading: const Icon(Icons.book),
              title: Text(l.title),
              subtitle: Text(l10n.blocksCount(l.blocks.length)),
              trailing: const Icon(Icons.play_arrow),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => LessonDetailScreen(lessonId: l.id, topicId: widget.topicId, topicTitle: widget.topicTitle),
              )),
            ),
          ),
          );
        },
      ),
    );
  }
}
