import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/widgets/widgets.dart';

void main() {
  group('core/widgets barrel exports', () {
    test('exports AnimatedBarChart', () {
      expect(AnimatedBarChart, isA<Type>());
    });

    test('exports ConversationInput', () {
      expect(ConversationInput, isA<Type>());
    });

    test('exports GradientContainer', () {
      expect(GradientContainer, isA<Type>());
    });

    test('exports MetricCard', () {
      expect(MetricCard, isA<Type>());
    });
  });
}
