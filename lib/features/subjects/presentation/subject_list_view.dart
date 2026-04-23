import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/subjects/models/subject_model.dart';
import 'subject_selection_screen.dart';

// Database service import
import 'package:studyking/main.dart' show database;

class SubjectListView extends ConsumerWidget {
  const SubjectListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subjects'),
        actions: [
          IconButton(
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
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          // Note: In production, use Riverpod to watch subjects
          return FutureBuilder<List<Subject>>(
            future: _loadSubjects(ref),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final subjects = snapshot.data ?? [];

              if (subjects.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No subjects yet',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first subject to begin studying',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
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
                        label: const Text('Add Subject'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  return _buildSubjectCard(context, subject);
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Subject>> _loadSubjects(WidgetRef ref) async {
    // Use database directly since we don't have full Riverpod setup yet
    final subjects = await database.subjectRepository.getAll();
    return subjects;
  }

  Widget _buildSubjectCard(BuildContext context, Subject subject) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to subject detail
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.transparent,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              // Subject icon with color
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(int.parse(subject.color.substring(1), radix: 16) + 0xFF000000),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.school,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),

              // Subject info
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
                          'Practice sessions',
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

              // Arrow
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
