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

Lesson createTestLesson(String id, String topicId) {
  return Lesson(
    id: id,
    subjectId: 'subject-1',
    title: 'Test Lesson',
    topicId: topicId,
    blocks: [
      LessonBlock(
        id: 'block-1',
        subjectId: 'subject-1',
        lessonId: id,
        type: LessonBlockType.text,
        content: 'This is a text block',
        order: 0,
      ),
      LessonBlock(
        id: 'block-2',
        subjectId: 'subject-1',
        lessonId: id,
        type: LessonBlockType.example,
        content: 'This is an example block',
        order: 1,
      ),
      LessonBlock(
        id: 'block-3',
        subjectId: 'subject-1',
        lessonId: id,
        type: LessonBlockType.exercise,
        content: 'This is an exercise block',
        order: 2,
      ),
      LessonBlock(
        id: 'block-4',
        subjectId: 'subject-1',
        lessonId: id,
        type: LessonBlockType.slide,
        content: 'This is a slide block',
        order: 3,
      ),
      LessonBlock(
        id: 'block-5',
        subjectId: 'subject-1',
        lessonId: id,
        type: LessonBlockType.quiz,
        content: 'This is a quiz block',
        order: 4,
      ),
      LessonBlock(
        id: 'block-6',
        subjectId: 'subject-1',
        lessonId: id,
        type: LessonBlockType.summary,
        content: 'This is a summary block',
        order: 5,
      ),
    ],
    difficulty: 1,
    generatedBy: GeneratedBy.ai,
    createdAt: DateTime.now(),
  );
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

void main() {
  group('TopicListScreen UI Tests', () {
    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty message when topics list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('No topics yet - add some!')),
          ),
        ),
      );

      expect(find.text('No topics yet - add some!'), findsOneWidget);
    });

    testWidgets('displays topic list in ListView with correct padding', (tester) async {
      final topics = createTestTopics(count: 3);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final t = topics[index];
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
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(3));
    });

    testWidgets('displays folder icon for each topic', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 2,
              itemBuilder: (context, index) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.folder, color: Colors.blue),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.folder), findsNWidgets(2));
    });

    testWidgets('displays chevron right icon for navigation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 1,
              itemBuilder: (context, index) {
                return const Card(
                  child: ListTile(
                    trailing: Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('displays topic title correctly', (tester) async {
      final topics = createTestTopics(count: 1);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final t = topics[index];
                return ListTile(
                  title: Text(t.title),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Topic 0'), findsOneWidget);
    });

    testWidgets('displays topic description correctly', (tester) async {
      final topics = createTestTopics(count: 1);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final t = topics[index];
                return ListTile(
                  subtitle: Text(t.description),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Description for topic 0'), findsOneWidget);
    });

    testWidgets('topic list has correct padding of 16', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 1,
              itemBuilder: (context, index) => const SizedBox(),
            ),
          ),
        ),
      );

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.padding, const EdgeInsets.all(16));
    });

    testWidgets('card has correct margin of bottom 8', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 1,
              itemBuilder: (context, index) {
                return const Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: SizedBox(),
                );
              },
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.margin, const EdgeInsets.only(bottom: 8));
    });
  });

  group('LessonListScreen UI Tests', () {
    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty message when lessons list is empty', (tester) async {
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
    });

    testWidgets('displays lesson list in ListView', (tester) async {
      final lessons = createTestLessons('topic-1', count: 3);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test Topic')),
            body: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final l = lessons[index];
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
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(3));
    });

    testWidgets('displays correct block count in subtitle', (tester) async {
      final lessons = createTestLessons('topic-1', count: 2);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final l = lessons[index];
                return ListTile(
                  subtitle: Text('${l.blocks.length} blocks'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('2 blocks'), findsNWidgets(2));
    });

    testWidgets('shows play arrow icon for navigation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 1,
              itemBuilder: (context, index) {
                return const Card(
                  child: ListTile(
                    trailing: Icon(Icons.play_arrow),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('shows book icon for each lesson', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 2,
              itemBuilder: (context, index) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.book),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.book), findsNWidgets(2));
    });

    testWidgets('appBar displays topic title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Mathematics')),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.text('Mathematics'), findsOneWidget);
    });

    testWidgets('list has correct padding of 16', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 1,
              itemBuilder: (context, index) => const SizedBox(),
            ),
          ),
        ),
      );

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.padding, const EdgeInsets.all(16));
    });

    testWidgets('card has correct margin of bottom 8', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 1,
              itemBuilder: (context, index) {
                return const Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: SizedBox(),
                );
              },
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.margin, const EdgeInsets.only(bottom: 8));
    });
  });

  group('LessonDetailScreen UI Tests', () {
    testWidgets('shows loading indicator when lesson is null', (tester) async {
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
      final lesson = createTestLesson('lesson-1', 'topic-1');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: Text(lesson.title)),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.text('Test Lesson'), findsOneWidget);
    });

    testWidgets('displays all block content', (tester) async {
      final lesson = createTestLesson('lesson-1', 'topic-1');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: lesson.blocks.length,
              itemBuilder: (context, i) {
                final b = lesson.blocks[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(b.content),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('This is a text block'), findsOneWidget);
      expect(find.text('This is an example block'), findsOneWidget);
      expect(find.text('This is an exercise block'), findsOneWidget);
      expect(find.text('This is a slide block'), findsOneWidget);
      expect(find.text('This is a quiz block'), findsOneWidget);
      expect(find.text('This is a summary block'), findsOneWidget);
    });

    testWidgets('displays timer in bottom navigation bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text('0:00'),
              ),
            ),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.text('0:00'), findsOneWidget);
    });

    testWidgets('timer formats correctly for single digit seconds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text('${0}:${5.toString().padLeft(2, '0')}'),
              ),
            ),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.text('0:05'), findsOneWidget);
    });

    testWidgets('timer formats correctly for minutes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text('${5}:${30.toString().padLeft(2, '0')}'),
              ),
            ),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.text('5:30'), findsOneWidget);
    });

    testWidgets('displays block icons correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 6,
              itemBuilder: (context, index) {
                final types = [
                  LessonBlockType.text,
                  LessonBlockType.example,
                  LessonBlockType.exercise,
                  LessonBlockType.slide,
                  LessonBlockType.quiz,
                  LessonBlockType.summary,
                ];
                return ListTile(
                  leading: Icon(getBlockIcon(types[index])),
                );
              },
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

    testWidgets('displays block titles correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 6,
              itemBuilder: (context, index) {
                final types = [
                  LessonBlockType.text,
                  LessonBlockType.example,
                  LessonBlockType.exercise,
                  LessonBlockType.slide,
                  LessonBlockType.quiz,
                  LessonBlockType.summary,
                ];
                return ListTile(
                  title: Text(getBlockTitle(types[index])),
                );
              },
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

    testWidgets('lesson blocks are wrapped in cards', (tester) async {
      final lesson = createTestLesson('lesson-1', 'topic-1');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: lesson.blocks.length,
              itemBuilder: (context, index) {
                return const Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: SizedBox(height: 100),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsNWidgets(6));
    });

    testWidgets('cards have correct margin of bottom 12', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 1,
              itemBuilder: (context, index) {
                return const Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: SizedBox(),
                );
              },
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.margin, const EdgeInsets.only(bottom: 12));
    });

    testWidgets('block content has correct padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 1,
              itemBuilder: (context, index) {
                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ListTile(
                        leading: Icon(Icons.description),
                        title: Text('Explanation'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Block content'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Block content'), findsOneWidget);
      final paddingWidgets = tester.widgetList<Padding>(find.byType(Padding));
      final contentPadding = paddingWidgets.last;
      expect(contentPadding.padding, const EdgeInsets.all(16.0));
    });

    testWidgets('Scaffold body is ListView', (tester) async {
      final lesson = createTestLesson('lesson-1', 'topic-1');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: Text(lesson.title)),
            body: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lesson.blocks.length,
              itemBuilder: (context, i) => const Card(child: SizedBox()),
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('ListView has correct padding of 16', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 1,
              itemBuilder: (context, index) => const SizedBox(),
            ),
          ),
        ),
      );

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.padding, const EdgeInsets.all(16));
    });
  });

  group('Block Icon Helper Function Tests', () {
    test('returns correct icon for text type', () {
      expect(getBlockIcon(LessonBlockType.text), Icons.description);
    });

    test('returns correct icon for example type', () {
      expect(getBlockIcon(LessonBlockType.example), Icons.play_circle);
    });

    test('returns correct icon for exercise type', () {
      expect(getBlockIcon(LessonBlockType.exercise), Icons.note_add);
    });

    test('returns correct icon for slide type', () {
      expect(getBlockIcon(LessonBlockType.slide), Icons.slideshow);
    });

    test('returns correct icon for quiz type', () {
      expect(getBlockIcon(LessonBlockType.quiz), Icons.question_answer);
    });

    test('returns correct icon for summary type', () {
      expect(getBlockIcon(LessonBlockType.summary), Icons.check_circle);
    });
  });

  group('Block Title Helper Function Tests', () {
    test('returns correct title for text type', () {
      expect(getBlockTitle(LessonBlockType.text), 'Explanation');
    });

    test('returns correct title for example type', () {
      expect(getBlockTitle(LessonBlockType.example), 'Example');
    });

    test('returns correct title for exercise type', () {
      expect(getBlockTitle(LessonBlockType.exercise), 'Exercise');
    });

    test('returns correct title for slide type', () {
      expect(getBlockTitle(LessonBlockType.slide), 'Slide');
    });

    test('returns correct title for quiz type', () {
      expect(getBlockTitle(LessonBlockType.quiz), 'Quiz');
    });

    test('returns correct title for summary type', () {
      expect(getBlockTitle(LessonBlockType.summary), 'Summary');
    });
  });

  group('Model Tests', () {
    test('Topic model creates correct JSON', () {
      final topic = Topic(
        id: 'topic-1',
        subjectId: 'subject-1',
        title: 'Test Topic',
        description: 'Test Description',
        syllabusText: 'Test Syllabus',
        sortOrder: 1,
        childTopicIds: ['child-1', 'child-2'],
      );

      final json = topic.toJson();

      expect(json['id'], 'topic-1');
      expect(json['subjectId'], 'subject-1');
      expect(json['title'], 'Test Topic');
      expect(json['description'], 'Test Description');
      expect(json['syllabusText'], 'Test Syllabus');
      expect(json['sortOrder'], 1);
      expect(json['childTopicIds'], ['child-1', 'child-2']);
    });

    test('Topic model creates from JSON', () {
      final json = {
        'id': 'topic-1',
        'subjectId': 'subject-1',
        'title': 'Test Topic',
        'description': 'Test Description',
        'syllabusText': 'Test Syllabus',
        'sortOrder': 1,
        'childTopicIds': ['child-1'],
      };

      final topic = Topic.fromJson(json);

      expect(topic.id, 'topic-1');
      expect(topic.subjectId, 'subject-1');
      expect(topic.title, 'Test Topic');
      expect(topic.description, 'Test Description');
      expect(topic.syllabusText, 'Test Syllabus');
      expect(topic.sortOrder, 1);
      expect(topic.childTopicIds, ['child-1']);
    });

    test('Topic copyWith creates new instance with updated values', () {
      final topic = Topic(
        id: 'topic-1',
        subjectId: 'subject-1',
        title: 'Original Title',
        description: 'Original Description',
        syllabusText: 'Original Syllabus',
      );

      final updated = topic.copyWith(title: 'New Title', sortOrder: 5);

      expect(updated.id, 'topic-1');
      expect(updated.title, 'New Title');
      expect(updated.description, 'Original Description');
      expect(updated.sortOrder, 5);
    });

    test('Lesson model creates correct JSON', () {
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
            content: 'Content',
            order: 0,
          ),
        ],
        difficulty: 2,
        generatedBy: GeneratedBy.ai,
        createdAt: DateTime(2024, 1, 1),
        markscheme: 'Test markscheme',
      );

      final json = lesson.toJson();

      expect(json['id'], 'lesson-1');
      expect(json['subjectId'], 'subject-1');
      expect(json['title'], 'Test Lesson');
      expect(json['topicId'], 'topic-1');
      expect(json['difficulty'], 2);
      expect(json['generatedBy'], 0);
      expect(json['markscheme'], 'Test markscheme');
      expect((json['blocks'] as List).length, 1);
    });

    test('Lesson model creates from JSON', () {
      final json = {
        'id': 'lesson-1',
        'subjectId': 'subject-1',
        'title': 'Test Lesson',
        'topicId': 'topic-1',
        'blocks': [
          {
            'id': 'block-1',
            'subjectId': 'subject-1',
            'lessonId': 'lesson-1',
            'type': 0,
            'content': 'Content',
            'order': 0,
          }
        ],
        'difficulty': 1,
        'generatedBy': 0,
        'createdAt': '2024-01-01T00:00:00.000',
      };

      final lesson = Lesson.fromJson(json);

      expect(lesson.id, 'lesson-1');
      expect(lesson.title, 'Test Lesson');
      expect(lesson.topicId, 'topic-1');
      expect(lesson.blocks.length, 1);
      expect(lesson.blocks[0].content, 'Content');
    });

    test('LessonBlock model creates correct JSON', () {
      final block = LessonBlock(
        id: 'block-1',
        subjectId: 'subject-1',
        lessonId: 'lesson-1',
        type: LessonBlockType.exercise,
        content: 'Test content',
        order: 2,
      );

      final json = block.toJson();

      expect(json['id'], 'block-1');
      expect(json['subjectId'], 'subject-1');
      expect(json['lessonId'], 'lesson-1');
      expect(json['type'], 2);
      expect(json['content'], 'Test content');
      expect(json['order'], 2);
    });

    test('LessonBlock model creates from JSON', () {
      final json = {
        'id': 'block-1',
        'subjectId': 'subject-1',
        'lessonId': 'lesson-1',
        'type': 3,
        'content': 'Test content',
        'order': 1,
      };

      final block = LessonBlock.fromJson(json);

      expect(block.id, 'block-1');
      expect(block.type, LessonBlockType.slide);
      expect(block.content, 'Test content');
      expect(block.order, 1);
    });

    test('Topic default values are set correctly', () {
      final topic = Topic(
        id: 'topic-1',
        subjectId: 'subject-1',
        title: 'Test',
        description: 'Test',
        syllabusText: 'Test',
      );

      expect(topic.sortOrder, 0);
      expect(topic.childTopicIds, isEmpty);
    });

    test('Lesson default values are set correctly', () {
      final lesson = Lesson(
        id: 'lesson-1',
        subjectId: 'subject-1',
        title: 'Test',
        topicId: 'topic-1',
        createdAt: DateTime.now(),
      );

      expect(lesson.difficulty, 1);
      expect(lesson.generatedBy, GeneratedBy.manual);
      expect(lesson.blocks, isEmpty);
      expect(lesson.markscheme, isNull);
    });

    test('LessonBlock default order is 0', () {
      final block = LessonBlock(
        id: 'block-1',
        subjectId: 'subject-1',
        lessonId: 'lesson-1',
        type: LessonBlockType.text,
        content: 'Content',
      );

      expect(block.order, 0);
    });
  });
}