enum AppFeature { analytics, crashReporting, betaFeatures, performanceOptimization }

class FeatureFlagService {
  FeatureFlagService({Map<AppFeature, bool>? overrides}) : _overrides = overrides ?? const {};

  final Map<AppFeature, bool> _overrides;

  static const Map<AppFeature, bool> _defaults = {
    AppFeature.analytics: false,
    AppFeature.crashReporting: false,
    AppFeature.betaFeatures: false,
    AppFeature.performanceOptimization: true,
  };

  bool isEnabled(AppFeature feature) => _overrides[feature] ?? _defaults[feature] ?? false;
}
