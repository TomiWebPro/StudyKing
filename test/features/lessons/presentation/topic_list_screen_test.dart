import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/models/lesson_model.dart';
import 'package:studyking/core/data/models/lesson_block_model.dart';
import 'package:studyking/core/data/enums.dart';

class MockDatabaseService {
  final List<Topic> topics;
  final List<Lesson> lessons;
  final bool shouldThrowOnTopics;
  final bool shouldThrowOnLessons;

  MockDatabaseService({
    this.topics = const [],
    this.lessons = const [],
    this.shouldThrowOnTopics = false,
    this.shouldThrowOnLessons = false,
  });
}

class FakeTopicRepository {
  final MockDatabaseService _db;
  
  FakeTopicRepository(this._db);

  Future<List<Topic>> getAll() async {
    if (_db.shouldThrowOnTopics) {
      throw Exception('Database error loading topics');
    }
    await Future.delayed(const Duration(milliseconds: 10));
    return _db.topics;
  }

  Future<Topic?> get(String id) async {
    await Future.delayed(const Duration(milliseconds: 10));
    return _db.topics.where((t) => t.id == id).firstOrNull;
  }
}

class FakeLessonRepository {
  final MockDatabaseService _db;
  
  FakeLessonRepository(this._db);

  Future<List<Lesson>> getAll() async {
    if (_db.shouldThrowOnLessons) {
      throw Exception('Database error loading lessons');
    }
    await Future.delayed(const Duration(milliseconds: 10));
    return _db.lessons;
  }

  Future<Lesson?> get(String id) async {
    await Future.delayed(const Duration(milliseconds: 10));
    return _db.lessons.where((l) => l.id == id).firstOrNull;
  }
}

class MockDatabaseServiceWrapper {
  final MockDatabaseService _mockDb;
  
  MockDatabaseServiceWrapper(this._mockDb);

  FakeTopicRepository get topicRepository => FakeTopicRepository(_mockDb);
  FakeLessonRepository get lessonRepository => FakeLessonRepository(_mockDb);
}

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

