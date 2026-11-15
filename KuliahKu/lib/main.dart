import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/app_scope.dart';
import 'core/app_theme.dart';
import 'pages/auth_page.dart';
import 'pages/main_shell.dart';
import 'services/academic_data_service.dart';
import 'services/auth_service.dart';
import 'services/json_storage.dart';
import 'services/settings_service.dart';
import 'services/system_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  final storage = await JsonStorage.create();
  final settings = SettingsService(storage);
  final auth = AuthService(storage);
  final data = AcademicDataService(storage);

  await settings.load();
  data.setSystemNotificationsEnabled(settings.notificationsEnabled);
  settings.addListener(() {
    data.setSystemNotificationsEnabled(settings.notificationsEnabled);
  });

  if (settings.notificationsEnabled) {
    await SystemNotificationService.requestPermission();
  }

  await Future.wait<void>([
    auth.init(),
    data.loadAll(),
  ]);

  runApp(
    KuliahKuApp(
      auth: auth,
      settings: settings,
      data: data,
    ),
  );
}

/// Root widget aplikasi KuliahKu.
class KuliahKuApp extends StatelessWidget {
  const KuliahKuApp({
    required this.auth,
    required this.settings,
    required this.data,
    super.key,
  });

  final AuthService auth;
  final SettingsService settings;
  final AcademicDataService data;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      auth: auth,
      settings: settings,
      data: data,
      child: ListenableBuilder(
        listenable: Listenable.merge([auth, settings]),
        builder: (context, _) {
          return MaterialApp(
            title: 'KuliahKu',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('id', 'ID'),
              Locale('en', 'US'),
            ],
            home: auth.isLoggedIn ? const MainShell() : const AuthPage(),
          );
        },
      ),
    );
  }
}
