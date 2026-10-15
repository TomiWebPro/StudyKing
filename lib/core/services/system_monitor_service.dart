import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb, VoidCallback;
import 'package:studyking/core/utils/logger.dart';

/// Vision-next-term §4.3 — CPU / system monitoring for off-period prep.
///
/// Heavy off-period preparation (embeddings, question-variant generation,
/// lesson pre-generation) must defer when the device is stressed — e.g.
/// CPU > 80%, battery < 20%, or battery-saver active — so preparation never
/// janks the student's screen or drains their battery.
///
/// All reads are **best-effort**: when a sensor is unavailable on a given
/// platform the service reports a *healthy* state, because we must never
/// silently block prep we cannot measure. The [IdleExecutor] consults
/// [canRunHeavyPrepNow] before running a heavy task; tests inject a
/// hand-written fake ([FakeSystemMonitorService] in tests) to drive the
/// deferral logic deterministically, so this real implementation is never
/// exercised by the unit-test suite.
abstract class SystemMonitorService {
  const SystemMonitorService();

  /// True when the device can currently run a heavy prep job without risk of
  /// jank, heat, or excessive battery drain. Heavy tasks must call this before
  /// starting and defer (leave themselves in the queue) when it is false.
  bool get canRunHeavyPrepNow;

  /// Battery level 0..100, or -1 when unknown/unavailable.
  int get batteryLevel;

  /// Whether the device is currently plugged in / charging.
  bool get isCharging;

  /// Current CPU load as a fraction 0..1, or -1 when unknown/unavailable.
  double get cpuLoad;

  /// True when a system battery-saver / low-power mode is engaged.
  bool get isBatterySaver;

  /// Network class: `'wifi'`, `'cellular'`, or `null` when undeterminable.
  String? get networkType;

  void addListener(VoidCallback listener) {}
  void removeListener(VoidCallback listener) {}

  // ------------------------------------------------------------------
  // Pure, side-effect-free threshold helpers. These encode the gating
  // policy and are unit-tested directly so the policy is never implicit.
  // ------------------------------------------------------------------

  /// Defer heavy work while on battery with a charge below [lowThreshold].
  /// Unknown battery (-1) or a charging device never triggers this deferral.
  static bool shouldDeferDueToBattery(
    int batteryLevel,
    bool isCharging, {
    int lowThreshold = 20,
  }) {
    if (isCharging) return false;
    if (batteryLevel < 0) return false;
    return batteryLevel < lowThreshold;
  }

  /// Defer heavy work while the CPU is saturated above [highThreshold].
  /// Unknown load (-1) never triggers this deferral.
  static bool shouldDeferDueToCpu(double cpuLoad, {double highThreshold = 0.8}) {
    if (cpuLoad < 0) return false;
    return cpuLoad > highThreshold;
  }
}

/// A monitor that always reports a healthy state.
///
/// Used on web (where Flutter exposes no battery/CPU sensors) and as the
/// fallback when platform monitoring is unavailable, so heavy prep is never
/// blocked purely because monitoring cannot run.
class NoopSystemMonitorService extends SystemMonitorService {
  const NoopSystemMonitorService();

  @override
  bool get canRunHeavyPrepNow => true;

  @override
  int get batteryLevel => -1;

  @override
  bool get isCharging => false;

  @override
  double get cpuLoad => -1;

  @override
  bool get isBatterySaver => false;

  @override
  String? get networkType => null;
}

/// A best-effort, cross-platform implementation that reads battery and load
/// averages directly from the OS where available. Any read failure degrades to
/// a healthy signal (never blocks prep) and is logged at [w]; decisions are
/// logged at [d].
///
/// On Linux this reads `/proc/loadavg` (1-minute load average ÷ processor
/// count) and `/sys/class/power_supply/*/capacity` + `status`. On other
/// desktop/mobile platforms, or when a read is unavailable, it reports the
/// healthy default so prep proceeds.
class PlatformSystemMonitorService extends SystemMonitorService {
  static final Logger _logger = const Logger('PlatformSystemMonitorService');

