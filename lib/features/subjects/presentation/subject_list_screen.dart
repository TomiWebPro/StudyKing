import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/core/utils/color_utils.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/widgets/widgets.dart';

class SubjectListScreen extends ConsumerWidget {
  static final Logger _logger = const Logger('SubjectListScreen');
  const SubjectListScreen({super.key});

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
              tooltip: l10n.addSubject,
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.subjectSelection);
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(subjectsRepositoryProvider);
        },
        child: subjectsAsync.when(
          data: (repository) => _buildSubjectList(context, ref, repository),
          loading: () => const Center(child: LoadingIndicator()),
          error: (error, stack) {
            _logger.w('Error loading subjects', error, stack);
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: ErrorRetryWidget(
                  message: l10n.somethingWentWrong,
                  retryLabel: l10n.retry,
                  onRetry: () => ref.invalidate(subjectsRepositoryProvider),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubjectList(
      BuildContext context, WidgetRef ref, SubjectRepository repository) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<Subject>>(
      future: repository.getAll().then((r) => r.data ?? []),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        if (snapshot.hasError) {
          _logger.w('Error in subject list builder', snapshot.error);
          return ErrorRetryWidget(
            message: l10n.somethingWentWrong,
            retryLabel: l10n.retry,
            onRetry: () => ref.invalidate(subjectsRepositoryProvider),
          );
        }

        final subjects = snapshot.data ?? [];

        if (subjects.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.school_outlined,
            title: l10n.noSubjectsYet,
            subtitle: l10n.addFirstSubject,
            actionLabel: l10n.addSubject,
            onAction: () => Navigator.pushNamed(context, AppRoutes.subjectSelection),
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
      button: true,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.subjectDetail,
              arguments: subject,
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
                    color: ColorUtils.stringToColor(subject.color),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    subject.icon,
                    color: ColorUtils.contrastingTextColor(ColorUtils.stringToColor(subject.color)),
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
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.timer, size: 14),
                          const SizedBox(width: 4),
                          FutureBuilder<int>(
                            future: SessionRepository().getBySubject(subject.id).then(
                              (r) => (r.data ?? []).length,
                            ).catchError((_) => 0),
                            builder: (context, snapshot) {
                              final count = snapshot.data ?? 0;
                              return Text(
                                count > 0
                                    ? l10n.sessionsCount(count)
                                    : l10n.practiceSessions,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}