import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'tugas.dart';
import 'jadwal.dart';
import 'catatan.dart';

class KalenderPage extends StatefulWidget {
  const KalenderPage({super.key});

  @override
  State<KalenderPage> createState() => _KalenderPageState();
}

class _KalenderPageState extends State<KalenderPage> {
  DateTime currentMonth = DateTime.now();
  DateTime selectedDate = DateTime.now();

  List<Task> allTasks = [];
  List<Jadwal> allJadwal = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAllEvents();
  }

  Future<void> loadAllEvents() async {
    setState(() => isLoading = true);
    try {
      // Load tasks
      final dir = await getApplicationDocumentsDirectory();
      final fileTasks = File('${dir.path}/tasks.json');
      if (await fileTasks.exists()) {
        final content = await fileTasks.readAsString();
        final List data = jsonDecode(content);
        allTasks = data.map((e) => Task.fromJson(e)).toList();
      } else {
        allTasks = [];
      }
      // Load jadwal
      final fileJadwal = File('${dir.path}/jadwal.json');
      if (await fileJadwal.exists()) {
        final content = await fileJadwal.readAsString();
        final List data = jsonDecode(content);
        allJadwal = data.map((e) => Jadwal.fromJson(e)).toList();
      } else {
        allJadwal = [];
      }
    } catch (e) {
      allTasks = [];
      allJadwal = [];
    }
    setState(() => isLoading = false);
  }

  // Helper: dapatkan event pada tanggal tertentu
  List<Map<String, dynamic>> getEventsForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    // Tugas (deadline)
    final tugasEvents = allTasks.where((t) =>
      DateFormat('yyyy-MM-dd').format(t.dueDate) == dateStr
    ).map((t) => {
      'type': 'task',
      'title': t.title,
      'subtitle': t.course,
      'time': null,
      'color': Colors.orange,
    });
    // Jadwal (kelas)
    final hari = DateFormat('EEEE', 'id_ID').format(date).toLowerCase();
    final jadwalEvents = allJadwal.where((j) => j.day == hari).map((j) => {
      'type': 'class',
      'title': j.courseTitle,
      'subtitle': j.instructor,
      'time': '${j.startTime} - ${j.endTime}',
      'color': Colors.deepPurple,
    });
    return [...tugasEvents, ...jadwalEvents];
  }

  // Helper: map tanggal yang punya event
  Map<String, bool> getDatesWithEvents() {
    final Map<String, bool> map = {};
    for (var t in allTasks) {
      final dateStr = DateFormat('yyyy-MM-dd').format(t.dueDate);
      map[dateStr] = true;
    }
    for (var j in allJadwal) {
      // Tandai semua hari dalam bulan ini yang sesuai dengan j.day
      final monthStart = DateTime(currentMonth.year, currentMonth.month, 1);
      final monthEnd = DateTime(currentMonth.year, currentMonth.month + 1, 0);
      for (int d = 0; d < monthEnd.day; d++) {
        final date = DateTime(currentMonth.year, currentMonth.month, d + 1);
        final hari = DateFormat('EEEE', 'id_ID').format(date).toLowerCase();
        if (hari == j.day) {
          final dateStr = DateFormat('yyyy-MM-dd').format(date);
          map[dateStr] = true;
        }
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    // Generate grid kalender
    final monthStart = DateTime(currentMonth.year, currentMonth.month, 1);
    final monthEnd = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final daysInMonth = List.generate(
      monthEnd.day,
      (i) => DateTime(currentMonth.year, currentMonth.month, i + 1),
    );
    final startDay = monthStart.weekday % 7;
    final daysToDisplay = [
      ...List.generate(startDay, (_) => null),
      ...daysInMonth,
    ];
    final dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    final datesWithEvents = getDatesWithEvents();

    final selectedEvents = getEventsForDate(selectedDate);

    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Kalender',  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: loadAllEvents,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Navigasi bulan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            currentMonth = DateTime(
                              currentMonth.year,
                              currentMonth.month - 1,
                              1,
                            );
                          });
                        },
                      ),
                      Text(
                        DateFormat('MMMM yyyy', 'id_ID').format(currentMonth),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            currentMonth = DateTime(
                              currentMonth.year,
                              currentMonth.month + 1,
                              1,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Nama hari
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: dayNames
                        .map((d) => Expanded(
                              child: Center(
                                child: Text(
                                  d,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 4),
                  // Grid kalender
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: daysToDisplay.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, i) {
                      final day = daysToDisplay[i];
                      if (day == null) {
                        return Container();
                      }
                      final dayStr = DateFormat('yyyy-MM-dd').format(day);
                      final hasEvents = datesWithEvents.containsKey(dayStr);
                      final isSelected = DateUtils.isSameDay(day, selectedDate);
                      final isToday = DateUtils.isSameDay(day, DateTime.now());
                      final isCurrentMonth = day.month == currentMonth.month;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDate = day;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: !isCurrentMonth
                                      ? Colors.grey.shade400
                                      : isToday
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.black87,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              if (hasEvents)
                                Positioned(
                                  bottom: 6,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Event pada tanggal terpilih
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEEE, d MMMM', 'id_ID').format(selectedDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      // Tombol tambah event bisa ditambahkan di sini jika ingin
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (selectedEvents.isEmpty)
                    Card(
                      margin: const EdgeInsets.only(top: 8),
                      child: const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Tidak ada kegiatan pada tanggal ini',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                  else
                    ...selectedEvents.map((event) {
                      return Card(
                        margin: const EdgeInsets.only(top: 8),
                        shape: Border(
                          left: BorderSide(color: event['color'], width: 5),
                        ),
                        child: ListTile(
                          title: Text(event['title']),
                          subtitle: event['time'] != null
                              ? Text('${event['time']}'
                                  '${event['subtitle'] != null && event['subtitle'] != "" ? " • ${event['subtitle']}" : ""}')
                              : (event['subtitle'] != null && event['subtitle'] != ""
                                  ? Text(event['subtitle'])
                                  : null),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: event['color'].withOpacity(0.13),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              event['type'] == 'task'
                                  ? 'Tugas'
                                  : event['type'] == 'class'
                                      ? 'Kelas'
                                      : 'Kegiatan',
                              style: TextStyle(
                                color: event['color'],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                ],
              ),
      ),
      bottomNavigationBar: BottomAppBar(
          color: Colors.white,
          elevation: 0,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                  active: false,
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
                  active: true,
                  onTap: () {},
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
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? Theme.of(context).colorScheme.primary : Colors.grey;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}