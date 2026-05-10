import 'package:flutter/material.dart';
import 'package:studyking/main.dart' show database;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/lessons/presentation/lesson_list_screen.dart';
import 'package:studyking/features/practice/presentation/practice_session_screen.dart';
import 'package:studyking/features/sessions/presentation/session_history_screen.dart';
import 'package:studyking/core/data/repositories/lesson_repository.dart';
import 'package:studyking/core/data/repositories/study_session_repository.dart';

/// Subject Detail Screen - Shows all content for a subject
class SubjectDetailScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String subjectName;
  final String? subjectDescription;
  final String? subjectSyllabus;
  final String? subjectCode;
  final String? subjectTeacher;
  final String subjectColor;
  final String? subjectExamDate;
  final List<String> topicIds;

  const SubjectDetailScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    this.subjectDescription,
    this.subjectSyllabus,
    this.subjectCode,
    this.subjectTeacher,
    required this.subjectColor,
    this.subjectExamDate,
    required this.topicIds,
  });

  @override
  ConsumerState<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends ConsumerState<SubjectDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _stringToColor(widget.subjectColor);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // SliverAppBar with gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: color.withOpacity(0.1),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.subjectName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.8),
                      color.withOpacity(0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    widget.subjectName[0].toUpperCase(),
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.subjectName,
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (widget.subjectCode != null)
                                        Text(
                                          widget.subjectCode!,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  color: Colors.white,
                                  onPressed: () {
                                    // Navigate to edit screen
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  color: Colors.white,
                                  onPressed: _showMoreOptions,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: theme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: color,
              tabs: const [
                Tab(icon: Icon(Icons.book), text: 'Lessons'),
                Tab(icon: Icon(Icons.play_arrow), text: 'Practice'),
                Tab(icon: Icon(Icons.history), text: 'History'),
                Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
              ],
            ),
          ),

          // Tab content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: TabBarView(
              controller: _tabController,
              children: [
                // Lessons Tab
                _buildLessonsTab(),

                // Practice Tab
                _buildPracticeTab(),

                // History Tab
                _buildHistoryTab(),

                // Stats Tab
                _buildStatsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsTab() {
    return Consumer(builder: (context, ref, child) {
      final lessonRepo = LessonRepository();
      
      Future<List<dynamic>> loadLessons() async {
        try {
          final lessons = await lessonRepo.getAll();
          final subjectLessons = lessons.where((l) => l.subjectId == widget.subjectId).toList();
          return subjectLessons;
        } catch (e) {
          return [];
        }
      }

      return FutureBuilder<List<dynamic>>(
        future: loadLessons(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final subjectLessons = snapshot.data ?? [];
          
          if (subjectLessons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No lessons yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start learning by creating topics and questions',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      // Navigate to topic creation
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Topic'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: subjectLessons.length,
            itemBuilder: (context, index) {
              final lesson = subjectLessons[index];
              final questionCount = ((lesson as dynamic).questionIds?.length ?? 0).toInt();
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _stringToColor(widget.subjectColor).withOpacity(0.2),
                    child: Icon(Icons.book, color: _stringToColor(widget.subjectColor)),
                  ),
                  title: Text((lesson as dynamic).title ?? 'Lesson'),
                  subtitle: Text('Questions: $questionCount'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LessonListScreen(
                          topicId: (lesson as dynamic).topicId ?? '',
                          topicTitle: (lesson as dynamic).title ?? 'Lesson',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      );
    });
  }

  Widget _buildPracticeTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.workspace_premium, size: 64, color: _stringToColor(widget.subjectColor)),
          const SizedBox(height: 16),
          Text(
            'Practice Mode',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _stringToColor(widget.subjectColor)),
          ),
          const SizedBox(height: 8),
          Text(
            'Practice questions from ${widget.subjectName}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PracticeSessionScreen(
                    subjectId: widget.subjectId,
                    questionCount: 20,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Practice'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Consumer(builder: (context, ref, child) {
      final sessionRepo = StudySessionRepository();
      
      Future<List<dynamic>> loadSessions() async {
        try {
          final sessions = await sessionRepo.getAll();
          final subjectSessions = sessions.where((s) => s.subjectId == widget.subjectId).toList();
          return subjectSessions;
        } catch (e) {
          return [];
        }
      }

      return FutureBuilder<List<dynamic>>(
        future: loadSessions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final subjectSessions = snapshot.data ?? [];
          
          if (subjectSessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No practice history'),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SessionHistoryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.view_list),
                    label: const Text('View All Sessions'),
                  ),
                ],
              ),
            );
          }

          // Sort by most recent
          subjectSessions.sort((a, b) {
            final aTime = (a as dynamic).startTime?.millisecondsSinceEpoch ?? 0;
            final bTime = (b as dynamic).startTime?.millisecondsSinceEpoch ?? 0;
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            itemCount: subjectSessions.length,
            itemBuilder: (context, index) {
              final session = subjectSessions[index];
              final questionsAnswered = ((session as dynamic).questionsAnswered ?? 0).toInt();
              final correctAnswers = ((session as dynamic).correctAnswers ?? 0).toInt();
              final score = questionsAnswered > 0 ? (correctAnswers / questionsAnswered * 100) : 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: score >= 80 
                        ? Colors.green.withOpacity(0.2)
                        : score >= 50 
                            ? Colors.orange.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                    child: Icon(
                      score >= 80 
                          ? Icons.check_circle 
                          : Icons.sticky_note_2,
                      color: score >= 80 
                          ? Colors.green 
                          : score >= 50 
                              ? Colors.orange 
                              : Colors.red,
                    ),
                  ),
                  title: Text('Session ${index + 1}'),
                  subtitle: Text(
                    '${_formatDate((session as dynamic).startTime ?? DateTime.now())} • ${_formatDuration(Duration(milliseconds: ((session as dynamic).timeSpentMs ?? 0).toInt()))}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${score.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: score >= 80 
                              ? Colors.green 
                              : score >= 50 
                                  ? Colors.orange 
                                  : Colors.red,
                        ),
                      ),
                      if (questionsAnswered > 0)
                        Text(
                          '$correctAnswers/$questionsAnswered',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                  onTap: () => _showSessionDetails(session),
                ),
              );
            },
          );
        },
      );
    });
  }

  Widget _buildStatsTab() {
    return Consumer(builder: (context, ref, child) {
      final sessionRepo = StudySessionRepository();
      
      Future<List<dynamic>> loadSessions() async {
        try {
          final sessions = await sessionRepo.getAll();
          final subjectSessions = sessions.where((s) => s.subjectId == widget.subjectId).toList();
          return subjectSessions;
        } catch (e) {
          return [];
        }
      }

      return FutureBuilder<List<dynamic>>(
        future: loadSessions(),
        builder: (context, snapshot) {
          final subjectSessions = snapshot.data ?? [];
          
          final totalSessions = subjectSessions.length;
          final totalQuestions = subjectSessions.fold<int>(0, (sum, s) => sum + (((s as dynamic).questionsAnswered ?? 0) as int).toInt());
          final totalCorrect = subjectSessions.fold<int>(0, (sum, s) => sum + (((s as dynamic).correctAnswers ?? 0) as int).toInt());
          final totalTime = subjectSessions.fold<int>(0, (sum, s) => sum + (((s as dynamic).timeSpentMs ?? 0) as int).toInt());
          final avgScore = totalQuestions > 0 ? (totalCorrect / totalQuestions * 100) : 0;

          return Column(
            children: [
              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Sessions',
                      totalSessions.toString(),
                      Icons.how_to_vote,
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Accuracy',
                      '${avgScore.toStringAsFixed(1)}%',
                      Icons.star,
                      avgScore >= 80 ? Colors.green : avgScore >= 50 ? Colors.orange : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Questions',
                      totalQuestions.toString(),
                      Icons.question_answer,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Time',
                      _formatDuration(Duration(milliseconds: totalTime)),
                      Icons.access_time,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Practice Progress
              _buildSectionHeader('Practice Progress'),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Overall Score'),
                          Text(
                            '${avgScore.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: avgScore >= 80 ? Colors.green : avgScore >= 50 ? Colors.orange : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: avgScore / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          avgScore >= 80 ? Colors.green : avgScore >= 50 ? Colors.orange : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Keep practicing to improve your score!',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Subject'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to edit screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // Add settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Subject', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: const Text('Are you sure you want to delete this subject? This will also delete all associated lessons and questions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Delete subject logic
              Navigator.pop(context);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSessionDetails(dynamic session) {
    final questions = ((session as dynamic).questionsAnswered ?? 0).toInt();
    final correct = ((session as dynamic).correctAnswers ?? 0).toInt();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Date', _formatDate((session as dynamic).startTime ?? DateTime.now())),
            _detailRow('Duration', _formatDuration(Duration(milliseconds: ((session as dynamic).timeSpentMs ?? 0) as int))),
            _detailRow('Questions', questions.toString()),
            if (correct > 0)
              _detailRow('Correct', '$correct/$questions'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _stringToColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ';
    }
    return '${duration.inSeconds}s';
  }
}
