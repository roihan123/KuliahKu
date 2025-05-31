import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'halamanutama.dart';
import 'tugas.dart';
import 'catatan.dart';
import 'kalender.dart';
import 'profile.dart';

class Jadwal {
  String id;
  String courseTitle;
  String day;
  String startTime;
  String endTime;
  String instructor;
  String location;

  Jadwal({
    required this.id,
    required this.courseTitle,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.instructor,
    required this.location,
  });

  factory Jadwal.fromJson(Map<String, dynamic> json) => Jadwal(
        id: json['id'],
        courseTitle: json['courseTitle'],
        day: json['day'],
        startTime: json['startTime'],
        endTime: json['endTime'],
        instructor: json['instructor'],
        location: json['location'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseTitle': courseTitle,
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
        'instructor': instructor,
        'location': location,
      };
}

class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  List<Jadwal> jadwalList = [];
  bool isLoading = true;
  DateTime selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadJadwal();
  }

  Future<File> get _localFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/jadwal.json');
  }

  Future<void> loadJadwal() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final List data = jsonDecode(content);
        setState(() {
          jadwalList = data.map((e) => Jadwal.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          jadwalList = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        jadwalList = [];
        isLoading = false;
      });
    }
  }

  Future<void> saveJadwal() async {
    final file = await _localFile;
    await file.writeAsString(jsonEncode(jadwalList.map((e) => e.toJson()).toList()));
  }

  void addOrEditJadwal({Jadwal? jadwal, String? presetDay}) async {
    final result = await showDialog<Jadwal>(
      context: context,
      builder: (context) => JadwalDialog(
        jadwal: jadwal,
        presetDay: presetDay,
      ),
    );
    if (result != null) {
      setState(() {
        if (jadwal != null) {
          // Edit
          final idx = jadwalList.indexWhere((j) => j.id == jadwal.id);
          if (idx != -1) jadwalList[idx] = result;
        } else {
          // Add
          jadwalList.add(result);
        }
      });
      await saveJadwal();
    }
  }

  void deleteJadwal(String id) async {
    setState(() {
      jadwalList.removeWhere((j) => j.id == id);
    });
    await saveJadwal();
  }

  // Helper
  String getHariIndonesia(DateTime date) {
    final hari = DateFormat('EEEE', 'id_ID').format(date);
    return hari[0].toUpperCase() + hari.substring(1);
  }

  String getTanggalIndonesia(DateTime date) {
    return DateFormat('d MMMM yyyy', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    // Generate minggu ini (Senin-Minggu)
    DateTime startOfWeek = selectedDay.subtract(Duration(days: selectedDay.weekday - 1));
    List<DateTime> daysOfWeek = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    String hariIni = DateFormat('EEEE', 'id_ID').format(selectedDay).toLowerCase();
    List<Jadwal> jadwalHariIni = jadwalList.where((j) => j.day == hariIni).toList();

    // Jadwal mendatang (selain hari ini, urutkan sesuai minggu)
    List<String> hariList = [
      'senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu', 'minggu'
    ];
    List<String> upcomingDays = hariList.where((h) => h != hariIni).toList();
    Map<String, List<Jadwal>> groupedUpcoming = {};
    for (var day in upcomingDays) {
      groupedUpcoming[day] = jadwalList.where((j) => j.day == day).toList();
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Jadwal Kuliah', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Jadwal Mingguan
                  const SizedBox(height: 8),
                  const Text(
                    'Jadwal Mingguan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: daysOfWeek.map((date) {
                      String dayShort = DateFormat('E', 'id_ID').format(date);
                      bool isSelected = date.day == selectedDay.day &&
                          date.month == selectedDay.month &&
                          date.year == selectedDay.year;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDay = date;
                          });
                        },
                        child: Column(
                          children: [
                            Text(
                              dayShort,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.grey[300] : Colors.transparent,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.grey[700],
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Hari ini
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      getHariIndonesia(selectedDay),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      getTanggalIndonesia(selectedDay),
                                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => addOrEditJadwal(presetDay: hariIni),
                                child: const Text(
                                  '+ Tambah',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (jadwalHariIni.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'Tidak ada jadwal untuk ${getHariIndonesia(selectedDay)}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 15),
                                ),
                              ),
                            )
                          else
                            Column(
                              children: jadwalHariIni.map((j) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              j.startTime,
                                              style: const TextStyle(color: Colors.white, fontSize: 13),
                                            ),
                                          ),
                                          Container(
                                            width: 2,
                                            height: 18,
                                            color: Colors.grey[300],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[700],
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              j.endTime,
                                              style: const TextStyle(color: Colors.white, fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              j.courseTitle,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                            if (j.instructor.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.person, size: 16, color: Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      j.instructor,
                                                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if (j.location.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      j.location,
                                                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            addOrEditJadwal(jadwal: j);
                                          } else if (value == 'delete') {
                                            deleteJadwal(j.id);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Hapus'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Jadwal Mendatang
                  const Text(
                    'Jadwal Mendatang',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (groupedUpcoming.values.every((list) => list.isEmpty))
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      color: Colors.grey[50],
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Center(
                          child: Text(
                            'Tidak ada jadwal mendatang untuk minggu ini',
                            style: TextStyle(color: Colors.grey[400], fontSize: 15),
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: groupedUpcoming.entries
                          .where((entry) => entry.value.isNotEmpty)
                          .map((entry) {
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          color: Colors.grey[50],
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      entry.key[0].toUpperCase() + entry.key.substring(1),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      '${entry.value.length} kelas',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Column(
                                  children: entry.value.map((j) {
                                    return Row(
                                      children: [
                                        SizedBox(
                                          width: 50,
                                          child: Text(
                                            j.startTime,
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(vertical: 4),
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              j.courseTitle,
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () => addOrEditJadwal(presetDay: hariIni),
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
              _NavIcon(
                icon: Icons.home,
                label: 'Beranda',
                active: false,
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              _NavIcon(
                icon: Icons.calendar_today,
                label: 'Jadwal',
                active: true,
                onTap: () {}, // Sudah di halaman Jadwal
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

class JadwalDialog extends StatefulWidget {
  final Jadwal? jadwal;
  final String? presetDay;
  const JadwalDialog({this.jadwal, this.presetDay, super.key});

  @override
  State<JadwalDialog> createState() => _JadwalDialogState();
}

class _JadwalDialogState extends State<JadwalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _title, _start, _end, _instruktur, _lokasi;
  String _day = 'senin';

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.jadwal?.courseTitle ?? '');
    _start = TextEditingController(text: widget.jadwal?.startTime ?? '');
    _end = TextEditingController(text: widget.jadwal?.endTime ?? '');
    _instruktur = TextEditingController(text: widget.jadwal?.instructor ?? '');
    _lokasi = TextEditingController(text: widget.jadwal?.location ?? '');
    _day = widget.jadwal?.day ?? widget.presetDay ?? 'senin';
  }

  @override
  void dispose() {
    _title.dispose();
    _start.dispose();
    _end.dispose();
    _instruktur.dispose();
    _lokasi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = [
      'senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu', 'minggu'
    ];
    return AlertDialog(
      title: Text(widget.jadwal == null ? 'Tambah Jadwal' : 'Edit Jadwal'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _day,
                items: days
                    .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(d[0].toUpperCase() + d.substring(1)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _day = v ?? 'senin'),
                decoration: const InputDecoration(labelText: 'Hari'),
              ),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Mata Kuliah'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _start,
                decoration: const InputDecoration(labelText: 'Jam Mulai (ex: 08:00)'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _end,
                decoration: const InputDecoration(labelText: 'Jam Selesai (ex: 09:40)'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _instruktur,
                decoration: const InputDecoration(labelText: 'Dosen/Pengajar'),
              ),
              TextFormField(
                controller: _lokasi,
                decoration: const InputDecoration(labelText: 'Lokasi'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(
                  context,
                  Jadwal(
                    id: widget.jadwal?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    courseTitle: _title.text,
                    day: _day,
                    startTime: _start.text,
                    endTime: _end.text,
                    instructor: _instruktur.text,
                    location: _lokasi.text,
                  ));
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap; // Tambahkan parameter onTap

  const _NavIcon({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap, // Tambahkan ke konstruktor
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Gunakan onTap di GestureDetector
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: active ? Colors.black : Colors.grey[400],
          ),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.black : Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}