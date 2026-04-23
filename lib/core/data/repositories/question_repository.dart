import 'package:hive_flutter/hive_flutter.dart';
import '../models/question_model.dart';
import '../enums.dart';

class QuestionRepository {
  late Box<Question> _box;

  Future<void> init() async {
    _box = Hive.box<Question>('questions');
  }

  Future<void> create(Question question) async {
    await _box.put(question.id, question);
  }

  Future<Question?> get(String id) async {
    return _box.get(id);
  }

  Future<List<Question>> getAll() async {
    return _box.values.toList();
  }

  Future<List<Question>> getByTopic(String topicId) async {
    final all = _box.values.toList();
    return all.where((q) => q.topicId == topicId).toList();
  }

  Future<List<Question>> getBySubject(String subjectId) async {
    final all = _box.values.toList();
    return all.where((q) => q.subjectId == subjectId).toList();
  }

  Future<List<Question>> getBySubjectAndTopic(
    String subjectId,
    String topicId,
  ) async {
    final all = _box.values.toList();
    return all.where((q) => 
      q.subjectId == subjectId && q.topicId == topicId
    ).toList();
  }

  Future<List<Question>> getByType(QuestionType type) async {
    final all = _box.values.toList();
    return all.where((q) => q.type == type).toList();
  }

  Future<List<Question>> getBySubjectAndType(
    String subjectId,
    QuestionType type,
  ) async {
    final all = _box.values.toList();
    return all.where((q) => 
      q.subjectId == subjectId && q.type == type
    ).toList();
  }

  /// Get questions with markscheme for a subject
  Future<List<QuestionWithMarkscheme>> getQuestionsWithMarkschemes(String subjectId) async {
    final questions = await getBySubject(subjectId);
    return questions
        .where((q) => q.markscheme != null && q.markscheme!.isNotEmpty)
        .map((q) => QuestionWithMarkscheme(question: q, markscheme: q.markscheme!))
        .toList();
  }

  Future<void> updateMarkscheme(String questionId, String markscheme) async {
    final question = await get(questionId);
    if (question != null) {
      final updated = question.copyWith(markscheme: markscheme);
      await create(updated);
    }
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}

class QuestionWithMarkscheme {
  final Question question;
  final String markscheme;

  QuestionWithMarkscheme({required this.question, required this.markscheme});
}
