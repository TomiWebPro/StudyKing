import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/presentation/screens/topic_detail_screen.dart';

void main() {
  group('TopicDetailArgs', () {
    test('constructs with topicId and studentId', () {
      const args = TopicDetailArgs(topicId: 't1', studentId: 's1');
      expect(args.topicId, 't1');
      expect(args.studentId, 's1');
    });
  });
}
