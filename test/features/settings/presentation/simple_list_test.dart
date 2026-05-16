import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('simple list test', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Test')),
        body: ListView(
          children: List.generate(20, (i) => ListTile(title: Text('Item $i'))),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    
    // ignore: avoid_print
    print('Found Item 15: ${find.text("Item 15").evaluate().length}');
    // ignore: avoid_print
    print('Found Item 19: ${find.text("Item 19").evaluate().length}');
    
    // Also check all items
    for (int i = 0; i < 20; i++) {
      final count = find.text('Item $i').evaluate().length;
      if (count == 0) {
        // ignore: avoid_print
        print('Item $i NOT FOUND!');
      }
    }
    // ignore: avoid_print
    print('Total ListTiles: ${find.byType(ListTile).evaluate().length}');
  });
}
