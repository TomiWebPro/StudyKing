import '../../errors/result.dart';
import '../models/question_model.dart';

/// Core interface for looking up a single question by ID.
///
/// Implemented by the questions feature's `QuestionRepository`;
/// core services depend on this interface (dependency inversion)
/// instead of the concrete repository so that core never imports
/// feature modules (see `test/architecture/architectural_constraints_test.dart`).
abstract class QuestionLookup {
  Future<Result<Question?>> get(String id);
}
