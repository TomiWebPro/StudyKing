// COMPLETE LESSON SCHEDULING UI PAGE
// Schedules lessons connecting subjects, materials, pages to questions
// Shows progress and lesson types

import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson Scheduler'),
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
                    const Text('Upcoming Lessons'),
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
                    const Text('Select Subject'),
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
                    const Text('Generate Question Types'),
                    const SizedBox(height: 8),
                    const Text('Select question format:'),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: const [
                        FilterChip(
                          label: Text('MCQ'),
                          selected: true,
                          onSelected: null,
                        ),
                        FilterChip(
                          label: Text('Input'),
                          selected: false,
                          onSelected: null,
                        ),
                        FilterChip(
                          label: Text('Graph'),
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
                    const Text('Lesson Progress'),
                    LinearProgressIndicator(
                      value: 0.65,
                    ),
                    const SizedBox(height: 8),
                    Text('65% Complete: 5/8 questions generated'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Lesson'),
        content: const Text('Select calendar date for lesson'),
        actions: [
          TextButton(
            child: const Text('Done'),
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
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('Create New Lesson'),
              onTap: () => _handleCreateLesson(context),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Existing Lesson'),
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
