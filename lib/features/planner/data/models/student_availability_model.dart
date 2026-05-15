import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 35)
class StudentAvailabilityModel extends HiveObject {
  @HiveField(0)
  final String studentId;

  @HiveField(1)
  final List<int> preferredStudyDays;

  @HiveField(2)
  final int preferredStartHour;

  @HiveField(3)
  final int preferredEndHour;

  @HiveField(4)
  final int maxSessionsPerDay;

  @HiveField(5)
  final int defaultSessionDurationMinutes;

  @HiveField(6)
  final List<DateTime> blackoutDates;

  StudentAvailabilityModel({
    required this.studentId,
    this.preferredStudyDays = const [1, 2, 3, 4, 5, 6, 7],
    this.preferredStartHour = 9,
    this.preferredEndHour = 21,
    this.maxSessionsPerDay = 3,
    this.defaultSessionDurationMinutes = 30,
    this.blackoutDates = const [],
  });

  StudentAvailabilityModel copyWith({
    String? studentId,
    List<int>? preferredStudyDays,
    int? preferredStartHour,
    int? preferredEndHour,
    int? maxSessionsPerDay,
    int? defaultSessionDurationMinutes,
    List<DateTime>? blackoutDates,
  }) {
    return StudentAvailabilityModel(
      studentId: studentId ?? this.studentId,
      preferredStudyDays: preferredStudyDays ?? this.preferredStudyDays,
      preferredStartHour: preferredStartHour ?? this.preferredStartHour,
      preferredEndHour: preferredEndHour ?? this.preferredEndHour,
      maxSessionsPerDay: maxSessionsPerDay ?? this.maxSessionsPerDay,
      defaultSessionDurationMinutes: defaultSessionDurationMinutes ?? this.defaultSessionDurationMinutes,
      blackoutDates: blackoutDates ?? this.blackoutDates,
    );
  }

  bool isAvailableOn(DateTime date) {
    if (blackoutDates.any((b) =>
        b.year == date.year && b.month == date.month && b.day == date.day)) {
      return false;
    }
    return preferredStudyDays.contains(date.weekday);
  }

  int get preferredStudyHoursPerDay => preferredEndHour - preferredStartHour;
}
