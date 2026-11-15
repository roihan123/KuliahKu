import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Kumpulan helper tanggal & waktu berbasis locale Indonesia.
///
/// Semua formatter dibuat sekali (lazy static) sehingga tidak membuat objek
/// `DateFormat` baru setiap kali widget dibangun.
class AppDate {
  AppDate._();

  /// Kunci hari yang dipakai di data jadwal (urut Senin..Minggu).
  static const List<String> dayKeys = [
    'senin',
    'selasa',
    'rabu',
    'kamis',
    'jumat',
    'sabtu',
    'minggu',
  ];

  static final DateFormat _fullDate = DateFormat('d MMMM yyyy', 'id_ID');
  static final DateFormat _shortDate = DateFormat('d MMM yyyy', 'id_ID');
  static final DateFormat _dayMonth = DateFormat('d MMMM', 'id_ID');
  static final DateFormat _shortDayMonth = DateFormat('d MMM', 'id_ID');
  static final DateFormat _weekday = DateFormat('EEEE', 'id_ID');
  static final DateFormat _weekdayShort = DateFormat('E', 'id_ID');
  static final DateFormat _weekdayDayMonth = DateFormat('EEEE, d MMMM', 'id_ID');
  static final DateFormat _longDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'id_ID');

  static String fullDate(DateTime d) => _fullDate.format(d);
  static String shortDate(DateTime d) => _shortDate.format(d);
  static String dayMonth(DateTime d) => _dayMonth.format(d);
  static String shortDayMonth(DateTime d) => _shortDayMonth.format(d);
  static String weekday(DateTime d) => _weekday.format(d);
  static String weekdayShort(DateTime d) => _weekdayShort.format(d);
  static String weekdayDayMonth(DateTime d) => _weekdayDayMonth.format(d);
  static String longDate(DateTime d) => _longDate.format(d);
  static String monthYear(DateTime d) => _monthYear.format(d);

  /// Tanggal tanpa komponen jam.
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Selisih hari kalender (bukan selisih 24 jam). Dihitung dalam UTC agar
  /// tidak terpengaruh jam saat ini maupun DST.
  static int daysBetween(DateTime from, DateTime to) => DateTime.utc(to.year, to.month, to.day)
      .difference(DateTime.utc(from.year, from.month, from.day))
      .inDays;

  static int daysUntil(DateTime date, {DateTime? from}) => daysBetween(from ?? DateTime.now(), date);

  static bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// Hari Senin pada minggu yang sama dengan [d].
  static DateTime startOfWeek(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));

  static String dayKeyOf(DateTime d) => dayKeys[d.weekday - 1];

  /// 1 (Senin) .. 7 (Minggu); 0 jika kunci tidak valid.
  static int weekdayOfKey(String key) => dayKeys.indexOf(key) + 1;

  static String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Parse "08:00" / "8.00" menjadi menit sejak tengah malam.
  static int? parseMinutes(String value) {
    final match = RegExp(r'^\s*(\d{1,2})[:.](\d{2})\s*$').firstMatch(value);
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return hour * 60 + minute;
  }

  static TimeOfDay? parseTime(String value) {
    final minutes = parseMinutes(value);
    return minutes == null ? null : TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  static int toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  static TimeOfDay fromMinutes(int minutes) {
    final clamped = minutes.clamp(0, 23 * 60 + 59);
    return TimeOfDay(hour: clamped ~/ 60, minute: clamped % 60);
  }

  static String formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static int minutesOfDay(DateTime d) => d.hour * 60 + d.minute;

  static String greeting([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  /// Periode akademik: Agustus–Januari = Ganjil, Februari–Juli = Genap.
  static String academicPeriod([DateTime? now]) {
    final d = now ?? DateTime.now();
    final isGanjil = d.month >= 8 || d.month == 1;
    final startYear = d.month >= 8 ? d.year : d.year - 1;
    return '${isGanjil ? 'Ganjil' : 'Genap'} $startYear/${startYear + 1}';
  }
}
