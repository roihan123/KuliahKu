import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:main/main.dart';
import 'package:main/models/schedule.dart';
import 'package:main/models/task.dart';
import 'package:main/services/academic_data_service.dart';
import 'package:main/services/auth_service.dart';
import 'package:main/services/json_storage.dart';
import 'package:main/services/settings_service.dart';

void main() {
  late Directory tempDir;
  late JsonStorage storage;
  late AuthService auth;
  late SettingsService settings;
  late AcademicDataService data;

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kuliahku_test_');
    storage = JsonStorage(tempDir);
    auth = AuthService(storage);
    settings = SettingsService(storage);
    data = AcademicDataService(storage);
    await Future.wait<void>([
      settings.load(),
      auth.init(),
      data.loadAll(),
    ]);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('Menampilkan halaman AuthPage saat belum login dan bisa login akun demo',
      (tester) async {
    await tester.pumpWidget(
      KuliahKuApp(auth: auth, settings: settings, data: data),
    );
    await tester.pumpAndSettle();

    expect(find.text('KuliahKu'), findsOneWidget);
    expect(find.text('Masuk'), findsWidgets);

    await auth.login('test@test.com', 'password');
    await tester.pumpAndSettle();

    expect(auth.isLoggedIn, isTrue);
    expect(find.text('Beranda'), findsWidgets);
  });

  test('Deteksi bentrok jadwal dan status tenggat tugas berjalan akurat', () async {
    final j1 = Schedule(
      id: '1',
      courseTitle: 'PAM',
      day: 'senin',
      startTime: '08:00',
      endTime: '09:40',
    );
    final j2 = Schedule(
      id: '2',
      courseTitle: 'Basis Data',
      day: 'senin',
      startTime: '09:00',
      endTime: '10:40',
    );
    expect(j1.overlaps(j2), isTrue);

    final now = DateTime(2026, 11, 15, 22, 0);
    final tomorrowTask = Task(
      id: 't1',
      title: 'Laporan',
      dueDate: DateTime(2026, 11, 16, 8, 0),
    );
    expect(tomorrowTask.daysUntilDue(now), 1);
    expect(tomorrowTask.status(now), TaskStatus.tomorrow);
  });
}