  static const Duration _cacheTtl = Duration(seconds: 2);

  _Sample? _cached;
  DateTime? _cachedAt;

  @override
  bool get canRunHeavyPrepNow {
    final sample = _sample();
    if (SystemMonitorService.shouldDeferDueToBattery(
      sample.batteryLevel,
      sample.isCharging,
    )) {
      _logger.d(
        'Deferring heavy prep: battery low (${sample.batteryLevel}%) on battery',
      );
      return false;
    }
    if (sample.batterySaver) {
      _logger.d('Deferring heavy prep: battery-saver active');
      return false;
    }
    if (SystemMonitorService.shouldDeferDueToCpu(sample.cpuLoad)) {
      _logger.d(
        'Deferring heavy prep: CPU load high (${(sample.cpuLoad * 100).toStringAsFixed(0)}%)',
      );
      return false;
    }
    return true;
  }

  @override
  int get batteryLevel => _sample().batteryLevel;

  @override
  bool get isCharging => _sample().isCharging;

  @override
  double get cpuLoad => _sample().cpuLoad;

  @override
  bool get isBatterySaver => _sample().batterySaver;

  @override
  String? get networkType => _sample().networkType;

  _Sample _sample() {
    if (kIsWeb) return _Sample.healthy;
    final now = DateTime.now();
    if (_cached != null && _cachedAt != null && now.difference(_cachedAt!) < _cacheTtl) {
      return _cached!;
    }
    _cached = _readPlatform();
    _cachedAt = now;
    return _cached!;
  }

  _Sample _readPlatform() {
    try {
      final cpu = _readCpuLoad();
      final battery = _readBattery();
      return _Sample(
        batteryLevel: battery.level,
        isCharging: battery.charging,
        cpuLoad: cpu,
        batterySaver: false,
        networkType: null,
      );
    } catch (e) {
      _logger.w('Failed to sample system state; reporting healthy', e);
      return _Sample.healthy;
    }
  }

  /// Linux 1-minute load average divided by processor count (0..1).
  double _readCpuLoad() {
    if (kIsWeb) return -1;
    try {
      final loadavg = File('/proc/loadavg').readAsStringSync();
      final load = double.parse(loadavg.split(' ').first);
      final cores = Platform.numberOfProcessors;
      if (cores > 0) {
        final v = load / cores;
        return v < 0 ? 0.0 : (v > 1 ? 1.0 : v);
      }
      return -1;
    } catch (e) {
      _logger.w('Could not read CPU load average', e);
      return -1;
    }
  }

  /// Reads `/sys/class/power_supply/BAT0|BAT1` capacity + status.
  _BatterySample _readBattery() {
    if (kIsWeb) return const _BatterySample(level: -1, charging: false);
    for (final name in ['BAT0', 'BAT1']) {
      final base = '/sys/class/power_supply/$name';
      if (!Directory(base).existsSync()) continue;
      try {
        int level = -1;
        var charging = false;
        final cap = File('$base/capacity');
        if (cap.existsSync()) {
          level = int.parse(cap.readAsStringSync().trim());
        }
        final status = File('$base/status');
        if (status.existsSync()) {
          final s = status.readAsStringSync().trim();
          charging = s == 'Charging' || s == 'Full';
        }
        return _BatterySample(level: level, charging: charging);
      } catch (e) {
        _logger.w('Failed to read battery info for $name', e);
      }
    }
    return const _BatterySample(level: -1, charging: false);
  }
}

class _Sample {
  final int batteryLevel;
  final bool isCharging;
  final double cpuLoad;
  final bool batterySaver;
  final String? networkType;

  const _Sample({
    required this.batteryLevel,
    required this.isCharging,
    required this.cpuLoad,
    required this.batterySaver,
    required this.networkType,
  });

  static const _Sample healthy = _Sample(
    batteryLevel: -1,
    isCharging: false,
    cpuLoad: -1,
    batterySaver: false,
    networkType: null,
  );
}

class _BatterySample {
  final int level;
  final bool charging;

  const _BatterySample({required this.level, required this.charging});
}
