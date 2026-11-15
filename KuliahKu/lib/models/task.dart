import '../core/date_utils.dart';
import '../core/validators.dart';

enum TaskStatus { completed, overdue, today, tomorrow, soon, thisWeek, later }

/// Tugas kuliah. Immutable: perubahan dilakukan lewat [copyWith].
class Task {
  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.course = '',
    required this.dueDate,
    this.completed = false,
  });

  final String id;
  final String title;
  final String description;
  final String course;
  final DateTime dueDate;
  final bool completed;

  /// Kompatibel dengan format `tasks.json` versi lama.
  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id']?.toString() ?? generateId(),
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        course: json['course']?.toString() ?? '',
        dueDate: DateTime.tryParse(json['dueDate']?.toString() ?? '') ?? DateTime.now(),
        completed: json['completed'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'course': course,
        'dueDate': dueDate.toIso8601String(),
        'completed': completed,
      };

  Task copyWith({
    String? title,
    String? description,
    String? course,
    DateTime? dueDate,
    bool? completed,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        course: course ?? this.course,
        dueDate: dueDate ?? this.dueDate,
        completed: completed ?? this.completed,
      );

  /// Sisa hari kalender sampai tenggat (negatif = terlambat).
  int daysUntilDue([DateTime? now]) => AppDate.daysUntil(dueDate, from: now);

  TaskStatus status([DateTime? now]) {
    if (completed) return TaskStatus.completed;
    final days = daysUntilDue(now);
    if (days < 0) return TaskStatus.overdue;
    if (days == 0) return TaskStatus.today;
    if (days == 1) return TaskStatus.tomorrow;
    if (days <= 3) return TaskStatus.soon;
    if (days <= 7) return TaskStatus.thisWeek;
    return TaskStatus.later;
  }

  /// Belum selesai dan tenggat ≤ 3 hari lagi (termasuk yang sudah terlambat).
  bool isUrgent([DateTime? now]) => !completed && daysUntilDue(now) <= 3;

  /// Belum selesai dan tenggat dalam 0–7 hari ke depan.
  bool isDueThisWeek([DateTime? now]) {
    if (completed) return false;
    final days = daysUntilDue(now);
    return days >= 0 && days <= 7;
  }
}
