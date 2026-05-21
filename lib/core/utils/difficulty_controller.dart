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
      _currentDifficulty = (_currentDifficulty + 1).clamp(minDifficulty, maxDifficulty);
    } else if (_consecutiveIncorrect >= incorrectStreakThreshold) {
      _currentDifficulty = (_currentDifficulty - 1).clamp(minDifficulty, maxDifficulty);
    }
    return _currentDifficulty;
  }

  void reset({int? initialDifficulty}) {
    _consecutiveCorrect = 0;
    _consecutiveIncorrect = 0;
    if (initialDifficulty != null) {
      _currentDifficulty = initialDifficulty.clamp(minDifficulty, maxDifficulty);
    } else {
      _currentDifficulty = 1;
    }
  }
}
