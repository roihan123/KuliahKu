import '../core/date_utils.dart';
import '../core/validators.dart';

/// Jadwal kelas mingguan. Immutable.
class Schedule {
  Schedule({
    required this.id,
    required this.courseTitle,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.instructor = '',
    this.location = '',
  })  : startMinutes = AppDate.parseMinutes(startTime) ?? 0,
        endMinutes = AppDate.parseMinutes(endTime) ?? 0;

  final String id;
  final String courseTitle;

  /// Salah satu dari [AppDate.dayKeys], mis. `senin`.
  final String day;
  final String startTime;
  final String endTime;
  final String instructor;
  final String location;

  /// Di-cache saat konstruksi agar sorting / pengecekan bentrok murah.
  final int startMinutes;
  final int endMinutes;

  String get timeRange => '$startTime – $endTime';

  /// Kompatibel dengan format `jadwal.json` versi lama.
  factory Schedule.fromJson(Map<String, dynamic> json) {
    final day = json['day']?.toString().toLowerCase().trim() ?? 'senin';
    return Schedule(
      id: json['id']?.toString() ?? generateId(),
      courseTitle: json['courseTitle']?.toString() ?? '',
      day: AppDate.dayKeys.contains(day) ? day : 'senin',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      instructor: json['instructor']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseTitle': courseTitle,
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
        'instructor': instructor,
        'location': location,
      };

  bool overlaps(Schedule other) =>
      other.id != id &&
      other.day == day &&
      startMinutes < other.endMinutes &&
      other.startMinutes < endMinutes;

  bool isOngoingAt(DateTime now) {
    if (AppDate.dayKeyOf(now) != day) return false;
    final m = AppDate.minutesOfDay(now);
    return m >= startMinutes && m < endMinutes;
  }

  bool hasEndedAt(DateTime now) =>
      AppDate.dayKeyOf(now) == day && AppDate.minutesOfDay(now) >= endMinutes;
}
