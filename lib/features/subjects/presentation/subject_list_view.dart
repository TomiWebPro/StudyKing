import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/subjects/models/subject_model.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/features/subjects/presentation/subject_form_widgets.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'subject_selection_screen.dart';
import 'subject_detail_view.dart';

class SubjectListView extends ConsumerWidget {
  const SubjectListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final subjectsAsync = ref.watch(subjectsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mySubjects),
        actions: [
          Semantics(
            label: l10n.addSubject,
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubjectSelectionScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: subjectsAsync.when(
        data: (repository) => _buildSubjectList(context, ref, repository),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.errorWithMessage(error.toString()))),
      ),
    );
  }

  Widget _buildSubjectList(
      BuildContext context, WidgetRef ref, SubjectRepository repository) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<Subject>>(
      future: repository.getAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(l10n.errorWithMessage('${snapshot.error}')));
        }

        final subjects = snapshot.data ?? [];

        if (subjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: ResponsiveUtils.emptyStateIconSize(context),
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 1.5),
                Text(
                  l10n.noSubjectsYet,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
                Text(
                  l10n.addFirstSubject,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubjectSelectionScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addSubject),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: ResponsiveUtils.listPadding(context),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final subject = subjects[index];
            return _buildSubjectCard(context, subject);
          },
        );
      },
    );
  }

  Widget _buildSubjectCard(BuildContext context, Subject subject) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: subject.name,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubjectDetailScreen(
                  subjectId: subject.id,
                  subjectName: subject.name,
                  subjectColor: subject.color,
                  topicIds: [],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: ResponsiveUtils.cardPadding(context),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: SubjectColors.stringToColor(subject.color),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (subject.code != null)
                        Text(
                          subject.code!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.timer, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            l10n.practiceSessions,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}