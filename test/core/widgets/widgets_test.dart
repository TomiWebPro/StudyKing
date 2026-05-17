import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/widgets/widgets.dart';

void main() {
  group('core/widgets barrel exports', () {
    test('AnimatedBarChart has static minBarWidth constant', () {
      expect(AnimatedBarChart.minBarWidth, 24.0);
    });

    test('ConversationInput can be instantiated with required fields', () {
      final controller = TextEditingController();
      final input = ConversationInput(
        controller: controller,
        hintText: 'Type here',
        sendTooltip: 'Send',
        onSend: () {},
      );
      expect(input.controller, controller);
      expect(input.hintText, 'Type here');
      expect(input.sendTooltip, 'Send');
      controller.dispose();
    });

    test('GradientContainer can be instantiated with required fields', () {
      final container = GradientContainer(
        accent: Colors.blue,
        child: const SizedBox(),
      );
      expect(container.accent, Colors.blue);
      expect(container.child, isA<SizedBox>());
      expect(container.borderRadius, 12);
    });

    test('MetricCard can be instantiated with required fields', () {
      final card = MetricCard(
        icon: Icons.star,
        value: '85',
        label: 'Score',
        accent: Colors.blue,
      );
      expect(card.icon, Icons.star);
      expect(card.value, '85');
      expect(card.label, 'Score');
      expect(card.accent, Colors.blue);
    });

    test('NotFoundScreen can be instantiated with optional message', () {
      final screen = NotFoundScreen(message: 'Page not found');
      expect(screen.message, 'Page not found');
    });
  });
}
