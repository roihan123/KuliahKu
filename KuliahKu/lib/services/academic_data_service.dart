import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/date_utils.dart';
import '../models/app_notification.dart';
import '../models/note.dart';
import '../models/schedule.dart';
import '../models/task.dart';
import 'json_storage.dart';

/// Mengelola seluruh data akademik (Jadwal, Tugas, Catatan, dan status baca
/// Notifikasi) dalam satu `ChangeNotifier` terpusat.
///
/// Keuntungan:
/// - Semua tab (Beranda, Jadwal, Tugas, Catatan, Kalender, Notifikasi) selalu
///   sinkron secara instan tanpa perlu membaca ulang file JSON setiap pindah halaman.
/// - Mendukung operasi Undo saat menghapus item.
class AcademicDataService extends ChangeNotifier {
  AcademicDataService(this._storage);

  static const String _tasksFile = 'tasks.json';
  static const String _notesFile = 'notes.json';
  static const String _schedulesFile = 'jadwal.json';
  static const String _notifStateFile = 'notifications_state.json';

  final JsonStorage _storage;

  final List<Task> _tasks = [];
  final List<Note> _notes = [];
  final List<Schedule> _schedules = [];
  final Set<String> _readNotificationIds = {};

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Note> get notes => List.unmodifiable(_notes);
  List<Schedule> get schedules => List.unmodifiable(_schedules);

  /// Muat semua data secara paralel saat aplikasi dibuka atau di-refresh.
  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    final results = await Future.wait<Object?>([
      _storage.readList(_tasksFile),
      _storage.readList(_notesFile),
      _storage.readList(_schedulesFile),
      _storage.readMap(_notifStateFile),
    ]);

    final rawTasks = results[0]! as List<Map<String, dynamic>>;
    final rawNotes = results[1]! as List<Map<String, dynamic>>;
    final rawSchedules = results[2]! as List<Map<String, dynamic>>;
    final rawNotifState = results[3] as Map<String, dynamic>?;

    _tasks
      ..clear()
      ..addAll(rawTasks.map(Task.fromJson));
    _sortTasks();

    _notes
      ..clear()
      ..addAll(rawNotes.map(Note.fromJson));
    _sortNotes();

    _schedules
      ..clear()
      ..addAll(rawSchedules.map(Schedule.fromJson));
    _sortSchedules();

