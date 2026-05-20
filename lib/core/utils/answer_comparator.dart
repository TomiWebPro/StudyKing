import 'string_extensions.dart';

class AnswerComparator {
  static bool areEquivalent(String user, String correct) {
    return user.normalized == correct.normalized;
  }
}