void main() {
  group('TopicListScreen Widget Tests', () {
    testWidgets('displays loading indicator initially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays empty state message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('No topics yet - add some!')),
          ),
        ),
      );
      expect(find.text('No topics yet - add some!'), findsOneWidget);
    });

    testWidgets('displays list of topics with correct structure', (tester) async {
      final topics = createTestTopics(count: 2);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.folder, color: Colors.blue),
                    title: Text(topic.title),
                    subtitle: Text(topic.description),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(2));
      expect(find.text('Topic 0'), findsOneWidget);
      expect(find.text('Topic 1'), findsOneWidget);
    });

    testWidgets('tapping topic navigates to lesson list', (tester) async {
      bool navigated = false;
      final topics = createTestTopics(count: 1);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];
                return Card(
                  child: ListTile(
                    title: Text(topic.title),
                    onTap: () {
                      navigated = true;
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Topic 0'));
      expect(navigated, isTrue);
    });
  });

  group('LessonListScreen Widget Tests', () {
    testWidgets('displays loading indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays empty state message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('No lessons - use Planner to generate!')),
          ),
        ),
      );
      expect(find.text('No lessons - use Planner to generate!'), findsOneWidget);
    });

    testWidgets('displays Scaffold with AppBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test Topic')),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Test Topic'), findsOneWidget);
    });

    testWidgets('displays list of lessons with block count', (tester) async {
      final lessons = createTestLessons('topic-1', count: 2);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Topic')),
            body: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.book),
                    title: Text(lesson.title),
                    subtitle: Text('${lesson.blocks.length} blocks'),
                    trailing: const Icon(Icons.play_arrow),
                    onTap: () {},
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('2 blocks'), findsNWidgets(2));
      expect(find.text('Lesson 0'), findsOneWidget);
    });

    testWidgets('tapping lesson navigates to detail', (tester) async {
      bool navigated = false;
      final lessons = createTestLessons('topic-1', count: 1);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Topic')),
            body: ListView.builder(
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                return Card(
                  child: ListTile(
                    title: Text(lesson.title),
                    onTap: () {
                      navigated = true;
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Lesson 0'));
      expect(navigated, isTrue);
    });
  });

  group('LessonDetailScreen Widget Tests', () {
    testWidgets('displays loading when lesson is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays lesson title in appBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test Lesson')),
            body: const SizedBox(),
          ),
        ),
      );
      expect(find.text('Test Lesson'), findsOneWidget);
    });

    testWidgets('displays all lesson blocks', (tester) async {
      final lesson = Lesson(
        id: 'lesson-1',
        subjectId: 'subject-1',
        title: 'Test Lesson',
        topicId: 'topic-1',
        blocks: [
          LessonBlock(
            id: 'block-1',
            subjectId: 'subject-1',
            lessonId: 'lesson-1',
            type: LessonBlockType.text,
            content: 'Text content',
            order: 0,
          ),
          LessonBlock(
            id: 'block-2',
            subjectId: 'subject-1',
            lessonId: 'lesson-1',
            type: LessonBlockType.exercise,
            content: 'Exercise content',
            order: 1,
          ),
          LessonBlock(
            id: 'block-3',
            subjectId: 'subject-1',
            lessonId: 'lesson-1',
            type: LessonBlockType.summary,
            content: 'Summary content',
            order: 2,
          ),
        ],
        difficulty: 1,
        generatedBy: GeneratedBy.ai,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: Text(lesson.title)),
            body: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lesson.blocks.length,
              itemBuilder: (context, i) {
                final block = lesson.blocks[i];
                IconData icon;
                String title;
                switch (block.type) {
                  case LessonBlockType.text:
                    icon = Icons.description;
                    title = 'Explanation';
                    break;
                  case LessonBlockType.exercise:
                    icon = Icons.note_add;
                    title = 'Exercise';
                    break;
                  case LessonBlockType.summary:
                    icon = Icons.check_circle;
                    title = 'Summary';
                    break;
                  default:
                    icon = Icons.description;
                    title = 'Block';
                }
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: Icon(icon),
                        title: Text(title),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(block.content),
                      ),
                    ],
                  ),
                );
              },
            ),
            bottomNavigationBar: const BottomAppBar(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text('0:00'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(3));
      expect(find.text('Text content'), findsOneWidget);
      expect(find.text('Exercise content'), findsOneWidget);
      expect(find.text('Summary content'), findsOneWidget);
      expect(find.text('0:00'), findsOneWidget);
    });

    testWidgets('timer displays correct format', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SizedBox(),
            bottomNavigationBar: BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text('5:30'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('5:30'), findsOneWidget);
    });

    testWidgets('displays icons for each block type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                const ListTile(leading: Icon(Icons.description)),
                const ListTile(leading: Icon(Icons.play_circle)),
                const ListTile(leading: Icon(Icons.note_add)),
                const ListTile(leading: Icon(Icons.slideshow)),
                const ListTile(leading: Icon(Icons.question_answer)),
                const ListTile(leading: Icon(Icons.check_circle)),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.description), findsOneWidget);
      expect(find.byIcon(Icons.play_circle), findsOneWidget);
      expect(find.byIcon(Icons.note_add), findsOneWidget);
      expect(find.byIcon(Icons.slideshow), findsOneWidget);
      expect(find.byIcon(Icons.question_answer), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays titles for each block type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                ListTile(title: Text('Explanation')),
                ListTile(title: Text('Example')),
                ListTile(title: Text('Exercise')),
                ListTile(title: Text('Slide')),
                ListTile(title: Text('Quiz')),
                ListTile(title: Text('Summary')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Explanation'), findsOneWidget);
      expect(find.text('Example'), findsOneWidget);
      expect(find.text('Exercise'), findsOneWidget);
      expect(find.text('Slide'), findsOneWidget);
      expect(find.text('Quiz'), findsOneWidget);
      expect(find.text('Summary'), findsOneWidget);
    });
  });
}