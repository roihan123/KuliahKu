import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/app_theme.dart';
import '../core/date_utils.dart';
import '../core/validators.dart';
import '../models/task.dart';
import '../widgets/course_suggestion_field.dart';
import '../widgets/delete_confirmation.dart';
import '../widgets/empty_state_card.dart';

enum TaskFilter { all, urgent, thisWeek, completed }

/// Halaman Manajemen Tugas Kuliah.
class TugasPage extends StatefulWidget {
  const TugasPage({super.key});

  @override
  State<TugasPage> createState() => _TugasPageState();
}

class _TugasPageState extends State<TugasPage> {
  TaskFilter _filter = TaskFilter.all;
  String _searchQuery = '';

  Future<void> _openTaskDialog({Task? task}) async {
    final data = AppScope.dataOf(context);
    final result = await showDialog<Task>(
      context: context,
      builder: (context) => TaskDialog(
        task: task,
        courseSuggestions: data.knownCourses,
      ),
    );
    if (result != null) {
      await data.upsertTask(result);
    }
  }

  Future<void> _confirmDelete(Task task) async {
    final data = AppScope.dataOf(context);
    await confirmDeleteWithUndo(
      context: context,
      title: 'Hapus Tugas?',
      itemName: task.title,
      onDelete: () => data.deleteTask(task.id),
      onUndo: () => data.upsertTask(task),
    );
  }

