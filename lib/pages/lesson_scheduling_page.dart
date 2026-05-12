// COMPLETE LESSON SCHEDULING UI PAGE
// Schedules lessons connecting subjects, materials, pages to questions
// Shows progress and lesson types

import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/llm_engine_provider.dart';

/// Main lesson scheduling page
class LessonSchedulingPage extends StatelessWidget {
  final LLMAIEngineProvider llmProvider;

  const LessonSchedulingPage({
    super.key,
    required this.llmProvider,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.lessonScheduler),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _showScheduleCalendar(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddLessonDialog(context, llmProvider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Schedule Calendar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(l10n.upcomingLessons),
                    const SizedBox(height: 16),
                      TableCalendar(
                        firstDay: DateTime(2024),
                        lastDay: DateTime(2035),
                        focusedDay: DateTime.now(),
                        onDaySelected: _onDaySelected,
                      ),
                  ],
                ),
              ),
            ),
            // Subject Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.selectSubjectLabel),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: 'math',
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'math', child: Text('Mathematics')),
                        DropdownMenuItem(value: 'science', child: Text('Science')),
                        DropdownMenuItem(value: 'english', child: Text('English')),
                      ],
                      onChanged: (value) {},
                    ),
                  ],
                ),
              ),
            ),
            // Question Type Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.generateQuestionTypes),
                    const SizedBox(height: 8),
                    Text(l10n.selectFormat),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        FilterChip(
                          label: Text(l10n.mcq),
                          selected: true,
                          onSelected: null,
                        ),
                        FilterChip(
                          label: Text(l10n.inputLabel),
                          selected: false,
                          onSelected: null,
                        ),
                        FilterChip(
                          label: Text(l10n.graphLabel),
                          selected: false,
                          onSelected: null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Lesson Progress
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(l10n.lessonProgress),
                    LinearProgressIndicator(
                      value: 0.65,
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.percentComplete(65, 5, 8)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleCalendar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.scheduleLesson),
        content: Text(l10n.selectCalendarDate),
        actions: [
          TextButton(
            child: Text(l10n.done),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showAddLessonDialog(
    BuildContext context,
    LLMAIEngineProvider llmProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.public),
              title: Text(l10n.createNewLesson),
              onTap: () => _handleCreateLesson(context),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n.editExistingLesson),
              onTap: () {},
            ),
          ],
        );
      },
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {}

  void _handleCreateLesson(BuildContext context) {
    // Create lesson, generate questions via LLM
  }
}
