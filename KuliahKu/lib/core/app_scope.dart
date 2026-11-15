import 'package:flutter/material.dart';

import '../services/academic_data_service.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';

/// Menyediakan akses ke service utama di seluruh widget tree tanpa memerlukan
/// package pihak ketiga.
class AppScope extends InheritedWidget {
  const AppScope({
    required this.auth,
    required this.settings,
    required this.data,
    required super.child,
    super.key,
  });

  final AuthService auth;
  final SettingsService settings;
  final AcademicDataService data;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope tidak ditemukan di widget tree.');
    return scope!;
  }

  static AuthService authOf(BuildContext context) => of(context).auth;
  static SettingsService settingsOf(BuildContext context) => of(context).settings;
  static AcademicDataService dataOf(BuildContext context) => of(context).data;

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      auth != oldWidget.auth || settings != oldWidget.settings || data != oldWidget.data;
}
