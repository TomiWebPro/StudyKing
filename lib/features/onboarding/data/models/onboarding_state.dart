class OnboardingState {
  final bool completed;
  final bool dontShowAgain;

  const OnboardingState({
    this.completed = false,
    this.dontShowAgain = false,
  });

  OnboardingState copyWith({
    bool? completed,
    bool? dontShowAgain,
  }) {
    return OnboardingState(
      completed: completed ?? this.completed,
      dontShowAgain: dontShowAgain ?? this.dontShowAgain,
    );
  }

  bool get isNeeded => !completed && !dontShowAgain;

  bool get isFirstLaunch => !completed;

  Map<String, dynamic> toJson() => {
    'completed': completed,
    'dontShowAgain': dontShowAgain,
  };

  factory OnboardingState.fromJson(Map<String, dynamic> json) => OnboardingState(
    completed: json['completed'] as bool? ?? false,
    dontShowAgain: json['dontShowAgain'] as bool? ?? false,
  );
}
