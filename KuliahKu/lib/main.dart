// ignore_for_file: use_build_context_synchronously, unused_import

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'halamanutama.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null); // Inisialisasi locale Indonesia
  runApp(const MyApp());
}

  Future<File> get _akunFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/akun.txt');
  }
  // Simpan akun ke file (append)
  Future<void> simpanAkun(Map<String, String> akun) async {
    final file = await _akunFile;
    final akunString = '${akun['email']};${akun['password']};${akun['full_name']};${akun['program_studi']};${akun['semester']};${akun['nim'] ?? ''};\n';
    await file.writeAsString(akunString, mode: FileMode.append);
  }

  Future<void> updateAkun(String email, Map<String, String> newData) async {
    final file = await _akunFile;
    if (!(await file.exists())) return;
    final lines = await file.readAsLines();
    final newLines = lines.map((line) {
      final parts = line.split(';');
      if (parts[0] == email) {
        // Update sesuai urutan field
        return '${newData['email']};${newData['password']};${newData['full_name']};${newData['program_studi']};${newData['semester']};${newData['nim'] ?? ''};}';
      }
      return line;
    }).toList();
    await file.writeAsString(newLines.join('\n'));
  }

  // Baca semua akun dari file
  Future<List<Map<String, String>>> bacaAkun() async {
    final file = await _akunFile;
    if (!(await file.exists())) return [];
    final lines = await file.readAsLines();
    return lines.map((line) {
      final parts = line.split(';');
      return {
        'email': parts[0],
        'password': parts[1],
        'full_name': parts[2],
        'program_studi': parts[3],
        'semester': parts[4],
        'nim': parts.length > 5 ? parts[5] : '',
      };
    }).toList();
  }

  ValueNotifier<bool> darkModeNotifier = ValueNotifier(false);

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, darkMode, _) {
        return MaterialApp(
          title: 'KuliahKu',
          theme: ThemeData(
            brightness: darkMode ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: darkMode ? const Color(0xFF23243A) : Colors.white,
            cardColor: darkMode ? const Color(0xFF2A2D43) : Colors.white,
            appBarTheme: AppBarTheme(
              backgroundColor: darkMode ? const Color(0xFF23243A) : Colors.white,
              foregroundColor: darkMode ? Colors.white : Colors.black,
              elevation: 0,
            ),
            textTheme: Theme.of(context).textTheme.apply(
              bodyColor: darkMode ? Colors.white : Colors.black,
              displayColor: darkMode ? Colors.white : Colors.black,
            ),
            colorScheme: ColorScheme.fromSwatch().copyWith(
              primary: const Color(0xFF2A2D43),
              secondary: Colors.blueAccent,
              brightness: darkMode ? Brightness.dark : Brightness.light,
            ),
          ),
      home: const AuthPage(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
    );
  }
  );
}
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}
List<Map<String, String>> akunList = [
    {
      'email': 'test@test.com',
      'password': 'password',
      'full_name': 'test',
      'program_studi': 'If',
      'semester': '2',
    },
];
class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // Controllers for login
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Controllers for register
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerFullNameController = TextEditingController();
  final _registerProgramController = TextEditingController();
  final _registerSemesterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerFullNameController.dispose();
    _registerProgramController.dispose();
    _registerSemesterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
        return Center (
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  mainAxisSize: MainAxisSize.max,
                    children: [
                      const SizedBox(height: 40),
                      const Text(
                        'KuliahKu',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D2D3A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Kelola jadwal dan tugas kuliahmu dengan mudah',
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(0xFF6B6B7E),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/KuliahkuBanner.png',
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F6F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _tabController.animateTo(0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _tabController.index == 0
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Masuk',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 18,
                                      color: _tabController.index == 0
                                          ? const Color(0xFF2D2D3A)
                                          : const Color(0xFFB0B0B0),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _tabController.animateTo(1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _tabController.index == 1
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Daftar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 18,
                                      color: _tabController.index == 1
                                          ? const Color(0xFF2D2D3A)
                                          : const Color(0xFFB0B0B0),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, _) {
                          return IndexedStack(
                            index: _tabController.index,
                            children: [
                                SingleChildScrollView(
                                  child: Form(
                                    key: _loginFormKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Email', style: TextStyle(fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _loginEmailController,
                                          decoration: InputDecoration(
                                            hintText: 'email@universitas.ac.id',
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          ),
                                          validator: (value) => value == null || value.isEmpty ? 'Email diperlukan' : null,
                                        ),
                                        const SizedBox(height: 18),
                                        const Text('Password', style: TextStyle(fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _loginPasswordController,
                                          decoration: InputDecoration(
                                            hintText: '********',
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          ),
                                          obscureText: true,
                                          validator: (value) => value == null || value.length < 6 ? 'Password minimal 6 karakter' : null,
                                        ),
                                        const SizedBox(height: 28),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 54,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF2D2D3A),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            // onPressed: () async {
                                            //   if (_loginFormKey.currentState!.validate()) {
                                            //     final semuaAkun = await bacaAkun();
                                            //     final akun = semuaAkun.firstWhere(
                                            //       (a) =>
                                            //         a['email'] == _loginEmailController.text &&
                                            //         a['password'] == _loginPasswordController.text,
                                            //       orElse: () => {},
                                            //     );
                                            //     if (akun.isNotEmpty) {
                                            //       ScaffoldMessenger.of(context).showSnackBar(
                                            //         const SnackBar(content: Text('Login berhasil!')),
                                            //       );
                                            //       Navigator.pushReplacement(
                                            //         context,
                                            //         MaterialPageRoute(builder: (context) => const HalamanUtama()),
                                            //       );
                                            //     } else {
                                            //       ScaffoldMessenger.of(context).showSnackBar(
                                            //         const SnackBar(content: Text('Email atau password salah')),
                                            //       );
                                            //     }
                                            //   }
                                            // },
                                            onPressed: () {
                                              if (_loginFormKey.currentState!.validate()) {
                                                final akun = akunList.firstWhere(
                                                  (a) =>
                                                    a['email'] == _loginEmailController.text &&
                                                    a['password'] == _loginPasswordController.text,
                                                  orElse: () => {},
                                                );
                                                if (akun.isNotEmpty) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Login berhasil!')),
                                                  );
                                                  Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(builder: (context) => HalamanUtama(user: akun)),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Email atau password salah')),
                                                  );
                                                }
                                              }
                                            },
                                            child: const Text(
                                              'Masuk',
                                              style: TextStyle(color: Colors.grey,fontSize: 18, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SingleChildScrollView(
                                  child: Form(
                                    key: _registerFormKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Email', style: TextStyle(fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _registerEmailController,
                                          decoration: InputDecoration(
                                            hintText: 'email@universitas.ac.id',
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          ),
                                          validator: (value) => value == null || value.isEmpty ? 'Email diperlukan' : null,
                                        ),
                                        const SizedBox(height: 18),
                                        const Text('Password', style: TextStyle(fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _registerPasswordController,
                                          decoration: InputDecoration(
                                            hintText: '********',
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          ),
                                          obscureText: true,
                                          validator: (value) => value == null || value.length < 6 ? 'Password minimal 6 karakter' : null,
                                        ),
                                        const SizedBox(height: 18),
                                        const Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _registerFullNameController,
                                          decoration: InputDecoration(
                                            hintText: 'Nama Lengkap',
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          ),
                                          validator: (value) => value == null || value.isEmpty ? 'Nama lengkap diperlukan' : null,
                                        ),
                                        const SizedBox(height: 18),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Program Studi', style: TextStyle(fontWeight: FontWeight.w500)),
                                                  const SizedBox(height: 6),
                                                  TextFormField(
                                                    controller: _registerProgramController,
                                                    decoration: InputDecoration(
                                                      hintText: 'Program Studi',
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                                      ),
                                                      enabledBorder: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                                      ),
                                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                                    ),
                                                    validator: (value) => value == null || value.isEmpty ? 'Program studi diperlukan' : null,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Semester', style: TextStyle(fontWeight: FontWeight.w500)),
                                                  const SizedBox(height: 6),
                                                  TextFormField(
                                                    controller: _registerSemesterController,
                                                    decoration: InputDecoration(
                                                      hintText: '1',
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                                      ),
                                                      enabledBorder: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                                      ),
                                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                                    ),
                                                    keyboardType: TextInputType.number,
                                                    validator: (value) => value == null || value.isEmpty ? 'Semester diperlukan' : null,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 18),
                                        const Text('NIM (Opsional)', style: TextStyle(fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          decoration: InputDecoration(
                                            hintText: 'Nomor Induk Mahasiswa',
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          ),
                                        ),
                                        const SizedBox(height: 28),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 54,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF2D2D3A),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            // onPressed: () async {
                                            //   if (_registerFormKey.currentState!.validate()) {
                                            //     final akunBaru = {
                                            //       'email': _registerEmailController.text,
                                            //       'password': _registerPasswordController.text,
                                            //       'full_name': _registerFullNameController.text,
                                            //       'program_studi': _registerProgramController.text,
                                            //       'semester': _registerSemesterController.text,
                                            //     };
                                            //     await simpanAkun(akunBaru);
                                            //     ScaffoldMessenger.of(context).showSnackBar(
                                            //       const SnackBar(content: Text('Registrasi berhasil! Silakan login.')),
                                            //     );
                                            //     _tabController.animateTo(0);
                                            //   }
                                            // },
                                            onPressed: () {
                                              if (_registerFormKey.currentState!.validate()) {
                                                akunList.add({
                                                  'email': _registerEmailController.text,
                                                  'password': _registerPasswordController.text,
                                                  'full_name': _registerFullNameController.text,
                                                  'program_studi': _registerProgramController.text,
                                                  'semester': _registerSemesterController.text,
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Registrasi berhasil! Silakan login.')),
                                                );
                                                _tabController.animateTo(0);
                                              }
                                            },
                                            child: const Text(
                                              'Daftar',
                                              style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 18, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ),
        );
      },
    ),
  );
}
}