import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../core/app_scope.dart';
import '../core/date_utils.dart';
import '../core/validators.dart';
import '../models/note.dart';
import '../widgets/course_suggestion_field.dart';
import '../widgets/delete_confirmation.dart';
import '../widgets/empty_state_card.dart';

/// Halaman Catatan Kuliah.
class CatatanPage extends StatefulWidget {
  const CatatanPage({super.key});

  @override
  State<CatatanPage> createState() => _CatatanPageState();
}

class _CatatanPageState extends State<CatatanPage> {
  String _searchQuery = '';
  String? _selectedCategory;

  Future<void> _openNoteDialog({Note? note}) async {
    final data = AppScope.dataOf(context);
    final result = await showDialog<Note>(
      context: context,
      builder: (context) => NoteDialog(
        note: note,
        courseSuggestions: data.knownCourses,
      ),
    );
    if (result != null) {
      await data.upsertNote(result);
    }
  }

  Future<void> _confirmDelete(Note note) async {
    final data = AppScope.dataOf(context);
    await confirmDeleteWithUndo(
      context: context,
      title: 'Hapus Catatan?',
      itemName: note.title,
      onDelete: () => data.deleteNote(note.id),
      onUndo: () => data.upsertNote(note),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = AppScope.dataOf(context);

    return ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        final categories = data.noteCategories;
        final activeCategory =
            (_selectedCategory != null && categories.contains(_selectedCategory))
                ? _selectedCategory
                : null;

        final filteredNotes = data.notes.where((note) {
          final matchesSearch = note.matches(_searchQuery);
          final matchesCategory =
              activeCategory == null || note.course.trim() == activeCategory;
          return matchesSearch && matchesCategory;
        }).toList(growable: false);

        return Scaffold(
          appBar: AppBar(title: const Text('Catatan Kuliah')),
          body: data.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: data.loadAll,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth >= 900
                          ? 4
                          : (constraints.maxWidth >= 600 ? 3 : 2);
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        children: [
                          // Pencarian
                          TextField(
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: 'Cari judul, isi, atau mata kuliah...',
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
                          // Kategori mata kuliah
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('Semua'),
                                  selected: activeCategory == null,
                                  onSelected: (_) => setState(() => _selectedCategory = null),
                                ),
                                for (final cat in categories)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: ChoiceChip(
                                      label: Text(cat),
                                      selected: activeCategory == cat,
                                      onSelected: (_) => setState(() => _selectedCategory = cat),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (filteredNotes.isEmpty)
                            EmptyStateCard(
                              icon: Icons.sticky_note_2_outlined,
                              title: data.notes.isEmpty
                                  ? 'Belum ada catatan'
                                  : 'Tidak ada catatan yang cocok',
                              subtitle: data.notes.isEmpty
                                  ? 'Tulis rangkuman materi atau poin penting perkuliahanmu.'
                                  : 'Coba ubah kata kunci pencarian atau kategori.',
                              actionLabel: data.notes.isEmpty ? 'Tambah Catatan' : null,
                              onAction: data.notes.isEmpty ? _openNoteDialog : null,
                            )
                          else
                            StaggeredGrid.count(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              children: [
                                for (final note in filteredNotes)
                                  _NoteCard(
                                    note: note,
                                    onTap: () => _openNoteDialog(note: note),
                                    onDelete: () => _confirmDelete(note),
                                  ),
                              ],
                            ),
                          const SizedBox(height: 80),
                        ],
                      );
                    },
                  ),
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: _openNoteDialog,
            tooltip: 'Tambah Catatan',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (note.hasCourse)
                    Container(
                      constraints: const BoxConstraints(maxWidth: 88),
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.secondary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        note.course,
                        style: TextStyle(
                          color: scheme.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                note.content,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      AppDate.shortDate(note.lastUpdated),
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Hapus catatan',
                    icon: Icon(Icons.delete_outline, size: 18, color: scheme.error),
                    onPressed: onDelete,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
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

/// Dialog Tambah / Edit Catatan.
class NoteDialog extends StatefulWidget {
  const NoteDialog({
    required this.courseSuggestions,
    this.note,
    super.key,
  });

  final Note? note;
  final List<String> courseSuggestions;

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleC;
  late final TextEditingController _contentC;
  late final TextEditingController _courseC;

  @override
  void initState() {
    super.initState();
    _titleC = TextEditingController(text: widget.note?.title ?? '');
    _contentC = TextEditingController(text: widget.note?.content ?? '');
    _courseC = TextEditingController(text: widget.note?.course ?? '');
  }

  @override
  void dispose() {
    _titleC.dispose();
    _contentC.dispose();
    _courseC.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      Note(
        id: widget.note?.id ?? generateId(),
        title: _titleC.text.trim(),
        content: _contentC.text.trim(),
        course: _courseC.text.trim(),
        lastUpdated: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.note != null;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
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
                          isEdit ? 'Edit Catatan' : 'Tambah Catatan',
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
                      labelText: 'Judul Catatan',
                      hintText: 'Contoh: Ringkasan State Management Flutter',
                    ),
                    validator: (v) => Validators.notEmpty(v, 'Judul catatan wajib diisi'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _contentC,
                    minLines: 5,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      labelText: 'Isi Catatan',
                      hintText: 'Tulis isi catatan di sini...',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => Validators.notEmpty(v, 'Isi catatan wajib diisi'),
                  ),
                  const SizedBox(height: 14),
                  CourseSuggestionField(
                    controller: _courseC,
                    suggestions: widget.courseSuggestions,
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: _submit,
                    child: Text(isEdit ? 'Simpan Perubahan' : 'Simpan Catatan'),
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
