import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/utils/color_utils.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/features/subjects/data/curriculum_seed_data.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.topicsAutoCreated(seedEntry.topics.length),
                ),
              ),
            );
          }
        } catch (e) {
          const Logger('SubjectSelectionScreen').w('Failed to auto-create seed topics', e);
        }
      }

      if (mounted) {
        if (widget.isEditing) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.editSubject)),
          );
          return;
        }

        final l10nCtx = AppLocalizations.of(context)!;
        final subjectName = subject.name;
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorSavingSubject(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? l10n.editSubject : l10n.addSubject),
        actions: [
          if (_isLoading)
            ResponsiveUtils.loaderInTouchTarget()
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
