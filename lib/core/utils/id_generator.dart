class IdGenerator {
  static int _counter = 0;

  static String generate(String prefix) {
    _counter++;
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}_$_counter';
  }

  static void reset() {
    _counter = 0;
  }
}
