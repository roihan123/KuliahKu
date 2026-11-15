import 'dart:math';

/// Validator form yang dipakai ulang di seluruh aplikasi.
class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _nimPattern = RegExp(r'^[0-9A-Za-z.\-]+$');

  static String? notEmpty(String? value, String message) =>
      (value == null || value.trim().isEmpty) ? message : null;

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email diperlukan';
    return _emailPattern.hasMatch(value.trim()) ? null : 'Format email tidak valid';
  }

  static String? password(String? value) =>
      (value == null || value.length < 6) ? 'Password minimal 6 karakter' : null;

  static String? semester(String? value) {
    final n = int.tryParse(value?.trim() ?? '');
    if (n == null) return 'Semester diperlukan';
    if (n < 1 || n > 14) return 'Semester 1–14';
    return null;
  }

  static String? nim(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return _nimPattern.hasMatch(value.trim()) ? null : 'NIM tidak valid';
  }
}

final Random _random = Random();

/// ID unik sederhana berbasis waktu + angka acak.
String generateId() =>
    '${DateTime.now().microsecondsSinceEpoch}${_random.nextInt(1 << 16).toRadixString(16)}';
