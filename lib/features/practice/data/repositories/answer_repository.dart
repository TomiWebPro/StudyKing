import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/answer_model.dart';
import 'package:studyking/core/data/repository.dart';

class AnswerRepository extends Repository<Answer> {
  Future<void> init() async {
    await openBox(HiveBoxNames.answers);
  }

  Future<void> create(Answer answer) async {
    await save(answer.id, answer);
  }

  Future<List<Answer>> getByQuestion(String questionId) async {
    return filterBy((a) => a.questionId, questionId);
  }
}
