import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/app_theme.dart';
import '../core/date_utils.dart';
import '../core/validators.dart';
import '../models/schedule.dart';
import '../widgets/course_suggestion_field.dart';
import '../widgets/delete_confirmation.dart';
import '../widgets/empty_state_card.dart';

/// Halaman Jadwal Kuliah Mingguan.
class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  DateTime _selectedDay = DateTime.now();

  Future<void> _openScheduleDialog({Schedule? schedule, String? presetDay}) async {
    final data = AppScope.dataOf(context);
    final result = await showDialog<Schedule>(
      context: context,
      builder: (context) => JadwalDialog(
        schedule: schedule,
        presetDay: presetDay,
        existingSchedules: data.schedules,
        courseSuggestions: data.knownCourses,
      ),
    );
    if (result != null) {
      await data.upsertSchedule(result);
    }
  }

  Future<void> _confirmDelete(Schedule schedule) async {
    final data = AppScope.dataOf(context);
    await confirmDeleteWithUndo(
      context: context,
      title: 'Hapus Jadwal?',
      itemName: schedule.courseTitle,
      onDelete: () => data.deleteSchedule(schedule.id),
      onUndo: () => data.upsertSchedule(schedule),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = AppScope.dataOf(context);
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        final startOfWeek = AppDate.startOfWeek(_selectedDay);
        final daysOfWeek = List<DateTime>.generate(
          7,
          (i) => DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + i),
        );
        final selectedDayKey = AppDate.dayKeyOf(_selectedDay);
        final selectedSchedules = data.schedulesForDay(selectedDayKey);

        final upcomingDays = AppDate.dayKeys.where((d) => d != selectedDayKey).toList();
        final hasAnyUpcoming = upcomingDays.any((d) => data.schedulesForDay(d).isNotEmpty);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Jadwal Kuliah'),
            actions: [
              IconButton(
                tooltip: 'Kembali ke Hari Ini',
                icon: const Icon(Icons.today_outlined),
                onPressed: () => setState(() => _selectedDay = DateTime.now()),
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
                      // Pemilih hari mingguan
                      const Text(
                        'Jadwal Mingguan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              for (final date in daysOfWeek)
                                _DaySelectorItem(
                                  date: date,
                                  isSelected: AppDate.isSameDay(date, _selectedDay),
                                  isToday: AppDate.isSameDay(date, DateTime.now()),
                                  hasClass: data.schedulesForDate(date).isNotEmpty,
                                  onTap: () => setState(() => _selectedDay = date),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Kartu jadwal untuk hari yang dipilih
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
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
                                          AppDate.capitalize(AppDate.weekday(_selectedDay)),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                          ),
                                        ),
                                        Text(
                                          AppDate.fullDate(_selectedDay),
                                          style: TextStyle(
                                            color: scheme.onSurfaceVariant,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FilledButton.tonalIcon(
                                    onPressed: () => _openScheduleDialog(presetDay: selectedDayKey),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Tambah'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              if (selectedSchedules.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 22),
                                  child: Center(
                                    child: Text(
                                      'Tidak ada kelas pada hari ${AppDate.capitalize(AppDate.weekday(_selectedDay))}',
                                      style: TextStyle(color: scheme.onSurfaceVariant),
                                    ),
                                  ),
                                )
                              else
                                for (final item in selectedSchedules)
                                  _ScheduleCardItem(
                                    schedule: item,
                                    hasConflict: data.findConflictingSchedules(item).isNotEmpty,
                                    onEdit: () => _openScheduleDialog(schedule: item),
                                    onDelete: () => _confirmDelete(item),
                                  ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Jadwal hari lainnya
                      const Text(
                        'Hari Lainnya Minggu Ini',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      if (!hasAnyUpcoming)
                        const EmptyStateCard(
                          icon: Icons.event_busy_outlined,
                          title: 'Belum ada jadwal di hari lain',
                          subtitle: 'Ketuk tombol + untuk menambahkan jadwal kuliah baru.',
                        )
                      else
                        for (final dayKey in upcomingDays)
                          if (data.schedulesForDay(dayKey).isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _UpcomingDayCard(
                                dayKey: dayKey,
                                schedules: data.schedulesForDay(dayKey),
                                onTapDay: () {
                                  final targetWeekday = AppDate.weekdayOfKey(dayKey);
                                  final targetDate = DateTime(
                                    startOfWeek.year,
                                    startOfWeek.month,
                                    startOfWeek.day + (targetWeekday - 1),
                                  );
                                  setState(() => _selectedDay = targetDate);
                                },
                              ),
                            ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openScheduleDialog(presetDay: selectedDayKey),
            tooltip: 'Tambah Jadwal',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _DaySelectorItem extends StatelessWidget {
  const _DaySelectorItem({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.hasClass,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool hasClass;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dayShort = AppDate.weekdayShort(date);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dayShort,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.primary
                    : (isToday ? scheme.primary.withValues(alpha: 0.14) : Colors.transparent),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: isSelected
                      ? scheme.onPrimary
                      : (isToday ? scheme.primary : scheme.onSurface),
                  fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: hasClass ? scheme.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCardItem extends StatelessWidget {
  const _ScheduleCardItem({
    required this.schedule,
    required this.hasConflict,
    required this.onEdit,
    required this.onDelete,
  });

  final Schedule schedule;
  final bool hasConflict;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isOngoing = schedule.isOngoingAt(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasConflict
              ? AppColors.warning
              : (isOngoing ? AppColors.success : scheme.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  schedule.startTime,
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                width: 2,
                height: 16,
                color: scheme.outlineVariant,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  schedule.endTime,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        schedule.courseTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    if (isOngoing)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Berlangsung',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (schedule.instructor.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 15, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            schedule.instructor,
                            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (schedule.location.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 15, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            schedule.location,
                            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (hasConflict)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 15, color: AppColors.warning),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Jam bentrok dengan kelas lain di hari ini',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Hapus')),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingDayCard extends StatelessWidget {
  const _UpcomingDayCard({
    required this.dayKey,
    required this.schedules,
    required this.onTapDay,
  });

  final String dayKey;
  final List<Schedule> schedules;
  final VoidCallback onTapDay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTapDay,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppDate.capitalize(dayKey),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    '${schedules.length} kelas',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final item in schedules)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 92,
                        child: Text(
                          item.timeRange,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.location.trim().isNotEmpty
                                ? '${item.courseTitle} • ${item.location}'
                                : item.courseTitle,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog Tambah / Edit Jadwal dengan TimePicker & validasi jam.
class JadwalDialog extends StatefulWidget {
  const JadwalDialog({
    required this.existingSchedules,
    required this.courseSuggestions,
    this.schedule,
    this.presetDay,
    super.key,
  });

  final Schedule? schedule;
  final String? presetDay;
  final List<Schedule> existingSchedules;
  final List<String> courseSuggestions;

  @override
  State<JadwalDialog> createState() => _JadwalDialogState();
}

class _JadwalDialogState extends State<JadwalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleC;
  late final TextEditingController _instructorC;
  late final TextEditingController _locationC;
  late String _day;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _timeError;

  @override
  void initState() {
    super.initState();
    _titleC = TextEditingController(text: widget.schedule?.courseTitle ?? '');
    _instructorC = TextEditingController(text: widget.schedule?.instructor ?? '');
    _locationC = TextEditingController(text: widget.schedule?.location ?? '');
    final initialDay = (widget.schedule?.day ?? widget.presetDay ?? 'senin').toLowerCase();
    _day = AppDate.dayKeys.contains(initialDay) ? initialDay : 'senin';
    _startTime = AppDate.parseTime(widget.schedule?.startTime ?? '') ??
        const TimeOfDay(hour: 8, minute: 0);
    _endTime = AppDate.parseTime(widget.schedule?.endTime ?? '') ??
        const TimeOfDay(hour: 9, minute: 40);
  }

  @override
  void dispose() {
    _titleC.dispose();
    _instructorC.dispose();
    _locationC.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      helpText: 'Pilih Jam Mulai',
    );
    if (picked == null) return;
    setState(() {
      _startTime = picked;
      if (AppDate.toMinutes(_endTime) <= AppDate.toMinutes(_startTime)) {
        _endTime = AppDate.fromMinutes(AppDate.toMinutes(_startTime) + 100);
      }
      _timeError = null;
    });
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      helpText: 'Pilih Jam Selesai',
    );
    if (picked == null) return;
    setState(() {
      _endTime = picked;
      _timeError = null;
    });
  }

  Schedule _buildCandidate() => Schedule(
        id: widget.schedule?.id ?? generateId(),
        courseTitle: _titleC.text.trim(),
        day: _day,
        startTime: AppDate.formatTime(_startTime),
        endTime: AppDate.formatTime(_endTime),
        instructor: _instructorC.text.trim(),
        location: _locationC.text.trim(),
      );

  void _submit() {
    final validForm = _formKey.currentState?.validate() ?? false;
    if (AppDate.toMinutes(_endTime) <= AppDate.toMinutes(_startTime)) {
      setState(() => _timeError = 'Jam selesai harus lebih besar dari jam mulai');
      return;
    }
    if (!validForm) return;
    Navigator.of(context).pop(_buildCandidate());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final candidate = _buildCandidate();
    final conflicts = widget.existingSchedules.where((s) => s.overlaps(candidate)).toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.schedule == null ? 'Tambah Jadwal' : 'Edit Jadwal',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _day,
                    items: [
                      for (final d in AppDate.dayKeys)
                        DropdownMenuItem(value: d, child: Text(AppDate.capitalize(d))),
                    ],
                    onChanged: (v) => setState(() => _day = v ?? 'senin'),
                    decoration: const InputDecoration(
                      labelText: 'Hari',
                      prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  CourseSuggestionField(
                    controller: _titleC,
                    suggestions: widget.courseSuggestions,
                    labelText: 'Mata Kuliah',
                    hintText: 'Contoh: Pemrograman Aplikasi Mobile',
                    validator: (v) => Validators.notEmpty(v, 'Mata kuliah wajib diisi'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _TimePickerField(
                          label: 'Jam Mulai',
                          time: _startTime,
                          onTap: _pickStartTime,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimePickerField(
                          label: 'Jam Selesai',
                          time: _endTime,
                          onTap: _pickEndTime,
                        ),
                      ),
                    ],
                  ),
                  if (_timeError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _timeError!,
                      style: TextStyle(color: scheme.error, fontSize: 12),
                    ),
                  ],
                  if (conflicts.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppColors.warning, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bentrok dengan: ${conflicts.map((e) => e.courseTitle).join(', ')}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _instructorC,
                    decoration: const InputDecoration(
                      labelText: 'Dosen / Pengajar (Opsional)',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _locationC,
                    decoration: const InputDecoration(
                      labelText: 'Ruangan / Lokasi (Opsional)',
                      prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Simpan Jadwal'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  const _TimePickerField({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.access_time, size: 18),
        ),
        child: Text(
          AppDate.formatTime(time),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
