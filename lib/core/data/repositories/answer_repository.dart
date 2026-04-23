import 'package:hive_flutter/hive_flutter.dart';
import '../models/answer_model.dart';

class AnswerRepository {
  late Box<Answer> _box;

  Future<void> init() async {
    _box = Hive.box<Answer>('answers');
  }

  Future<void> create(Answer answer) async {
    await _box.put(answer.id, answer);
  }

  Future<Answer?> get(String id) async {
    return _box.get(id);
  }

  Future<List<Answer>> getByQuestion(String questionId) async {
    final all = _box.values.toList();
    return all.where((a) => a.questionId == questionId).toList();
  }
}