    _readNotificationIds.clear();
    final readList = rawNotifState?['readIds'];
    if (readList is List) {
      for (final item in readList) {
        if (item is String) _readNotificationIds.add(item);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Koleksi terhitung (computed) untuk berbagai halaman
  // ---------------------------------------------------------------------------

  /// Daftar nama mata kuliah unik dari jadwal, tugas, dan catatan (untuk saran input).
  List<String> get knownCourses {
    final set = <String>{};
    for (final s in _schedules) {
      if (s.courseTitle.trim().isNotEmpty) set.add(s.courseTitle.trim());
    }
    for (final t in _tasks) {
      if (t.course.trim().isNotEmpty) set.add(t.course.trim());
    }
    for (final n in _notes) {
      if (n.course.trim().isNotEmpty) set.add(n.course.trim());
    }
    final list = set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  /// Jadwal untuk hari tertentu (`senin`..`minggu`), sudah terurut jam mulai.
  List<Schedule> schedulesForDay(String dayKey) =>
      _schedules.where((s) => s.day == dayKey.toLowerCase()).toList(growable: false);

  /// Jadwal untuk tanggal tertentu.
  List<Schedule> schedulesForDate(DateTime date) => schedulesForDay(AppDate.dayKeyOf(date));

  /// Tugas yang jatuh tempo pada tanggal tertentu.
  List<Task> tasksForDate(DateTime date) =>
      _tasks.where((t) => AppDate.isSameDay(t.dueDate, date)).toList(growable: false);

  /// Tugas mendesak (belum selesai dan tenggat ≤ 3 hari lagi atau terlambat).
  List<Task> urgentTasks([DateTime? now]) {
    final ref = now ?? DateTime.now();
    return _tasks.where((t) => t.isUrgent(ref)).toList(growable: false);
  }

  /// 3 catatan terakhir yang diperbarui.
  List<Note> get recentNotes => _notes.take(3).toList(growable: false);

  /// Kategori mata kuliah unik pada catatan.
  List<String> get noteCategories {
    final set = <String>{};
    for (final note in _notes) {
      final c = note.course.trim();
      if (c.isNotEmpty) set.add(c);
    }
    final list = set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  /// Cari jadwal lain di hari yang sama yang waktunya bertabrakan dengan [candidate].
  List<Schedule> findConflictingSchedules(Schedule candidate) =>
      _schedules.where((s) => s.overlaps(candidate)).toList(growable: false);

  // ---------------------------------------------------------------------------
  // Operasi Tugas (Tasks)
  // ---------------------------------------------------------------------------

  Future<void> upsertTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _tasks[index] = task;
    } else {
      _tasks.add(task);
    }
    _sortTasks();
    notifyListeners();
    await _saveTasks();
  }

  Future<void> toggleTaskCompleted(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index < 0) return;
    final current = _tasks[index];
    _tasks[index] = current.copyWith(completed: !current.completed);
    _sortTasks();
    notifyListeners();
    await _saveTasks();
  }

  Future<Task?> deleteTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index < 0) return null;
    final removed = _tasks.removeAt(index);
    notifyListeners();
    await _saveTasks();
    return removed;
  }

  // ---------------------------------------------------------------------------
  // Operasi Catatan (Notes)
  // ---------------------------------------------------------------------------

  Future<void> upsertNote(Note note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      _notes[index] = note;
    } else {
      _notes.add(note);
    }
    _sortNotes();
    notifyListeners();
    await _saveNotes();
  }

  Future<Note?> deleteNote(String noteId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index < 0) return null;
    final removed = _notes.removeAt(index);
    notifyListeners();
    await _saveNotes();
    return removed;
  }

  // ---------------------------------------------------------------------------
  // Operasi Jadwal (Schedules)
  // ---------------------------------------------------------------------------

  Future<void> upsertSchedule(Schedule schedule) async {
    final index = _schedules.indexWhere((s) => s.id == schedule.id);
    if (index >= 0) {
      _schedules[index] = schedule;
    } else {
      _schedules.add(schedule);
    }
    _sortSchedules();
    notifyListeners();
    await _saveSchedules();
  }

  Future<Schedule?> deleteSchedule(String scheduleId) async {
    final index = _schedules.indexWhere((s) => s.id == scheduleId);
    if (index < 0) return null;
    final removed = _schedules.removeAt(index);
    notifyListeners();
    await _saveSchedules();
    return removed;
  }

  // ---------------------------------------------------------------------------
  // Notifikasi In-App
  // ---------------------------------------------------------------------------

  List<AppNotificationItem> buildNotifications([DateTime? now]) {
    final ref = now ?? DateTime.now();
    final todayStr = '${ref.year}-${ref.month}-${ref.day}';
    final items = <AppNotificationItem>[];

    // 1. Tugas yang terlambat, jatuh tempo hari ini, atau dalam 3 hari ke depan
    for (final task in _tasks) {
      if (task.completed) continue;
      final days = task.daysUntilDue(ref);
      if (days > 3) continue;

      final String id;
      final AppNotificationType type;
      final String title;
      final String detail;
      final Color color;
      final IconData icon;

      if (days < 0) {
        id = 'task_overdue_${task.id}_$todayStr';
        type = AppNotificationType.overdueTask;
        title = 'Tugas Terlambat (${-days} hari)';
        detail = 'Tenggat: ${AppDate.fullDate(task.dueDate)}';
        color = AppColors.danger;
        icon = Icons.warning_amber_rounded;
      } else if (days == 0) {
        id = 'task_today_${task.id}_$todayStr';
        type = AppNotificationType.dueTodayTask;
        title = 'Tenggat Hari Ini!';
        detail = 'Selesaikan sebelum hari berakhir (${AppDate.dayMonth(task.dueDate)})';
        color = AppColors.warning;
        icon = Icons.alarm_rounded;
      } else if (days == 1) {
        id = 'task_tomorrow_${task.id}_$todayStr';
        type = AppNotificationType.dueSoonTask;
        title = 'Tenggat Besok';
        detail = 'Jatuh tempo ${AppDate.fullDate(task.dueDate)}';
        color = AppColors.warning;
        icon = Icons.schedule_rounded;
      } else {
        id = 'task_soon_${task.id}_$todayStr';
        type = AppNotificationType.dueSoonTask;
        title = 'Tenggat $days Hari Lagi';
        detail = 'Jatuh tempo ${AppDate.fullDate(task.dueDate)}';
        color = AppColors.info;
        icon = Icons.assignment_late_outlined;
      }

      final courseSuffix = task.course.trim().isNotEmpty ? ' • ${task.course}' : '';
      items.add(AppNotificationItem(
        id: id,
        type: type,
        title: title,
        subtitle: '${task.title}$courseSuffix',
        detail: detail,
        color: color,
        icon: icon,
        isRead: _readNotificationIds.contains(id),
        targetTabIndex: 2,
      ));
    }

    // 2. Jadwal kuliah hari ini
    final todaySchedules = schedulesForDate(ref);
    for (final schedule in todaySchedules) {
      final id = 'class_today_${schedule.id}_$todayStr';
      final isOngoing = schedule.isOngoingAt(ref);
      final hasEnded = schedule.hasEndedAt(ref);
      final statusLabel = isOngoing
          ? 'Sedang berlangsung'
          : (hasEnded ? 'Selesai hari ini' : 'Kelas hari ini');
      final details = <String>[
        schedule.timeRange,
        if (schedule.location.trim().isNotEmpty) schedule.location.trim(),
        if (schedule.instructor.trim().isNotEmpty) schedule.instructor.trim(),
      ].join(' • ');

      items.add(AppNotificationItem(
        id: id,
        type: AppNotificationType.todayClass,
        title: statusLabel,
        subtitle: schedule.courseTitle,
        detail: details,
        color: AppColors.classEvent,
        icon: Icons.school_outlined,
        isRead: _readNotificationIds.contains(id),
        targetTabIndex: 1,
      ));
    }

    return items;
  }

  int unreadNotificationCount([DateTime? now]) =>
      buildNotifications(now).where((n) => !n.isRead).length;

  Future<void> markNotificationRead(String id) async {
    if (_readNotificationIds.add(id)) {
      notifyListeners();
      await _saveNotificationState();
    }
  }

  Future<void> markAllNotificationsRead([DateTime? now]) async {
    final all = buildNotifications(now);
    var changed = false;
    for (final item in all) {
      if (_readNotificationIds.add(item.id)) changed = true;
    }
    if (changed) {
      notifyListeners();
      await _saveNotificationState();
    }
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  void _sortTasks() {
    _tasks.sort((a, b) {
      if (a.completed != b.completed) {
        return a.completed ? 1 : -1;
      }
      final dateCmp = a.dueDate.compareTo(b.dueDate);
      if (dateCmp != 0) return dateCmp;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
  }

  void _sortNotes() {
    _notes.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
  }

  void _sortSchedules() {
    _schedules.sort((a, b) {
      final dayCmp = AppDate.weekdayOfKey(a.day).compareTo(AppDate.weekdayOfKey(b.day));
      if (dayCmp != 0) return dayCmp;
      final timeCmp = a.startMinutes.compareTo(b.startMinutes);
      if (timeCmp != 0) return timeCmp;
      return a.courseTitle.toLowerCase().compareTo(b.courseTitle.toLowerCase());
    });
  }

  Future<void> _saveTasks() =>
      _storage.write(_tasksFile, _tasks.map((t) => t.toJson()).toList());

  Future<void> _saveNotes() =>
      _storage.write(_notesFile, _notes.map((n) => n.toJson()).toList());

  Future<void> _saveSchedules() =>
      _storage.write(_schedulesFile, _schedules.map((s) => s.toJson()).toList());

  Future<void> _saveNotificationState() =>
      _storage.write(_notifStateFile, {'readIds': _readNotificationIds.toList()});
}
