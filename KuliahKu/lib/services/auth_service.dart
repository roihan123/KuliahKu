import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import 'json_storage.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Mengelola akun & sesi login.
///
/// Data akun disimpan di `users.json` (password di-hash SHA-256 + salt),
/// sesi aktif di `session.json`. File lama `akun.txt` / `login.txt`
/// dimigrasikan otomatis saat pertama kali dijalankan.
class AuthService extends ChangeNotifier {
  AuthService(this._storage);

  static const String _usersFile = 'users.json';
  static const String _sessionFile = 'session.json';
  static const int _hashRounds = 5000;

  final JsonStorage _storage;
  final List<AppUser> _users = [];
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  Future<void> init() async {
    await _migrateLegacyFiles();
    final raw = await _storage.readList(_usersFile);
    _users
      ..clear()
      ..addAll(raw.map(AppUser.fromJson).where((u) => u.email.isNotEmpty));

    final session = await _storage.readMap(_sessionFile);
    final email = session?['email'];
    _currentUser = email is String ? _findUser(email) : null;
    if (_currentUser == null && session != null) {
      await _storage.delete(_sessionFile);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String programStudi,
    required String semester,
    String nim = '',
  }) async {
    final normalized = normalizeEmail(email);
    if (_findUser(normalized) != null) {
      throw const AuthException('Email sudah terdaftar. Silakan masuk.');
    }
    final salt = _generateSalt();
    final user = AppUser(
      email: normalized,
      passwordHash: hashPassword(password, salt),
      salt: salt,
      fullName: fullName.trim(),
      programStudi: programStudi.trim(),
      semester: semester.trim(),
      nim: nim.trim(),
    );
    _users.add(user);
    await _saveUsers();
    await _startSession(user);
  }

  Future<void> login(String email, String password) async {
    final user = _findUser(email);
    if (user == null || hashPassword(password, user.salt) != user.passwordHash) {
      throw const AuthException('Email atau password salah');
    }
    await _startSession(user);
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
    await _storage.delete(_sessionFile);
  }

  Future<void> updateProfile({
    String? fullName,
    String? programStudi,
    String? semester,
    String? nim,
  }) async {
    final current = _currentUser;
    if (current == null) return;
    final updated = current.copyWith(
      fullName: fullName?.trim(),
      programStudi: programStudi?.trim(),
      semester: semester?.trim(),
      nim: nim?.trim(),
    );
    final index = _users.indexWhere((u) => u.email == current.email);
    if (index >= 0) {
      _users[index] = updated;
    } else {
      _users.add(updated);
    }
    _currentUser = updated;
    notifyListeners();
    await _saveUsers();
  }

  // ---------------------------------------------------------------------------

  AppUser? _findUser(String email) {
    final normalized = normalizeEmail(email);
    for (final user in _users) {
      if (user.email == normalized) return user;
    }
    return null;
  }

  Future<void> _startSession(AppUser user) async {
    _currentUser = user;
    notifyListeners();
    await _storage.write(_sessionFile, {'email': user.email});
  }

  Future<void> _saveUsers() => _storage.write(_usersFile, _users.map((u) => u.toJson()).toList());

  static String _generateSalt() {
    final random = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => random.nextInt(256)));
  }

  @visibleForTesting
  static String hashPassword(String password, String salt) {
    final saltBytes = utf8.encode(salt);
    var digest = sha256.convert(utf8.encode('$salt:$password'));
    for (var i = 0; i < _hashRounds; i++) {
      digest = sha256.convert([...digest.bytes, ...saltBytes]);
    }
    return digest.toString();
  }

  /// Migrasi dari format lama:
  /// - `akun.txt`  : `email;password;nama;prodi;semester;nim;` per baris
  /// - `login.txt` : email user yang sedang login
  Future<void> _migrateLegacyFiles() async {
    if (await _storage.exists(_usersFile)) return;

    final legacyAccounts = _storage.file('akun.txt');
    final users = <AppUser>[];
    if (await legacyAccounts.exists()) {
      try {
        // Versi lama punya bug: updateAkun menulis ";}" tanpa newline sehingga
        // akun berikutnya tersambung di baris yang sama. Pisahkan kembali.
        final content = (await legacyAccounts.readAsString()).replaceAll(';}', ';\n');
        for (final line in const LineSplitter().convert(content)) {
          final parts = line.split(';');
          if (parts.length < 5) continue;
          final email = normalizeEmail(parts[0]);
          if (email.isEmpty || users.any((u) => u.email == email)) continue;
          final salt = _generateSalt();
          users.add(AppUser(
            email: email,
            passwordHash: hashPassword(parts[1], salt),
            salt: salt,
            fullName: parts[2].trim(),
            programStudi: parts[3].trim(),
            semester: parts[4].trim(),
            nim: parts.length > 5 ? parts[5].replaceAll('}', '').trim() : '',
          ));
        }
      } catch (e) {
        debugPrint('AuthService: gagal migrasi akun.txt: $e');
      }
    }

    // Pastikan akun demo bawaan tetap tersedia seperti versi sebelumnya.
    if (users.every((u) => u.email != 'test@test.com')) {
      final salt = _generateSalt();
      users.add(AppUser(
        email: 'test@test.com',
        passwordHash: hashPassword('password', salt),
        salt: salt,
        fullName: 'Mahasiswa Demo',
        programStudi: 'Informatika',
        semester: '2',
        nim: '',
      ));
    }

    await _storage.write(_usersFile, users.map((u) => u.toJson()).toList());
    if (await legacyAccounts.exists()) {
      await _storage.rename('akun.txt', 'akun.txt.bak');
    }

    final legacyLogin = _storage.file('login.txt');
    if (await legacyLogin.exists()) {
      try {
        final email = (await legacyLogin.readAsString()).trim();
        if (email.isNotEmpty) {
          await _storage.write(_sessionFile, {'email': normalizeEmail(email)});
        }
      } catch (e) {
        debugPrint('AuthService: gagal migrasi login.txt: $e');
      }
      await _storage.delete('login.txt');
    }
  }
}