  List<Task> _applyFilter(List<Task> all) {
    final now = DateTime.now();
    final q = _searchQuery.trim().toLowerCase();
    return all.where((task) {
      if (q.isNotEmpty) {
        final match = task.title.toLowerCase().contains(q) ||
            task.description.toLowerCase().contains(q) ||
            task.course.toLowerCase().contains(q);
        if (!match) return false;
      }
      switch (_filter) {
        case TaskFilter.urgent:
          return task.isUrgent(now);
        case TaskFilter.thisWeek:
          return task.isDueThisWeek(now);
        case TaskFilter.completed:
          return task.completed;
        case TaskFilter.all:
          return true;
      }
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final data = AppScope.dataOf(context);

    return ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        final allTasks = data.tasks;
        final now = DateTime.now();
        final urgentCount = allTasks.where((t) => t.isUrgent(now)).length;
        final weekCount = allTasks.where((t) => t.isDueThisWeek(now)).length;
        final doneCount = allTasks.where((t) => t.completed).length;
        final filtered = _applyFilter(allTasks);

        return Scaffold(
          appBar: AppBar(title: const Text('Daftar Tugas')),
          body: data.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: data.loadAll,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    children: [
                      // Pencarian tugas
                      TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Cari judul, deskripsi, atau mata kuliah...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => setState(() => _searchQuery = ''),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _TaskFilterChip(
                              label: 'Semua (${allTasks.length})',
                              selected: _filter == TaskFilter.all,
                              onTap: () => setState(() => _filter = TaskFilter.all),
                            ),
                            const SizedBox(width: 8),
                            _TaskFilterChip(
                              label: 'Mendesak ($urgentCount)',
                              selected: _filter == TaskFilter.urgent,
                              onTap: () => setState(() => _filter = TaskFilter.urgent),
                            ),
                            const SizedBox(width: 8),
                            _TaskFilterChip(
                              label: 'Minggu Ini ($weekCount)',
                              selected: _filter == TaskFilter.thisWeek,
                              onTap: () => setState(() => _filter = TaskFilter.thisWeek),
                            ),
                            const SizedBox(width: 8),
                            _TaskFilterChip(
                              label: 'Selesai ($doneCount)',
                              selected: _filter == TaskFilter.completed,
                              onTap: () => setState(() => _filter = TaskFilter.completed),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (filtered.isEmpty)
                        EmptyStateCard(
                          icon: Icons.assignment_turned_in_outlined,
                          title: allTasks.isEmpty
                              ? 'Belum ada tugas'
                              : 'Tidak ada tugas pada filter ini',
                          subtitle: allTasks.isEmpty
                              ? 'Catat tugas kuliahmu agar tidak terlewat tenggat waktu.'
                              : 'Coba ubah filter atau kata kunci pencarian.',
                          actionLabel: allTasks.isEmpty ? 'Tambah Tugas' : null,
                          onAction: allTasks.isEmpty ? _openTaskDialog : null,
                        )
                      else
                        for (final task in filtered)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TaskCard(
                              task: task,
                              onToggleComplete: () => data.toggleTaskCompleted(task.id),
                              onEdit: () => _openTaskDialog(task: task),
                              onDelete: () => _confirmDelete(task),
                            ),
                          ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: _openTaskDialog,
            tooltip: 'Tambah Tugas',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _TaskFilterChip extends StatelessWidget {
  const _TaskFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  (String, Color) _badgeInfo(DateTime now) {
    final days = task.daysUntilDue(now);
    switch (task.status(now)) {
      case TaskStatus.completed:
        return ('Selesai', AppColors.success);
      case TaskStatus.overdue:
        return ('Terlambat ${-days}h', AppColors.danger);
      case TaskStatus.today:
        return ('Hari Ini', AppColors.warning);
      case TaskStatus.tomorrow:
        return ('Besok', AppColors.warning);
      case TaskStatus.soon:
        return ('$days Hari Lagi', AppColors.caution);
      case TaskStatus.thisWeek:
        return ('$days Hari Lagi', AppColors.info);
      case TaskStatus.later:
        return ('Mendatang', AppColors.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (badgeText, badgeColor) = _badgeInfo(DateTime.now());

    return Card(
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: task.completed,
                    onChanged: (_) => onToggleComplete(),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            decoration: task.completed ? TextDecoration.lineThrough : null,
                            color: task.completed ? scheme.onSurfaceVariant : scheme.onSurface,
                          ),
                        ),
                        if (task.description.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              decoration: task.completed ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.event_outlined, size: 15, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.course.trim().isNotEmpty
                          ? '${task.course} • ${AppDate.fullDate(task.dueDate)}'
                          : AppDate.fullDate(task.dueDate),
                      style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: onEdit,
                    child: const Text('Edit'),
                  ),
                  TextButton(
                    onPressed: onToggleComplete,
                    child: Text(task.completed ? 'Batalkan' : 'Selesai'),
                  ),
                  IconButton(
                    tooltip: 'Hapus tugas',
                    icon: Icon(Icons.delete_outline, size: 20, color: scheme.error),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog Tambah / Edit Tugas.
class TaskDialog extends StatefulWidget {
  const TaskDialog({
    required this.courseSuggestions,
    this.task,
    this.presetDate,
    super.key,
  });

  final Task? task;
  final DateTime? presetDate;
  final List<String> courseSuggestions;

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleC;
  late final TextEditingController _descC;
  late final TextEditingController _courseC;
  late DateTime _dueDate;

  @override
  void initState() {
    super.initState();
    _titleC = TextEditingController(text: widget.task?.title ?? '');
    _descC = TextEditingController(text: widget.task?.description ?? '');
    _courseC = TextEditingController(text: widget.task?.course ?? '');
    _dueDate = widget.task?.dueDate ?? widget.presetDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    _courseC.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      Task(
        id: widget.task?.id ?? generateId(),
        title: _titleC.text.trim(),
        description: _descC.text.trim(),
        course: _courseC.text.trim(),
        dueDate: AppDate.dateOnly(_dueDate),
        completed: widget.task?.completed ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.task != null;
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
                          isEdit ? 'Edit Tugas' : 'Tambah Tugas',
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
                  TextFormField(
                    controller: _titleC,
                    decoration: const InputDecoration(
                      labelText: 'Judul Tugas',
                      hintText: 'Contoh: Laporan Praktikum Modul 3',
                      prefixIcon: Icon(Icons.assignment_outlined, size: 20),
                    ),
                    validator: (v) => Validators.notEmpty(v, 'Judul tugas wajib diisi'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descC,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi (Opsional)',
                      hintText: 'Detail atau catatan pengerjaan tugas...',
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickDueDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tenggat Waktu',
                        prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                      ),
                      child: Text(
                        AppDate.longDate(_dueDate),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  CourseSuggestionField(
                    controller: _courseC,
                    suggestions: widget.courseSuggestions,
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: _submit,
                    child: Text(isEdit ? 'Simpan Perubahan' : 'Simpan Tugas'),
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
