import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/dashboard.dart';

void main() {
  test('dashboard barrel export re-exports DashboardScreen', () {
    expect(DashboardScreen, isNotNull);
  });
}
