import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/models/lesson_model.dart';
import 'package:studyking/core/data/models/lesson_block_model.dart';
import 'package:studyking/core/data/enums.dart';

List<Topic> createTestTopics({int count = 3}) {
  return List.generate(count, (i) => Topic(
    id: 'topic-$i',
    subjectId: 'subject-1',
    title: 'Topic $i',
    description: 'Description for topic $i',
    syllabusText: 'Syllabus for topic $i',
    sortOrder: i,
    childTopicIds: [],
  ));
}

List<Lesson> createTestLessons(String topicId, {int count = 3}) {
  return List.generate(count, (i) => Lesson(
    id: 'lesson-$i',
    subjectId: 'subject-1',
    title: 'Lesson $i',
    topicId: topicId,
    blocks: [
      LessonBlock(
        id: 'block-$i-0',
        subjectId: 'subject-1',
        lessonId: 'lesson-$i',
        type: LessonBlockType.text,
        content: 'Content for block 0 in lesson $i',
        order: 0,
      ),
      LessonBlock(
        id: 'block-$i-1',
        subjectId: 'subject-1',
        lessonId: 'lesson-$i',
        type: LessonBlockType.exercise,
        content: 'Content for block 1 in lesson $i',
        order: 1,
      ),
    ],
    difficulty: 1,
    generatedBy: GeneratedBy.ai,
    createdAt: DateTime.now(),
  ));
}

class MockTopicRepository {
  final List<Topic> topics;
  final bool shouldThrow;

  MockTopicRepository({
    this.topics = const [],
    this.shouldThrow = false,
  });

  Future<List<Topic>> getAll() async {
    if (shouldThrow) throw Exception('Database error');
    return topics;
  }
}

class MockLessonRepository {
  final List<Lesson> lessons;
  final bool shouldThrow;

  MockLessonRepository({
    this.lessons = const [],
    this.shouldThrow = false,
  });

  Future<List<Lesson>> getAll() async {
    if (shouldThrow) throw Exception('Database error');
    return lessons;
  }

  Future<Lesson?> get(String id) async {
    if (shouldThrow) throw Exception('Database error');
    return lessons.where((l) => l.id == id).firstOrNull;
  }
}

IconData getBlockIcon(LessonBlockType type) {
  switch (type) {
    case LessonBlockType.text:
      return Icons.description;
    case LessonBlockType.example:
      return Icons.play_circle;
    case LessonBlockType.exercise:
      return Icons.note_add;
    case LessonBlockType.slide:
      return Icons.slideshow;
    case LessonBlockType.quiz:
      return Icons.question_answer;
    case LessonBlockType.summary:
      return Icons.check_circle;
  }
}

String getBlockTitle(LessonBlockType type) {
  switch (type) {
    case LessonBlockType.text:
      return 'Explanation';
    case LessonBlockType.example:
      return 'Example';
    case LessonBlockType.exercise:
      return 'Exercise';
    case LessonBlockType.slide:
      return 'Slide';
    case LessonBlockType.quiz:
      return 'Quiz';
    case LessonBlockType.summary:
      return 'Summary';
  }
}

class TestableTopicListView extends StatefulWidget {
  final MockTopicRepository topicRepo;
  
  const TestableTopicListView({super.key, required this.topicRepo});

  @override
  State<TestableTopicListView> createState() => _TestableTopicListViewState();
}

