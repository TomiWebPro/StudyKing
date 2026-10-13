import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';

class PlanAdherenceRepository extends Repository<PlanAdherenceModel> {
  static final Logger _logger = const Logger('PlanAdherenceRepository');
  final Clock _clock;

  PlanAdherenceRepository({Clock? clock})
      : _clock = clock ?? SystemClock(),
        super(boxName: HiveBoxNames.planAdherence);

  Future<Result<void>> init() async {
    return Result.capture(() async {
      await openBox(HiveBoxNames.planAdherence);
    }, context: 'init');
  }

  Future<Result<void>> create(PlanAdherenceModel model) async {
    // Repository.save reports write failures as Result.failure (it does not
    // throw), so the result must be propagated — discarding it here would
    // mask a failed adherence write as success.
    final result = await super.save(model.id, model);
    if (result.isFailure) {
      _logger.w('Failed to persist plan adherence ${model.id}', result.error);
    }
    return result;
  }

  Future<Result<List<PlanAdherenceModel>>> getByStudent(String studentId) async {
    return Result.capture(() async {
      final results = filterBy((m) => m.studentId, studentId)
        ..sort((a, b) => b.date.compareTo(a.date));
      return results;
    }, context: 'getByStudent');
  }

  Future<Result<List<PlanAdherenceModel>>> getByDateRange(
      String studentId, DateTime start, DateTime end) async {
    return Result.capture(() async {
      final byStudent = filterBy((m) => m.studentId, studentId);
      return byStudent
          .where((m) => m.date.isAfter(start) && m.date.isBefore(end))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }, context: 'getByDateRange');
  }

  Future<Result<List<PlanAdherenceModel>>> getWeekly(String studentId) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(Timeouts.week);
    return getByDateRange(studentId, weekAgo, now);
  }

  Future<Result<double>> getAverageAdherence(String studentId) async {
    return Result.capture(() async {
      final metricsResult = await getByStudent(studentId);
      if (metricsResult.isFailure) return 0.0;
      final metrics = metricsResult.data!;
      if (metrics.isEmpty) return 0.0;
      return metrics.fold<double>(0.0, (sum, m) => sum + m.adherenceScore) /
          metrics.length;
    }, context: 'getAverageAdherence');
  }

  Future<Result<int>> getConsecutiveLowAdherenceDays(String studentId,
      {double threshold = 0.5}) async {
    return Result.capture(() async {
      final metricsResult = await getByStudent(studentId);
      if (metricsResult.isFailure) return 0;
      final metrics = metricsResult.data!;
      int consecutive = 0;
      for (final metric in metrics) {
        if (metric.adherenceScore < threshold) {
          consecutive++;
        } else {
          break;
        }
      }
      return consecutive;
    }, context: 'getConsecutiveLowAdherenceDays');
  }

  Future<Result<PlanAdherenceModel?>> getToday(String studentId) async {
    return Result.capture(() async {
      final today = _clock.now();
      final startOfDay = today.dateOnly;
      // Calendar-day bound: DST-transition days are 23h/25h long, so a fixed
      // 24h span (`startOfDay.add(Timeouts.day)`) is not the next local midnight.
      final endOfDay = DateTime(startOfDay.year, startOfDay.month, startOfDay.day + 1);
      final todayMetrics = filterBy((m) => m.studentId, studentId).where(
          (m) => !m.date.isBefore(startOfDay) && m.date.isBefore(endOfDay));
      return todayMetrics.isNotEmpty ? todayMetrics.first : null;
    }, context: 'getToday');
  }

  Future<Result<void>> deleteByStudent(String studentId) async {
    try {
      final metrics = filterBy((m) => m.studentId, studentId);
      for (final m in metrics) {
        final result = await super.delete(m.id);
        if (result.isFailure) {
          _logger.w('Failed to delete plan adherence ${m.id}', result.error);
          return result;
        }
      }
      return Result.success(null);
    } catch (e) {
      _logger.w(
          'Failed to delete plan adherence records for $studentId', e);
      return Result.failure(e.toString());
    }
  }
}
