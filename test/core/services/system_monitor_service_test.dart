import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/system_monitor_service.dart';

void main() {
  group('SystemMonitorService.shouldDeferDueToBattery', () {
    test('returns false when charging, even with low battery', () {
      expect(SystemMonitorService.shouldDeferDueToBattery(15, true), isFalse);
    });

    test('returns false when battery is unknown (-1), regardless of charging',
        () {
      expect(SystemMonitorService.shouldDeferDueToBattery(-1, false), isFalse);
      expect(SystemMonitorService.shouldDeferDueToBattery(-1, true), isFalse);
    });

    test('returns true when battery is below threshold and not charging', () {
      expect(SystemMonitorService.shouldDeferDueToBattery(19, false), isTrue);
    });

    test('returns false when battery equals threshold and not charging', () {
      expect(SystemMonitorService.shouldDeferDueToBattery(20, false), isFalse);
    });

    test('returns false when battery is above threshold and not charging', () {
      expect(SystemMonitorService.shouldDeferDueToBattery(21, false), isFalse);
      expect(
        SystemMonitorService.shouldDeferDueToBattery(100, false),
        isFalse,
      );
    });

    test('respects a custom low-threshold', () {
      expect(
        SystemMonitorService.shouldDeferDueToBattery(10, false, lowThreshold: 15),
        isTrue,
      );
      expect(
        SystemMonitorService.shouldDeferDueToBattery(15, false, lowThreshold: 15),
        isFalse,
      );
    });
  });

  group('SystemMonitorService.shouldDeferDueToCpu', () {
    test('returns false when CPU load is unknown (-1)', () {
      expect(SystemMonitorService.shouldDeferDueToCpu(-1), isFalse);
    });

    test('returns true when CPU load exceeds threshold', () {
      expect(SystemMonitorService.shouldDeferDueToCpu(0.81), isTrue);
      expect(SystemMonitorService.shouldDeferDueToCpu(1.0), isTrue);
    });

    test('returns false when CPU load equals threshold (exclusive)', () {
      expect(SystemMonitorService.shouldDeferDueToCpu(0.8), isFalse);
    });

    test('returns false when CPU load is below threshold', () {
      expect(SystemMonitorService.shouldDeferDueToCpu(0.5), isFalse);
      expect(SystemMonitorService.shouldDeferDueToCpu(0.0), isFalse);
    });

    test('respects a custom high-threshold', () {
      expect(
        SystemMonitorService.shouldDeferDueToCpu(0.7, highThreshold: 0.7),
        isFalse,
      );
      expect(
        SystemMonitorService.shouldDeferDueToCpu(0.71, highThreshold: 0.7),
        isTrue,
      );
    });
  });

  group('NoopSystemMonitorService', () {
    test('always reports healthy state (can run heavy prep)', () {
      const monitor = NoopSystemMonitorService();
      expect(monitor.canRunHeavyPrepNow, isTrue);
      expect(monitor.batteryLevel, -1);
      expect(monitor.isCharging, isFalse);
      expect(monitor.cpuLoad, -1);
      expect(monitor.isBatterySaver, isFalse);
      expect(monitor.networkType, isNull);
    });

    test('listener methods do not throw', () {
      const monitor = NoopSystemMonitorService();
      expect(() => monitor.addListener(() {}), returnsNormally);
      expect(() => monitor.removeListener(() {}), returnsNormally);
    });
  });

  group('FakeSystemMonitorService', () {
    test('can configure canRunHeavyPrepNow', () {
      final healthy = FakeSystemMonitorService(
        canRunHeavyPrepNow: true,
        batteryLevel: 80,
        isCharging: false,
        cpuLoad: 0.3,
        isBatterySaver: false,
        networkType: 'wifi',
      );
      expect(healthy.canRunHeavyPrepNow, isTrue);
      expect(healthy.batteryLevel, 80);
      expect(healthy.cpuLoad, 0.3);
      expect(healthy.networkType, 'wifi');

      final stressed = FakeSystemMonitorService(
        canRunHeavyPrepNow: false,
        batteryLevel: 15,
        isCharging: false,
        cpuLoad: 0.95,
        isBatterySaver: true,
        networkType: 'cellular',
      );
      expect(stressed.canRunHeavyPrepNow, isFalse);
      expect(stressed.batteryLevel, 15);
      expect(stressed.cpuLoad, 0.95);
      expect(stressed.isBatterySaver, isTrue);
      expect(stressed.networkType, 'cellular');
    });

    test('defaults to healthy state', () {
      final monitor = FakeSystemMonitorService();
      expect(monitor.canRunHeavyPrepNow, isTrue);
      expect(monitor.batteryLevel, -1);
      expect(monitor.isCharging, false);
      expect(monitor.cpuLoad, -1);
      expect(monitor.isBatterySaver, false);
      expect(monitor.networkType, null);
    });
  });
}

/// Hand-written fake [SystemMonitorService] for deterministic testing.
///
/// Mirrors the pattern documented in
/// `lib/core/services/system_monitor_service.dart` (doc comment references
/// `[FakeSystemMonitorService]` in tests). All values are configurable so
/// tests can drive the deferral logic without platform sensors.
class FakeSystemMonitorService extends SystemMonitorService {
  final bool _canRunHeavyPrepNow;
  final int _batteryLevel;
  final bool _isCharging;
  final double _cpuLoad;
  final bool _isBatterySaver;
  final String? _networkType;

  FakeSystemMonitorService({
    bool canRunHeavyPrepNow = true,
    int batteryLevel = -1,
    bool isCharging = false,
    double cpuLoad = -1,
    bool isBatterySaver = false,
    String? networkType,
  })  : _canRunHeavyPrepNow = canRunHeavyPrepNow,
        _batteryLevel = batteryLevel,
        _isCharging = isCharging,
        _cpuLoad = cpuLoad,
        _isBatterySaver = isBatterySaver,
        _networkType = networkType;

  @override
  bool get canRunHeavyPrepNow => _canRunHeavyPrepNow;

  @override
  int get batteryLevel => _batteryLevel;

  @override
  bool get isCharging => _isCharging;

  @override
  double get cpuLoad => _cpuLoad;

  @override
  bool get isBatterySaver => _isBatterySaver;

  @override
  String? get networkType => _networkType;
}