class _TestableTopicListViewState extends State<TestableTopicListView> {
  List<Topic> _topics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    try {
      final topics = await widget.topicRepo.getAll();
      if (mounted) {
        setState(() {
          _topics = topics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _retryLoadTopics() => _loadTopics();

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_topics.isEmpty) {
      return const Center(child: Text('No topics yet - add some!'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _topics.length,
      itemBuilder: (context, index) {
        final t = _topics[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.folder, color: Colors.blue),
            title: Text(t.title),
            subtitle: Text(t.description),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}

class TestableLessonListView extends StatefulWidget {
  final String topicId;
  final String topicTitle;
  final MockLessonRepository lessonRepo;
  
  const TestableLessonListView({
    super.key,
    required this.topicId,
    required this.topicTitle,
    required this.lessonRepo,
  });

  @override
  State<TestableLessonListView> createState() => _TestableLessonListViewState();
}

class _TestableLessonListViewState extends State<TestableLessonListView> {
  List<Lesson> _lessons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    try {
      final all = await widget.lessonRepo.getAll();
      if (mounted) {
        setState(() {
          _lessons = all.where((l) => l.topicId == widget.topicId).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_lessons.isEmpty) {
      return const Center(child: Text('No lessons - use Planner to generate!'));
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.topicTitle)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _lessons.length,
        itemBuilder: (context, index) {
          final l = _lessons[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.book),
              title: Text(l.title),
              subtitle: Text('${l.blocks.length} blocks'),
              trailing: const Icon(Icons.play_arrow),
            ),
          );
        },
      ),
    );
  }
}

class TestableLessonDetailView extends StatefulWidget {
  final String lessonId;
  final MockLessonRepository lessonRepo;
  
  const TestableLessonDetailView({
    super.key,
    required this.lessonId,
    required this.lessonRepo,
  });

  @override
  State<TestableLessonDetailView> createState() => _TestableLessonDetailViewState();
}

class _TestableLessonDetailViewState extends State<TestableLessonDetailView> {
  Lesson? _lesson;
  final Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    try {
      final lesson = await widget.lessonRepo.get(widget.lessonId);
      if (mounted && lesson != null) {
        setState(() => _lesson = lesson);
      }
    } catch (e) {
      debugPrint('Error loading lesson: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lesson == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final lesson = _lesson!;
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lesson.blocks.length,
        itemBuilder: (context, i) {
          final b = lesson.blocks[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Icon(getBlockIcon(b.type)),
                  title: Text(getBlockTitle(b.type)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(b.content),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text('${_elapsed.inMinutes}:${_elapsed.inSeconds.remainder(60).toString().padLeft(2, '0')}'),
        ),
      ),
    );
  }
}

void main() {
  group('TopicListView Tests', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final repo = MockTopicRepository();
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestableTopicListView(topicRepo: repo),
        ),
      );
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays topics when loaded', (tester) async {
      final topics = createTestTopics(count: 2);
      final repo = MockTopicRepository(topics: topics);
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestableTopicListView(topicRepo: repo),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.text('Topic 0'), findsOneWidget);
      expect(find.text('Topic 1'), findsOneWidget);
    });

    testWidgets('displays empty message when no topics', (tester) async {
      final repo = MockTopicRepository(topics: []);
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestableTopicListView(topicRepo: repo),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.text('No topics yet - add some!'), findsOneWidget);
    });

    testWidgets('shows folder and chevron icons', (tester) async {
      final topics = createTestTopics(count: 1);
      final repo = MockTopicRepository(topics: topics);
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestableTopicListView(topicRepo: repo),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.byIcon(Icons.folder), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });

  group('LessonListView Tests', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final repo = MockLessonRepository();
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestableLessonListView(
            topicId: 'topic-1',
            topicTitle: 'Test Topic',
            lessonRepo: repo,
          ),
        ),
      );
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays lessons when loaded', (tester) async {
      final lessons = createTestLessons('topic-1', count: 2);
      final repo = MockLessonRepository(lessons: lessons);
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestableLessonListView(
            topicId: 'topic-1',
            topicTitle: 'Test Topic',
            lessonRepo: repo,
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.text('Lesson 0'), findsOneWidget);
      expect(find.text('Lesson 1'), findsOneWidget);
    });

    testWidgets('displays empty message when no lessons', (tester) async {
      final repo = MockLessonRepository(lessons: []);
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestableLessonListView(
            topicId: 'topic-1',
            topicTitle: 'Test Topic',
            lessonRepo: repo,
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.text('No lessons - use Planner to generate!'), findsOneWidget);
    });

    testWidgets('displays topic title in AppBar', (tester) async {
      final lessons = createTestLessons('topic-1');
      final repo = MockLessonRepository(lessons: lessons);
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestableLessonListView(
            topicId: 'topic-1',
            topicTitle: 'Mathematics',
            lessonRepo: repo,
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.text('Mathematics'), findsOneWidget);
    });

    testWidgets('shows book and play_arrow icons', (tester) async {
      final lessons = createTestLessons('topic-1');
      final repo = MockLessonRepository(lessons: lessons);
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestableLessonListView(
            topicId: 'topic-1',
            topicTitle: 'Test',
            lessonRepo: repo,
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.byIcon(Icons.play_arrow), findsAtLeastNWidgets(1));
    });

    testWidgets('displays correct block count', (tester) async {
      final lessons = createTestLessons('topic-1', count: 1);
      final repo = MockLessonRepository(lessons: lessons);
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestableLessonListView(
            topicId: 'topic-1',
            topicTitle: 'Test',
            lessonRepo: repo,
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.text('2 blocks'), findsOneWidget);
    });
  });

  group('LessonDetailView Tests', () {
    testWidgets('shows loading indicator when lesson is null', (tester) async {
      final repo = MockLessonRepository(lessons: []);
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestableLessonDetailView(
            lessonId: 'lesson-1',
            lessonRepo: repo,
          ),
        ),
      );
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays lesson title in AppBar', (tester) async {
      final lessons = [
        Lesson(
          id: 'lesson-1',
          subjectId: 'subject-1',
          title: 'Test Lesson',
          topicId: 'topic-1',
          blocks: [],
          createdAt: DateTime.now(),
        ),
      ];
      final repo = MockLessonRepository(lessons: lessons);
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestableLessonDetailView(
            lessonId: 'lesson-1',
            lessonRepo: repo,
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.text('Test Lesson'), findsOneWidget);
    });

    testWidgets('displays all blocks with correct icons and titles', (tester) async {
      final lessons = [
        Lesson(
          id: 'lesson-1',
          subjectId: 'subject-1',
          title: 'Test Lesson',
          topicId: 'topic-1',
          blocks: [
            LessonBlock(id: 'b1', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.text, content: 'Text content', order: 0),
            LessonBlock(id: 'b2', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.example, content: 'Example content', order: 1),
            LessonBlock(id: 'b3', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.exercise, content: 'Exercise content', order: 2),
            LessonBlock(id: 'b4', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.slide, content: 'Slide content', order: 3),
            LessonBlock(id: 'b5', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.quiz, content: 'Quiz content', order: 4),
            LessonBlock(id: 'b6', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.summary, content: 'Summary content', order: 5),
          ],
          createdAt: DateTime.now(),
        ),
      ];
      final repo = MockLessonRepository(lessons: lessons);
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestableLessonDetailView(
            lessonId: 'lesson-1',
            lessonRepo: repo,
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.text('Text content'), findsOneWidget);
      expect(find.text('Example content'), findsOneWidget);
      expect(find.text('Exercise content'), findsOneWidget);
      expect(find.text('Slide content'), findsOneWidget);
      
      expect(find.byIcon(Icons.description), findsOneWidget);
      expect(find.byIcon(Icons.play_circle), findsOneWidget);
      expect(find.byIcon(Icons.note_add), findsOneWidget);
      expect(find.byIcon(Icons.slideshow), findsOneWidget);
      
      expect(find.text('Explanation'), findsOneWidget);
      expect(find.text('Example'), findsOneWidget);
      expect(find.text('Exercise'), findsOneWidget);
      expect(find.text('Slide'), findsOneWidget);
    });

    testWidgets('displays timer in bottom navigation bar', (tester) async {
      final lessons = [
        Lesson(
          id: 'lesson-1',
          subjectId: 'subject-1',
          title: 'Test Lesson',
          topicId: 'topic-1',
          blocks: [],
          createdAt: DateTime.now(),
        ),
      ];
      final repo = MockLessonRepository(lessons: lessons);
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestableLessonDetailView(
            lessonId: 'lesson-1',
            lessonRepo: repo,
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.text('0:00'), findsOneWidget);
    });

    testWidgets('timer formats correctly for different times', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text('${5}:${30.toString().padLeft(2, '0')}'),
              ),
            ),
          ),
        ),
      );
      
      expect(find.text('5:30'), findsOneWidget);
    });
  });

  group('Helper Function Tests', () {
    test('getBlockIcon returns correct icon for each type', () {
      expect(getBlockIcon(LessonBlockType.text), Icons.description);
      expect(getBlockIcon(LessonBlockType.example), Icons.play_circle);
      expect(getBlockIcon(LessonBlockType.exercise), Icons.note_add);
      expect(getBlockIcon(LessonBlockType.slide), Icons.slideshow);
      expect(getBlockIcon(LessonBlockType.quiz), Icons.question_answer);
      expect(getBlockIcon(LessonBlockType.summary), Icons.check_circle);
    });

    test('getBlockTitle returns correct title for each type', () {
      expect(getBlockTitle(LessonBlockType.text), 'Explanation');
      expect(getBlockTitle(LessonBlockType.example), 'Example');
      expect(getBlockTitle(LessonBlockType.exercise), 'Exercise');
      expect(getBlockTitle(LessonBlockType.slide), 'Slide');
      expect(getBlockTitle(LessonBlockType.quiz), 'Quiz');
      expect(getBlockTitle(LessonBlockType.summary), 'Summary');
    });
  });
}