import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/data/repositories/topic_repository.dart';
import '../../../features/subjects/data/repositories/subject_repository.dart';
import '../../../core/services/llm/llm_chat_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';
import '../../teaching/presentation/tutor_screen.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  bool _isGenerating = false;
  List<_ScheduleItem> _schedule = [];
  String? _selectedSubjectId;

  Future<List<Map<String, String>>> _fetchCurriculumTopics(
      String courseName) async {
    try {
      final subjectRepo = SubjectRepository();
      final topicRepo = TopicRepository();
      await subjectRepo.init();
      await topicRepo.init();

      final subjects = await subjectRepo.getAll();
      final matchingSubjects = subjects.where((s) =>
          s.name.toLowerCase().contains(courseName.toLowerCase()) ||
          (s.code?.toLowerCase().contains(courseName.toLowerCase()) ?? false));

      final results = <Map<String, String>>[];
      for (final subject in matchingSubjects) {
        _selectedSubjectId ??= subject.id;
        final subjectTopics = await topicRepo.getBySubject(subject.id);
        for (final topic in subjectTopics) {
          results.add({
            'id': topic.id,
            'title': topic.title,
            'subjectId': subject.id,
          });
          if (results.length >= 7) break;
        }
        if (results.length >= 7) break;
      }

      if (results.isEmpty) {
        final allTopics = await topicRepo.getAll();
        for (final topic in allTopics) {
          results.add({
            'id': topic.id,
            'title': topic.title,
            'subjectId': '',
          });
          if (results.length >= 7) break;
        }
      }

      return results;
    } catch (_) {
      return [];
    }
  }

  Future<void> _generatePlan() async {
    final course = _courseController.text.trim();
    final daysValue = int.tryParse(_daysController.text);
    final hoursValue = int.tryParse(_hoursController.text);

    if (course.isEmpty ||
        daysValue == null ||
        hoursValue == null ||
        daysValue <= 0 ||
        hoursValue <= 0) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fillAllFieldsCorrectly)),
      );
      return;
    }

    setState(() => _isGenerating = true);

    final curriculumTopics = await _fetchCurriculumTopics(course);
    final llmPlan =
        await _tryGenerateWithLlm(course, daysValue, hoursValue, curriculumTopics);

    if (!mounted) return;

    final totalHours = daysValue * hoursValue;
    final sessionDuration = 45;
    final totalSessions = (totalHours * 60 / sessionDuration).floor();

    setState(() {
      if (llmPlan.isNotEmpty) {
        _schedule = llmPlan;
      } else {
        _schedule = List.generate(daysValue, (dayIndex) {
          final l10n = AppLocalizations.of(context)!;
          final topicLabel = curriculumTopics.isNotEmpty
              ? curriculumTopics[dayIndex % curriculumTopics.length]['title']!
              : l10n.courseSessionLabel(course, (dayIndex * sessionDuration) + 1);
          return _ScheduleItem(
            day: dayIndex + 1,
            session: 1,
            topic: topicLabel,
            duration: sessionDuration,
            totalSessions: totalSessions,
            subjectId: curriculumTopics.isNotEmpty
                ? curriculumTopics[dayIndex % curriculumTopics.length]['subjectId'] ?? ''
                : '',
            topicId: curriculumTopics.isNotEmpty
                ? curriculumTopics[dayIndex % curriculumTopics.length]['id'] ?? ''
                : '',
          );
        });
      }
      _isGenerating = false;
    });

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.generatedPlanOverDays(course, daysValue, totalHours)),
      ),
    );
  }

  Future<List<_ScheduleItem>> _tryGenerateWithLlm(
    String course,
    int days,
    int hoursPerDay,
    List<Map<String, String>> topics,
  ) async {
    try {
      final config = LlmConfiguration(
        provider: LlmProvider.openRouter,
        apiKey: '',
      );
      final llm = LlmService(config: config);

      final topicNames = topics.map((t) => t['title']).join(', ');

      final prompt = '''
Create a detailed study plan for "$course" over $days days, $hoursPerDay hours per day.

Available topics: $topicNames

Return a JSON array where each item has:
{
  "day": 1,
  "topic": "Topic name from the available list",
  "duration_minutes": 45,
  "focus": "Brief focus area"
}

Create exactly $days entries, cycling through available topics.
''';

      final response = await llm.chat(
        message: prompt,
        modelId: 'openai/gpt-4o-mini',
        systemPrompt:
            'You are a study planner. Return only valid JSON, no markdown.',
      );

      final jsonList = _extractJsonArray(response);
      if (jsonList != null) {
        return jsonList.asMap().entries.map((entry) {
          final item = entry.value as Map<String, dynamic>;
          final topicTitle = item['topic'] as String? ?? '';
          final matchingTopic = topics.firstWhere(
            (t) => t['title'] == topicTitle,
            orElse: () => {'id': '', 'title': topicTitle, 'subjectId': ''},
          );
          return _ScheduleItem(
            day: (item['day'] as int?) ?? entry.key + 1,
            session: 1,
            topic: matchingTopic['title'] ?? topicTitle,
            duration: (item['duration_minutes'] as int?) ?? 45,
            totalSessions: days,
            subjectId: matchingTopic['subjectId'] ?? '',
            topicId: matchingTopic['id'] ?? '',
          );
        }).toList();
      }
    } catch (_) {}

    return [];
  }

  List<dynamic>? _extractJsonArray(String response) {
    try {
      final start = response.indexOf('[');
      final end = response.lastIndexOf(']');
      if (start != -1 && end != -1) {
        final jsonStr = response.substring(start, end + 1);
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) return decoded;
      }
    } catch (_) {}
    return null;
  }

  void _openTutorMode(String topicId, String topicTitle, String subjectId) {
    if (topicId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TutorScreen(
          topicId: topicId,
          topicTitle: topicTitle,
          subjectId: subjectId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.studyPlanner)),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.screenPadding(context),
        child: FocusTraversalGroup(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.createStudyPlan,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: TextField(
                controller: _courseController,
                decoration: InputDecoration(
                  labelText: l10n.courseSubject,
                  hintText: l10n.courseHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 400;
                if (narrow) {
                  return Column(
                    children: [
                      TextField(
                        controller: _daysController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.days,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _hoursController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.hoursPerDay,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _daysController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.days,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _hoursController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.hoursPerDay,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Semantics(
              button: true,
              label: _isGenerating ? l10n.generating : l10n.generatePlan,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generatePlan,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.calendar_today),
                label: Text(
                    _isGenerating ? l10n.generating : l10n.generatePlan),
              ),
            ),
            const SizedBox(height: 24),
            if (_schedule.isNotEmpty) ...[
              Text(l10n.yourStudySchedule,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _schedule.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _schedule[index];
                  return Semantics(
                    label:
                        '${item.topic}, ${l10n.sessionDurationMinutes(item.duration)}',
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        title: Text(item.topic),
                        subtitle:
                            Text(l10n.sessionDurationMinutes(item.duration)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.topicId.isNotEmpty)
                              Semantics(
                                button: true,
                                label: l10n.startAiTutoring,
                                child: IconButton(
                                  icon: const Icon(Icons.smart_toy_outlined),
                                  tooltip: l10n.startAiTutoring,
                                  onPressed: () => _openTutorMode(
                                    item.topicId,
                                    item.topic,
                                    item.subjectId,
                                  ),
                                ),
                              ),
                            const Icon(Icons.play_arrow),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}

class _ScheduleItem {
  final int day;
  final int session;
  final String topic;
  final int duration;
  final int totalSessions;
  final String subjectId;
  final String topicId;

  _ScheduleItem({
    required this.day,
    required this.session,
    required this.topic,
    required this.duration,
    required this.totalSessions,
    this.subjectId = '',
    this.topicId = '',
  });
}
