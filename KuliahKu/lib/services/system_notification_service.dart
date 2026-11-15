import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Jembatan ke sistem notifikasi native Android menggunakan `MethodChannel`
/// bawaan Flutter (tanpa package pihak ketiga).
class SystemNotificationService {
  const SystemNotificationService._();

  static const MethodChannel _channel = MethodChannel('kuliahku/notifications');

  static bool get _isSupported => !kIsWeb && Platform.isAndroid;

  /// Meminta izin notifikasi pada Android 13+ (API 33+).
  static Future<bool> requestPermission() async {
    if (!_isSupported) return false;
    try {
      final result = await _channel.invokeMethod<bool>('requestPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('SystemNotificationService.requestPermission gagal: $e');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Menampilkan notifikasi di status bar / notification shade HP.
  static Future<bool> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isSupported) return false;
    try {
      final shown = await _channel.invokeMethod<bool>('showNotification', {
        'id': id,
        'title': title,
        'body': body,
      });
      return shown ?? false;
    } on PlatformException catch (e) {
      debugPrint('SystemNotificationService.show gagal: $e');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Menghapus seluruh notifikasi aktif milik aplikasi di status bar HP.
  static Future<void> cancelAll() async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod<bool>('cancelAll');
    } on PlatformException catch (e) {
      debugPrint('SystemNotificationService.cancelAll gagal: $e');
    } on MissingPluginException {
      // Abaikan pada environment test / desktop.
    }
  }
}
