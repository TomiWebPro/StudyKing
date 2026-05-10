enum AppFeature { analytics, crashReporting, betaFeatures, performanceOptimization }

class FeatureFlagService {
  FeatureFlagService({Map<AppFeature, bool>? overrides})
    : _overrides = Map.unmodifiable({...?overrides});

  final Map<AppFeature, bool> _overrides;

  static const Map<AppFeature, bool> _defaults = <AppFeature, bool>{
    AppFeature.analytics: false,
    AppFeature.crashReporting: false,
    AppFeature.betaFeatures: false,
    AppFeature.performanceOptimization: true,
  };

  bool isEnabled(AppFeature feature) {
    assert(_defaults.containsKey(feature), 'Missing default for feature: $feature');
    return _overrides[feature] ?? _defaults[feature]!;
  }
}
