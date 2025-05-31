// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'catatan.dart';
import 'jadwal.dart';
import 'kalender.dart';
import 'halamanutama.dart';

enum TaskFilter { all, urgent, thisWeek, completed }

class Task {
  String id;
  String title;
  String description;
  String course;
  DateTime dueDate;
  bool completed;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.course,
    required this.dueDate,
    this.completed = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        course: json['course'],
        dueDate: DateTime.parse(json['dueDate']),
        completed: json['completed'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'course': course,
        'dueDate': dueDate.toIso8601String(),
        'completed': completed,
      };
}

class TugasPage extends StatefulWidget {
  const TugasPage({super.key});

  @override
  State<TugasPage> createState() => _TugasPageState();
}

class _TugasPageState extends State<TugasPage> {
  List<Task> tasks = [];
  bool isLoading = true;
  TaskFilter filter = TaskFilter.all;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/tasks.json');
  }

  Future<void> loadTasks() async {
    setState(() => isLoading = true);
    try {
      final file = await _file;
      if (await file.exists()) {
        final content = await file.readAsString();
        final List data = jsonDecode(content);
        tasks = data.map((e) => Task.fromJson(e)).toList();
      } else {
        tasks = [];
      }
    } catch (e) {
      tasks = [];
    }
    setState(() => isLoading = false);
  }

  Future<void> saveTasks() async {
    final file = await _file;
    await file.writeAsString(jsonEncode(tasks.map((e) => e.toJson()).toList()));
  }

  Future<void> addOrEditTask({Task? task}) async {
    final result = await showDialog<Task>(
      context: context,
      builder: (context) => TaskDialog(task: task),
    );
    if (result != null) {
      setState(() {
        if (task != null) {
          // Edit
          final idx = tasks.indexWhere((t) => t.id == task.id);
          if (idx != -1) tasks[idx] = result;
        } else {
          // Add
          tasks.add(result);
        }
      });
      await saveTasks();
    }
  }

  Future<void> deleteTask(Task task) async {
    setState(() {
      tasks.removeWhere((t) => t.id == task.id);
    });
    await saveTasks();
  }

  Future<void> toggleComplete(Task task) async {
    setState(() {
      task.completed = !task.completed;
    });
    await saveTasks();
  }

  List<Task> get filteredTasks {
    final today = DateTime.now();
    return tasks.where((task) {
      final daysUntilDue = task.dueDate.difference(today).inDays;
      switch (filter) {
        case TaskFilter.urgent:
          return !task.completed && daysUntilDue <= 3;
        case TaskFilter.thisWeek:
          return !task.completed && daysUntilDue <= 7;
        case TaskFilter.completed:
          return task.completed;
        case TaskFilter.all:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text('Tugas', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
        centerTitle: true,

      ),
      body: RefreshIndicator(
        onRefresh: loadTasks,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            const SizedBox(height: 8),
            const Text('Daftar Tugas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Ganti Row filter dengan SingleChildScrollView
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterButton(
                          label: 'Semua',
                          selected: filter == TaskFilter.all,
                          onTap: () => setState(() => filter = TaskFilter.all),
                        ),
                        const SizedBox(width: 8),
                        _FilterButton(
                          label: 'Mendesak',
                          selected: filter == TaskFilter.urgent,
                          onTap: () => setState(() => filter = TaskFilter.urgent),
                        ),
                        const SizedBox(width: 8),
                        _FilterButton(
                          label: 'Minggu Ini',
                          selected: filter == TaskFilter.thisWeek,
                          onTap: () => setState(() => filter = TaskFilter.thisWeek),
                        ),
                        const SizedBox(width: 8),
                        _FilterButton(
                          label: 'Selesai',
                          selected: filter == TaskFilter.completed,
                          onTap: () => setState(() => filter = TaskFilter.completed),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // OutlinedButton.icon(
                //   icon: const Icon(Icons.filter_list, size: 18),
                //   label: const Text('Filter', style: TextStyle(fontSize: 14)),
                //   style: OutlinedButton.styleFrom(
                //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                //   ),
                //   onPressed: () {},
                // ),
              ],
            ),
            const SizedBox(height: 24),
            if (isLoading)
              ...List.generate(3, (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )),
            if (!isLoading && filteredTasks.isEmpty)
              Container(
                height: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Text(
                  "Belum ada tugas",
                  style: TextStyle(color: Color(0xFF8B8B9E), fontSize: 16),
                ),
              ),
            if (!isLoading)
              ...filteredTasks.map((task) {
                final today = DateTime.now();
                final daysUntilDue = task.dueDate.difference(today).inDays;
                String dueBadgeText = "Mendatang";
                Color badgeColor = const Color(0xFF3B82F6);
                if (task.completed) {
                  dueBadgeText = "Selesai";
                  badgeColor = const Color(0xFF22C55E);
                } else if (daysUntilDue < 0) {
                  dueBadgeText = "Terlambat";
                  badgeColor = const Color(0xFFEF4444);
                } else if (daysUntilDue == 0) {
                  dueBadgeText = "Hari Ini";
                  badgeColor = const Color(0xFFF59E42);
                } else if (daysUntilDue == 1) {
                  dueBadgeText = "Besok";
                  badgeColor = const Color(0xFFF59E42);
                } else if (daysUntilDue <= 3) {
                  dueBadgeText = "$daysUntilDue Hari";
                  badgeColor = const Color(0xFFFBBF24);
                } else if (daysUntilDue <= 7) {
                  dueBadgeText = "$daysUntilDue Hari";
                  badgeColor = const Color(0xFF3B82F6);
                }
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  decoration: task.completed ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeColor.withOpacity(0.13),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                dueBadgeText,
                                style: TextStyle(
                                  color: badgeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          style: TextStyle(
                            color: Colors.grey[700],
                            decoration: task.completed ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${task.course} - ${DateFormat('d MMMM', 'id_ID').format(task.dueDate)}",
                              style: const TextStyle(fontSize: 13, color: Color(0xFF8B8B9E)),
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () => addOrEditTask(task: task),
                                  child: const Text('Edit'),
                                ),
                                TextButton(
                                  onPressed: () => toggleComplete(task),
                                  child: Text(task.completed ? 'Batalkan' : 'Selesai'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  onPressed: () => deleteTask(task),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF23243A),
        onPressed: () => addOrEditTask(),
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
                active: true,
                onTap: () {},
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

class _FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF23243A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? const Color(0xFF23243A) : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF23243A),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class TaskDialog extends StatefulWidget {
  final Task? task;
  const TaskDialog({super.key, this.task});

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController titleC;
  late TextEditingController descC;
  late TextEditingController courseC;
  DateTime? dueDate;

  @override
  void initState() {
    super.initState();
    titleC = TextEditingController(text: widget.task?.title ?? '');
    descC = TextEditingController(text: widget.task?.description ?? '');
    courseC = TextEditingController(text: widget.task?.course ?? '');
    dueDate = widget.task?.dueDate ?? DateTime.now();
  }

  @override
  void dispose() {
    titleC.dispose();
    descC.dispose();
    courseC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tambah Tugas',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: titleC,
                  decoration: InputDecoration(
                    labelText: 'Judul Tugas',
                    hintText: 'Judul tugas',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Judul wajib diisi' : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: descC,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    hintText: 'Deskripsi tugas',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 18),
                Text('Tenggat Waktu', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dueDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      locale: const Locale('id', 'ID'),
                    );
                    if (picked != null) setState(() => dueDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          DateFormat('d MMMM yyyy', 'id_ID').format(dueDate ?? DateTime.now()),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        const Icon(Icons.calendar_today, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: courseC,
                  decoration: InputDecoration(
                    labelText: 'Mata Kuliah',
                    hintText: 'Nama mata kuliah',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF23243A),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate() && dueDate != null) {
                      Navigator.pop(
                        context,
                        Task(
                          id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleC.text,
                          description: descC.text,
                          course: courseC.text,
                          dueDate: dueDate!,
                          completed: widget.task?.completed ?? false,
                        ),
                      );
                    }
                  },
                  child: const Text('Simpan', style: TextStyle(fontSize: 17)),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(fontSize: 17)),
                ),
              ],
            ),
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

  const _NavIcon({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: active ? const Color(0xFF23243A) : Colors.grey[400],
          ),
          Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF23243A) : Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}