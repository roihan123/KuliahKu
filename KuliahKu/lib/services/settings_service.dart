import 'package:flutter/material.dart';

import 'json_storage.dart';
import 'system_notification_service.dart';

/// Pengaturan aplikasi yang tersimpan (tema & notifikasi).
class SettingsService extends ChangeNotifier {
  SettingsService(this._storage);

  static const String _file = 'settings.json';

  final JsonStorage _storage;
  ThemeMode _themeMode = ThemeMode.light;
  bool _notificationsEnabled = true;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> load() async {
    final data = await _storage.readMap(_file);
    if (data == null) return;
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == data['themeMode'],
      orElse: () => ThemeMode.light,
    );
    _notificationsEnabled = data['notificationsEnabled'] != false;
  }

  Future<void> setDarkMode(bool enabled) =>
      _update(() => _themeMode = enabled ? ThemeMode.dark : ThemeMode.light);

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (enabled) {
      await SystemNotificationService.requestPermission();
    } else {
      await SystemNotificationService.cancelAll();
    }
    return _update(() => _notificationsEnabled = enabled);
  }

  Future<void> _update(VoidCallback change) {
    change();
    notifyListeners();
    return _storage.write(_file, {
      'themeMode': _themeMode.name,
      'notificationsEnabled': _notificationsEnabled,
    });
  }
}
