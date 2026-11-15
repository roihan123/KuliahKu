import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/app_theme.dart';
import '../core/date_utils.dart';
import '../models/schedule.dart';
import '../models/task.dart';
import '../widgets/empty_state_card.dart';
import 'jadwal_page.dart';
import 'tugas_page.dart';

/// Halaman Kalender Akademik yang menggabungkan jadwal kelas mingguan
/// dan tenggat waktu tugas dalam tampilan bulanan.
class KalenderPage extends StatefulWidget {
  const KalenderPage({super.key});

  @override
  State<KalenderPage> createState() => _KalenderPageState();
}

class _KalenderPageState extends State<KalenderPage> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month);
      _selectedDate = now;
    });
  }

  Future<void> _addTaskOnSelectedDate() async {
    final data = AppScope.dataOf(context);
    final result = await showDialog<Task>(
      context: context,
      builder: (context) => TaskDialog(
        presetDate: _selectedDate,
        courseSuggestions: data.knownCourses,
      ),
    );
    if (result != null) {
      await data.upsertTask(result);
    }
  }

  Future<void> _addScheduleOnSelectedDate() async {
    final data = AppScope.dataOf(context);
    final result = await showDialog<Schedule>(
      context: context,
      builder: (context) => JadwalDialog(
        presetDay: AppDate.dayKeyOf(_selectedDate),
        existingSchedules: data.schedules,
        courseSuggestions: data.knownCourses,
      ),
    );
    if (result != null) {
      await data.upsertSchedule(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = AppScope.dataOf(context);
    final scheme = Theme.of(context).colorScheme;
    const dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    return ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        final monthStart = DateTime(_currentMonth.year, _currentMonth.month, 1);
        final monthEnd = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
        final leadingEmptyCount = monthStart.weekday % 7;
        final daysInMonth = List<DateTime>.generate(
          monthEnd.day,
          (i) => DateTime(_currentMonth.year, _currentMonth.month, i + 1),
        );
        final cells = <DateTime?>[
          ...List<DateTime?>.filled(leadingEmptyCount, null),
          ...daysInMonth,
        ];

        final selectedTasks = data.tasksForDate(_selectedDate);
        final selectedClasses = data.schedulesForDate(_selectedDate);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Kalender Akademik'),
            actions: [
              IconButton(
                tooltip: 'Hari Ini',
                icon: const Icon(Icons.today_outlined),
                onPressed: _goToToday,
              ),
            ],
          ),
          body: data.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: data.loadAll,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    children: [
                      // Kartu Kalender Bulanan
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    tooltip: 'Bulan sebelumnya',
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: () {
                                      setState(() {
                                        _currentMonth = DateTime(
                                          _currentMonth.year,
                                          _currentMonth.month - 1,
                                        );
                                      });
                                    },
                                  ),
                                  Text(
                                    AppDate.capitalize(AppDate.monthYear(_currentMonth)),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Bulan berikutnya',
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: () {
                                      setState(() {
                                        _currentMonth = DateTime(
                                          _currentMonth.year,
                                          _currentMonth.month + 1,
                                        );
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  for (final name in dayNames)
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          name,
                                          style: TextStyle(
                                            color: scheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: cells.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  mainAxisSpacing: 6,
                                  crossAxisSpacing: 6,
                                ),
                                itemBuilder: (context, index) {
                                  final day = cells[index];
                                  if (day == null) return const SizedBox.shrink();

                                  final hasTask = data.tasksForDate(day).isNotEmpty;
                                  final hasClass = data.schedulesForDate(day).isNotEmpty;
                                  final isSelected = AppDate.isSameDay(day, _selectedDate);
                                  final isToday = AppDate.isSameDay(day, DateTime.now());

                                  return InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () => setState(() => _selectedDate = day),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? scheme.primary.withValues(alpha: 0.16)
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? scheme.primary
                                              : (isToday
                                                  ? scheme.primary.withValues(alpha: 0.5)
                                                  : scheme.outlineVariant),
                                          width: isSelected ? 1.8 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Text(
                                            '${day.day}',
                                            style: TextStyle(
                                              color: isToday || isSelected
                                                  ? scheme.primary
                                                  : scheme.onSurface,
                                              fontWeight: isToday || isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          if (hasTask || hasClass)
                                            Positioned(
                                              bottom: 5,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (hasClass)
                                                    Container(
                                                      width: 6,
                                                      height: 6,
                                                      margin: const EdgeInsets.symmetric(
                                                        horizontal: 1.5,
                                                      ),
                                                      decoration: const BoxDecoration(
                                                        color: AppColors.classEvent,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                  if (hasTask)
                                                    Container(
                                                      width: 6,
                                                      height: 6,
                                                      margin: const EdgeInsets.symmetric(
                                                        horizontal: 1.5,
                                                      ),
                                                      decoration: const BoxDecoration(
                                                        color: AppColors.taskEvent,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              // Legenda
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _LegendDot(color: AppColors.classEvent, label: 'Kelas'),
                                  SizedBox(width: 16),
                                  _LegendDot(color: AppColors.taskEvent, label: 'Tenggat Tugas'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Header tanggal terpilih + tombol tambah cepat
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppDate.capitalize(AppDate.weekdayDayMonth(_selectedDate)),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Tambah kegiatan',
                            onSelected: (value) {
                              if (value == 'task') {
                                _addTaskOnSelectedDate();
                              } else if (value == 'class') {
                                _addScheduleOnSelectedDate();
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'task',
                                child: Text('+ Tugas pada tanggal ini'),
                              ),
                              PopupMenuItem(
                                value: 'class',
                                child: Text('+ Jadwal kelas hari ini'),
                              ),
                            ],
                            child: const Chip(
                              avatar: Icon(Icons.add, size: 16),
                              label: Text('Tambah'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (selectedTasks.isEmpty && selectedClasses.isEmpty)
                        const EmptyStateCard(
                          icon: Icons.event_available_outlined,
                          title: 'Tidak ada kegiatan pada tanggal ini',
                          subtitle: 'Pilih tanggal lain atau tambahkan tugas / jadwal baru.',
                        )
                      else ...[
                        for (final c in selectedClasses)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _CalendarEventTile(
                              title: c.courseTitle,
                              subtitle: [
                                c.timeRange,
                                if (c.location.trim().isNotEmpty) c.location.trim(),
                                if (c.instructor.trim().isNotEmpty) c.instructor.trim(),
                              ].join(' • '),
                              badgeLabel: 'Kelas',
                              color: AppColors.classEvent,
                              icon: Icons.school_outlined,
                            ),
                          ),
                        for (final t in selectedTasks)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _CalendarEventTile(
                              title: t.title,
                              subtitle: t.course.trim().isNotEmpty
                                  ? '${t.course} • ${t.completed ? 'Selesai' : 'Belum selesai'}'
                                  : (t.completed ? 'Selesai' : 'Belum selesai'),
                              badgeLabel: 'Tugas',
                              color: AppColors.taskEvent,
                              icon: t.completed
                                  ? Icons.check_circle_outline
                                  : Icons.assignment_outlined,
                              onTap: () => data.toggleTaskCompleted(t.id),
                            ),
                          ),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _CalendarEventTile extends StatelessWidget {
  const _CalendarEventTile({
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.color,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String badgeLabel;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 5)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
