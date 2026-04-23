import 'package:flutter/material.dart';
import 'dart:async';

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

  Future<void> _generatePlan() async {
    final course = _courseController.text.trim();
    final daysValue = int.tryParse(_daysController.text);
    final hoursValue = int.tryParse(_hoursController.text);

    if (course.isEmpty || daysValue == null || hoursValue == null || daysValue <= 0 || hoursValue <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields correctly')),
      );
      return;
    }

    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final totalHours = daysValue * hoursValue;
    final sessionDuration = 45;
    final totalSessions = (totalHours * 60 / sessionDuration).floor();

    setState(() {
      _schedule = List.generate(daysValue, (dayIndex) {
        return _ScheduleItem(
          day: dayIndex + 1,
          session: 1,
          topic: '$course - Topic ${(dayIndex * sessionDuration) + 1}',
          duration: sessionDuration,
          totalSessions: totalSessions,
        );
      });
      _isGenerating = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generated plan for $course over $daysValue days ($totalHours total hours)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Planner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Study Plan', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _courseController,
              decoration: const InputDecoration(
                labelText: 'Course/Subject',
                hintText: 'e.g., IB Physics',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _daysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Days',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _hoursController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Hours/Day',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generatePlan,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.calendar_today),
              label: Text(_isGenerating ? 'Generating...' : 'Generate Plan'),
            ),
            const SizedBox(height: 24),
            if (_schedule.isNotEmpty) ...[
              Text('Your Study Schedule', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _schedule.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text('${index + 1}', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    ),
                    title: Text(_schedule[index].topic),
                    subtitle: Text('${_schedule[index].duration} min session'),
                    trailing: const Icon(Icons.play_arrow),
                  ),
                ),
              ),
            ],
          ],
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
  _ScheduleItem({required this.day, required this.session, required this.topic, required this.duration, required this.totalSessions});
}
