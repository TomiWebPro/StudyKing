import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/utils/color_utils.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/features/subjects/data/curriculum_seed_data.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/features/subjects/presentation/subject_form_widgets.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class SubjectSelectionScreen extends ConsumerStatefulWidget {
  final Subject? editingSubject;

  const SubjectSelectionScreen({super.key, this.editingSubject});

  bool get isEditing => editingSubject != null;

  @override
  ConsumerState<SubjectSelectionScreen> createState() =>
      _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState
    extends ConsumerState<SubjectSelectionScreen> {
  static final Logger _logger = const Logger('SubjectSelectionScreen');
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _teacherController = TextEditingController();
  final _syllabusController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  String _selectedColor = ColorUtils.defaultColorHex;

  @override
  void initState() {
    super.initState();
    final subject = widget.editingSubject;
    if (subject != null) {
      _nameController.text = subject.name;
      _codeController.text = subject.code ?? '';
      _teacherController.text = subject.teacher ?? '';
      _syllabusController.text = subject.syllabus ?? '';
      _descriptionController.text = subject.description ?? '';
      _selectedColor = subject.color;
    } else {
      _selectedColor = ColorUtils.defaultColorHex;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _teacherController.dispose();
    _syllabusController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveSubject() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final subject = Subject(
        id: widget.isEditing
            ? widget.editingSubject!.id
            : 'subject_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        code: _codeController.text.trim().isEmpty
            ? null
            : _codeController.text.trim().toUpperCase(),
        teacher: _teacherController.text.trim().isEmpty
            ? null
            : _teacherController.text.trim(),
        syllabus: _syllabusController.text.trim().isEmpty
            ? null
            : _syllabusController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        color: _selectedColor,
        topicIds: widget.isEditing ? widget.editingSubject!.topicIds : null,
        createdAt: widget.isEditing ? widget.editingSubject!.createdAt : null,
      );

      final repo = await ref.read(subjectsRepositoryProvider.future);
      await repo.create(subject);

      final seedEntry = !widget.isEditing
          ? findSeedEntry(_nameController.text.trim())
          : null;
      if (seedEntry != null && mounted) {
        try {
          final topicRepo = TopicRepository();
          await topicRepo.init();
          final createdTopicIds = <String>[];
          for (final seedTopic in seedEntry.topics) {
            final topicId = 'topic_${DateTime.now().millisecondsSinceEpoch}_${createdTopicIds.length}';
            final topic = Topic(
              id: topicId,
              subjectId: subject.id,
              title: seedTopic.title,
              description: seedTopic.description,
              syllabusText: seedTopic.syllabusText,
              sortOrder: seedTopic.sortOrder,
            );
            await topicRepo.create(topic);
            createdTopicIds.add(topicId);

            for (var i = 0; i < seedTopic.subtopics.length; i++) {
              final sub = seedTopic.subtopics[i];
              final subId = 'topic_${DateTime.now().millisecondsSinceEpoch}_${createdTopicIds.length}';
              final subtopic = Topic(
                id: subId,
                subjectId: subject.id,
                title: sub.title,
                description: sub.description,
                syllabusText: sub.syllabusText,
                sortOrder: sub.sortOrder,
                parentId: topicId,
              );
              await topicRepo.create(subtopic);
              createdTopicIds.add(subId);
            }
          }
          final updatedSubject = subject.copyWith(topicIds: createdTopicIds);
          await repo.put(updatedSubject.id, updatedSubject);
          if (mounted) {
            await _showTopicsCreatedDialog(context, l10n, seedEntry.topics, subject.id, subjectName: subject.name);
          }
        } catch (e) {
          _logger.w('Failed to auto-create seed topics', e);
        }
      }

      if (widget.isEditing) {
        if (!mounted) return;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.editSubject)),
        );
        return;
      }

      if (!mounted) return;
      final l10nCtx = AppLocalizations.of(context)!;
      final subjectName = subject.name;
      final settingsBox = await Hive.openBox(HiveBoxNames.settings);
      if (!mounted) return;
      final apiKey = settingsBox.get('apiKey', defaultValue: '') as String;
      final hasApiKey = apiKey.isNotEmpty;

      if (!hasApiKey) {
        if (!mounted) return;
        final goToConfig = await showDialog<bool>(
          context: context,
          builder: (ctx2) => AlertDialog(
            title: Text(l10nCtx.apiKeyRequiredForUploadTitle),
            content: Text(l10nCtx.apiKeyRequiredForUpload),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx2, false),
                child: Text(l10nCtx.maybeLater),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx2, true),
                child: Text(l10nCtx.configureApiKey),
              ),
            ],
          ),
        );

        if (mounted) {
          Navigator.pop(context, true);
          if (goToConfig == true) {
            Navigator.pushNamed(context, AppRoutes.apiConfig);
          }
        }
        return;
      }

      if (!mounted) return;
      final shouldUpload = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10nCtx.subjectCreatedSuccessfully),
          content: Text(l10nCtx.uploadPrompt(subjectName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10nCtx.noThanks),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10nCtx.uploadMaterial),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.pop(context, true);
        if (shouldUpload == true) {
          Navigator.pushNamed(
            context,
            AppRoutes.upload,
            arguments: subject.id,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _logger.w('Save subject failed', e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorSavingSubject(l10n.somethingWentWrong))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showTopicsCreatedDialog(BuildContext context, AppLocalizations l10n, List<SeedTopic> topics, String subjectId, {String? subjectName}) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary, size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.topicsCreatedTitle)),
          ],
        ),
        content: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.topicsCreatedDescription),
              const SizedBox(height: 16),
              ...topics.map((topic) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.folder, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(topic.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (topic.subtopics.isNotEmpty)
                            Text(
                              l10n.topicSubtopicsCount(topic.subtopics.length),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              Text(
                l10n.curriculumBasedTopics,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.ok),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(
                context,
                AppRoutes.subjectDetail,
                arguments: Subject(id: subjectId, name: subjectName ?? ''),
              );
            },
            child: Text(l10n.reviewAndEdit),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? l10n.editSubject : l10n.addSubject),
        actions: [
          if (_isLoading)
            Semantics(
              label: l10n.loading,
              liveRegion: true,
              child: ResponsiveUtils.loaderInTouchTarget(),
            )
          else
            Semantics(
              label: l10n.save,
              button: true,
              child: TextButton(
                onPressed: _saveSubject,
                child: Text(l10n.save),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.screenPadding(context),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SubjectFormFields(
              formKey: _formKey,
              nameController: _nameController,
              codeController: _codeController,
              teacherController: _teacherController,
              syllabusController: _syllabusController,
              descriptionController: _descriptionController,
            ),
            const SizedBox(height: 24),
            SubjectColorSelector(
              selectedColor: _selectedColor,
              onColorSelected: (color) {
                setState(() => _selectedColor = color);
              },
            ),
          ],
        ),
      ),
    );
  }
}
