import 'package:flutter/material.dart';
import 'package:studyking/core/data/models/lesson_model.dart';
import 'package:studyking/core/data/repositories/lesson_repository.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class SubjectLessonsTab extends StatelessWidget {
  final String subjectId;
  final LessonRepository? lessonRepository;

  const SubjectLessonsTab({
    super.key,
    required this.subjectId,
    this.lessonRepository,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lessonRepo = lessonRepository ?? LessonRepository();

    Future<List<Lesson>> loadLessons() async {
      try {
        final lessons = await lessonRepo.getAll();
        return lessons.where((l) => l.subjectId == subjectId).toList();
      } catch (e) {
        return [];
      }
    }

    return FutureBuilder<List<Lesson>>(
      future: loadLessons(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final subjectLessons = snapshot.data ?? [];

        if (subjectLessons.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book_outlined, size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Text(
                  l10n.noLessonsYet,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.startLearningByCreatingTopics,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: subjectLessons.length,
          itemBuilder: (context, index) {
            final lesson = subjectLessons[index];
            return Card(
              margin: EdgeInsets.only(bottom: ResponsiveUtils.verticalSpacing(context) * 0.75),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Icon(Icons.book, color: Theme.of(context).primaryColor),
                ),
                title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  l10n.blocksCount(lesson.blocks.length),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.lessonDetail,
                  arguments: LessonDetailArgs(
                    lessonId: lesson.id,
                    topicId: lesson.topicId,
                    topicTitle: lesson.title,
                    subjectId: subjectId,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
