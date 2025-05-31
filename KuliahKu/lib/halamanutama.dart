// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'jadwal.dart';
import 'tugas.dart';
import 'catatan.dart';
import 'kalender.dart';
import 'profile.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class HalamanUtama extends StatefulWidget {
  final Map<String, String>? user;
  const HalamanUtama({super.key, this.user});

  @override
  State<HalamanUtama> createState() => _HalamanUtamaState();
}
class _HalamanUtamaState extends State<HalamanUtama> {
  List<dynamic> jadwalHariIni = [];
  bool isLoading = true;
  List<dynamic> tugasMendesak = [];
  bool isLoadingTugas = true;
  List<Note> lastNotes = [];
  bool isLoadingNote = true;

  @override
  void initState() {
    super.initState();
    loadJadwalHariIni();
    loadTugasMendesak();
    loadLastNote();
  }

  Future<void> loadLastNote() async {
    setState(() => isLoadingNote = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/notes.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List data = jsonDecode(content);
        if (data.isNotEmpty) {
          data.sort((a, b) => DateTime.parse(b['lastUpdated']).compareTo(DateTime.parse(a['lastUpdated'])));
        lastNotes = data.take(3).map<Note>((e) => Note.fromJson(e)).toList();
        } else {
          lastNotes = [];
        }
      } else {
        lastNotes = [];
      }
    } catch (e) {
      lastNotes = [];
    }
    setState(() => isLoadingNote = false);
  }

  Future<void> loadJadwalHariIni() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/jadwal.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List data = jsonDecode(content);
        String hariIni = DateFormat('EEEE', 'id_ID').format(DateTime.now()).toLowerCase();
        setState(() {
          jadwalHariIni = data.where((j) => j['day'] == hariIni).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          jadwalHariIni = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        jadwalHariIni = [];
        isLoading = false;
      });
    }
  }

  Future<void> loadTugasMendesak() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/tasks.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List data = jsonDecode(content);
        final today = DateTime.now();
        tugasMendesak = data.where((t) {
          final dueDate = DateTime.parse(t['dueDate']);
          final daysUntilDue = dueDate.difference(today).inDays;
          return !(t['completed'] ?? false) && daysUntilDue <= 3 && daysUntilDue >= 0;
        }).toList();
      } else {
        tugasMendesak = [];
      }
    } catch (e) {
      tugasMendesak = [];
    }
    setState(() => isLoadingTugas = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Beranda')),
        body: RefreshIndicator(
          onRefresh: () async {
            await loadJadwalHariIni();
            await loadTugasMendesak();
            await loadLastNote();
          }, // Fungsi yang dijalankan saat refresh
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(), // Agar bisa di-pull walau konten sedikit
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: Text('User tidak ditemukan')),
                // ...seluruh isi halaman utama Anda...
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
          elevation: 0,
          title: const Text(
            'Beranda',
            style: TextStyle(
              color: Color(0xFF2A2D43),
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: Color(0xFF2A2D43)),
                  onPressed: () {},
                ),
                Positioned(
                  right: 8,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 8),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(user: widget.user),
                    ),
                  );
                },
                child: const CircleAvatar(
                  radius: 16,
                  child: const Icon(Icons.person, color: Colors.white, size: 18),
                  // backgroundImage: AssetImage('assets/avatar.png'), // TODO: Ganti dengan asset profil jika ada
                ),
              ),
            ),
          ],
        ),
      body: RefreshIndicator(
        onRefresh: () async {
          await loadJadwalHariIni();
          await loadTugasMendesak();
          await loadLastNote();
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // <--- ini penting!
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2D43),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, ${widget.user!['full_name'] ?? 'Mahasiswa'}!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Semester ${widget.user!['semester'] ?? '-'} - ${widget.user!['program_studi'] ?? '-'}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Jadwal Hari Ini',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                              Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const JadwalPage()),
                          ).then((_) => loadJadwalHariIni()); // refresh jadwal
                        },
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(color: Colors.white),
                          )
                        : (jadwalHariIni.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 18),
                                child: Text(
                                  'Tidak ada kelas hari ini',
                                  style: TextStyle(color: Colors.white70, fontSize: 15),
                                ),
                              )
                            : Column(
                                children: jadwalHariIni.map((j) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white24,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${j['startTime']} - ${j['endTime']}',
                                            style: const TextStyle(color: Colors.white, fontSize: 13),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            j['courseTitle'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              )),
                  ),
                ],
              ),
            ),
            // Tugas Mendesak
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tugas Mendesak',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF2A2D43),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TugasPage()),
                    ).then((_) => loadTugasMendesak()); // refresh tugas mendesak
                  },
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(
                      color: Color(0xFF2A2D43),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: isLoadingTugas
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : (tugasMendesak.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'Tidak ada tugas mendesak',
                              style: TextStyle(
                                color: Color(0xFF8B8B8B),
                                fontSize: 15,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            ...tugasMendesak.take(3).map((t) {
                              final dueDate = DateTime.parse(t['dueDate']);
                              return ListTile(
                                title: Text(
                                  t['title'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  DateFormat('d MMMM yyyy', 'id_ID').format(dueDate),
                                  style: const TextStyle(color: Color(0xFF8B8B8B)),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.13),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Mendesak',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const TugasPage()),
                                  );
                                },
                              );
                            }),
                            if (tugasMendesak.length > 3)
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const TugasPage()),
                                  );
                                },
                                child: const Text('Lihat Semua'),
                              ),
                          ],
                        )),
            ),
            // Catatan Terakhir
            const Text(
              'Catatan Terakhir',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2A2D43),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: isLoadingNote
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : (lastNotes.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'Belum ada catatan',
                              style: TextStyle(
                                color: Color(0xFF8B8B8B),
                                fontSize: 15,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            ...lastNotes.map((note) => ListTile(
                                  title: Text(
                                    note.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    note.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Text(
                                    DateFormat('d MMM yyyy', 'id_ID').format(note.lastUpdated),
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF8B8B8B)),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const CatatanPage()),
                                    );
                                  },
                                )),
                            if (lastNotes.length >= 3)
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const CatatanPage()),
                                  );
                                },
                                child: const Text('Lihat Semua'),
                              ),
                          ],
                        )),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavIcon(icon: Icons.home, label: 'Beranda', active: true),
              _NavIcon(
                icon: Icons.calendar_today,
                label: 'Jadwal',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const JadwalPage()),
                  );
                },
              ),
              _NavIcon(
                icon: Icons.assignment,
                label: 'Tugas',
                active: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TugasPage()),
                  );
                },
              ),
              _NavIcon(
                icon: Icons.sticky_note_2, 
                label: 'Catatan',
                active: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CatatanPage()),
                  );
                },
              ),
              _NavIcon(
                icon: Icons.calendar_month, 
                label: 'Kalender',
                active: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const KalenderPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _NavIcon({required this.icon, required this.label, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: active ? const Color(0xFF2A2D43) : const Color(0xFFB0B0B0),
          ),
          Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF2A2D43) : const Color(0xFFB0B0B0),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}