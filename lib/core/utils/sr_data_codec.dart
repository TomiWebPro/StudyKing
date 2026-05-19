import 'dart:convert';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';

class SrDataCodec {
  static QuestionSRData deserialize(String? json) {
    if (json == null || json.isEmpty) return const QuestionSRData();
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return QuestionSRData(
        repetitions: map['r'] as int? ?? 0,
        easeFactor: (map['ef'] as num?)?.toDouble() ?? 2.5,
        previousInterval: map['pi'] != null
            ? Duration(milliseconds: map['pi'] as int)
            : null,
        lastReview: map['lr'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['lr'] as int)
            : null,
      );
    } catch (e) {
      const Logger('SrDataCodec').w('Failed to deserialize SR data', e);
      return const QuestionSRData();
    }
  }

  static String serialize(QuestionSRData data) {
    return jsonEncode({
      'r': data.repetitions,
      'ef': data.easeFactor,
      if (data.previousInterval != null) 'pi': data.previousInterval!.inMilliseconds,
      if (data.lastReview != null) 'lr': data.lastReview!.millisecondsSinceEpoch,
    });
  }
}
