import 'package:flutter/material.dart';

enum AppNotificationType {
  overdueTask,
  dueTodayTask,
  dueSoonTask,
  todayClass,
}

/// Representasi item notifikasi di dalam aplikasi.
class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.color,
    required this.icon,
    required this.isRead,
    required this.targetTabIndex,
  });

  final String id;
  final AppNotificationType type;
  final String title;
  final String subtitle;
  final String detail;
  final Color color;
  final IconData icon;
  final bool isRead;

  /// Index tab pada MainShell saat item diketuk (1 = Jadwal, 2 = Tugas).
  final int targetTabIndex;
}
