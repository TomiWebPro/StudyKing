import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'practice_session_screen.dart';
import '../../subjects/models/subject_model.dart';
import '../../subjects/data/repositories/subject_repository.dart';
import 'package:studyking/main.dart' show database;

/// Production Practice Screen - Shows practice modes and allows selecting subjects
class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  List<Subject> _subjects = [];

  Future<void> _loadSubjects() async {
    try {
      final subjects = await _fetchSubjects();
      if (mounted) {
        setState(() {
          _subjects = subjects;
        });
      }
    } catch (e) {
      debugPrint('Error loading subjects: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subjects: $e')),
        );
      }
    }
  }

  Future<List<Subject>> _fetchSubjects() async {
    // Use the global database instance
    // In Consumer widget, access through ref or global
    return await database.subjectRepository.getAll();
  }

  void _startPractice(Subject subject) {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, color: Colors.orange.shade400, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Practice Session Starting',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                subject.name,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Mode'),
        actions: [
          if (_subjects.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: () {
                _showPracticeModeDialog();
              },
              tooltip: 'Practice Options',
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _subjects.isEmpty
            ? null
            : () {
                if (_subjects.length == 1) {
                  _startPractice(_subjects.first);
                } else {
                  _showSubjectSelector();
                }
              },
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.play_arrow),
        label: Text(_subjects.isEmpty ? 'No Subjects' : 'Practice'),
      ),
    );
  }

  Widget _buildBody() {
    if (_subjects.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadSubjects,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildModeSection(context),
          const SizedBox(height: 24),
          _buildSubjectSection(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_online_outlined,
              size: 96,
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            const SizedBox(height: 24),
            Text(
              'No Practice Sessions Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Add subjects and questions to start practicing',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to subject management
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Subject'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Practice Modes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _PracticeModeCard(
              context: context,
              icon: Icons.flash_on,
              title: 'Quick Practice',
              subtitle: '10 random questions',
              color: Colors.blue,
              onTap: () => _showPracticeModeDialog(),
            ),
            _PracticeModeCard(
              context: context,
              icon: Icons.schedule,
              title: 'Spaced Repetition',
              subtitle: 'Coming soon',
              color: Colors.orange,
              onTap: null,
            ),
            _PracticeModeCard(
              context: context,
              icon: Icons.category,
              title: 'Topic Focus',
              subtitle: 'Practice specific topics',
              color: Colors.purple,
              onTap: () => _showTopicSelector(),
            ),
            _PracticeModeCard(
              context: context,
              icon: Icons.bar_chart,
              title: 'Weak Areas',
              subtitle: 'Focus on mistakes',
              color: Colors.red,
              onTap: null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubjectSection(BuildContext context) {
    if (_subjects.length == 1) {
      final subject = _subjects.first;
      return _buildSingleSubjectCard(context, subject);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Subjects',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._subjects.map((subject) => _buildSubjectPracticeCard(context, subject)),
      ],
    );
  }

  Widget _buildSingleSubjectCard(BuildContext context, Subject subject) {
    return Card(
      child: InkWell(
        onTap: () => _startPractice(subject),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.school,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready for practice',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectPracticeCard(BuildContext context, Subject subject) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _startPractice(subject),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getSubjectColor(subject.name).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.school,
                  color: _getSubjectColor(subject.name),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subject.code != null)
                      Text(
                        subject.code!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.quiz,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Practice available',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.play_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSubjectColor(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    return colors[name.hashCode % colors.length];
  }

  void _showSubjectSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Subject',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._subjects.map((subject) => ListTile(
              leading: CircleAvatar(
                backgroundColor: _getSubjectColor(subject.name).withOpacity(0.1),
                child: Icon(
                  Icons.school,
                  color: _getSubjectColor(subject.name),
                ),
              ),
              title: Text(subject.name),
              subtitle: subject.code != null ? Text(subject.code!) : null,
              onTap: () {
                Navigator.pop(context);
                _startPractice(subject);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPracticeModeDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Practice Mode',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_subjects.length == 1)
              _PracticeModeOption(
                icon: Icons.auto_fix_high,
                title: 'Auto Select',
                subtitle: 'AI picks optimal questions',
                onTap: () {
                  Navigator.pop(context);
                  _startPractice(_subjects.first);
                },
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Subject',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._subjects.map((subject) => _PracticeModeOption(
                    icon: Icons.school,
                    title: subject.name,
                    subtitle: subject.code ?? 'No code',
                    onTap: () {
                      Navigator.pop(context);
                      _startPractice(subject);
                    },
                  )),
                ],
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showTopicSelector() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Topic selection coming soon!')),
    );
  }
}

class _PracticeModeCard extends StatelessWidget {
  final BuildContext context;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _PracticeModeCard({
    required this.context,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = onTap != null;
    return Card(
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isAvailable ? color.withOpacity(0.1) : Colors.grey.shade100,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isAvailable ? color : Colors.grey.shade400,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isAvailable ? color : Colors.grey.shade400,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isAvailable ? color : Colors.grey.shade400,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PracticeModeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _PracticeModeOption({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
