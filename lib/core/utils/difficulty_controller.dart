class DifficultyController {
  int _consecutiveCorrect = 0;
  int _consecutiveIncorrect = 0;
  int _currentDifficulty;

  final int minDifficulty;
  final int maxDifficulty;
  final int correctStreakThreshold;
  final int incorrectStreakThreshold;

  DifficultyController({
    int initialDifficulty = 1,
    this.minDifficulty = 1,
    this.maxDifficulty = 5,
    this.correctStreakThreshold = 3,
    this.incorrectStreakThreshold = 2,
  }) : _currentDifficulty = initialDifficulty;

  int get currentDifficulty => _currentDifficulty;

  int _clampDifficulty(int value) {
    final lo = minDifficulty <= maxDifficulty ? minDifficulty : maxDifficulty;
    final hi = minDifficulty <= maxDifficulty ? maxDifficulty : minDifficulty;
    return value.clamp(lo, hi);
  }

  void recordResult(bool isCorrect) {
    if (isCorrect) {
      _consecutiveCorrect++;
      _consecutiveIncorrect = 0;
    } else {
      _consecutiveIncorrect++;
      _consecutiveCorrect = 0;
    }
  }

  int suggestNextDifficulty() {
    if (_consecutiveCorrect >= correctStreakThreshold) {
      _currentDifficulty = _clampDifficulty(_currentDifficulty + 1);
    } else if (_consecutiveIncorrect >= incorrectStreakThreshold) {
      _currentDifficulty = _clampDifficulty(_currentDifficulty - 1);
    }
    return _currentDifficulty;
  }

  void reset({int? initialDifficulty}) {
    _consecutiveCorrect = 0;
    _consecutiveIncorrect = 0;
    if (initialDifficulty != null) {
      _currentDifficulty = _clampDifficulty(initialDifficulty);
    } else {
      _currentDifficulty = 1;
    }
  }
}
