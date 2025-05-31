// ignore_for_file: deprecated_member_use
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'jadwal.dart';
import 'tugas.dart';
import 'kalender.dart';
import 'profile.dart';
import 'halamanutama.dart';

class Note {
  String id;
  String title;
  String content;
  String? course;
  DateTime lastUpdated;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.course,
    required this.lastUpdated,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        course: json['course'],
        lastUpdated: DateTime.parse(json['lastUpdated']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'course': course,
        'lastUpdated': lastUpdated.toIso8601String(),
      };
}

class CatatanPage extends StatefulWidget {
  const CatatanPage({super.key});
  @override
  State<CatatanPage> createState() => _CatatanPageState();
}

class _CatatanPageState extends State<CatatanPage> {
  List<Note> notes = [];
  bool isLoading = true;
  String searchQuery = '';
  String? selectedCategory;
  bool isAddNoteOpen = false;

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/notes.json');
  }

  Future<void> loadNotes() async {
    setState(() => isLoading = true);
    try {
      final file = await _file;
      if (await file.exists()) {
        final content = await file.readAsString();
        final List data = jsonDecode(content);
        notes = data.map((e) => Note.fromJson(e)).toList();
      } else {
        notes = [];
      }
    } catch (e) {
      notes = [];
    }
    setState(() => isLoading = false);
  }

  Future<void> saveNotes() async {
    final file = await _file;
    await file.writeAsString(jsonEncode(notes.map((e) => e.toJson()).toList()));
  }

  Future<void> addOrEditNote({Note? note}) async {
    final result = await showDialog<Note>(
      context: context,
      builder: (context) => NoteDialog(note: note),
    );
    if (result != null) {
      setState(() {
        if (note != null) {
          final idx = notes.indexWhere((n) => n.id == note.id);
          if (idx != -1) notes[idx] = result;
        } else {
          notes.add(result);
        }
      });
      await saveNotes();
    }
  }

  Future<void> deleteNote(Note note) async {
    setState(() {
      notes.removeWhere((n) => n.id == note.id);
    });
    await saveNotes();
  }

  List<String> get categories {
    final set = <String>{};
    for (var n in notes) {
      if (n.course != null && n.course!.isNotEmpty) set.add(n.course!);
    }
    return set.toList();
  }

  List<Note> get filteredNotes {
    return notes.where((note) {
      final matchesSearch = searchQuery.isEmpty ||
          note.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategory == null || note.course == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Catatan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: loadNotes,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // Header
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Catatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                IconButton(
                  icon: const Icon(Icons.add, color: Color(0xFF23243A)),
                  onPressed: () => addOrEditNote(),
                  tooltip: 'Tambah Catatan',
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Search
            Stack(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari catatan...',
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (v) => setState(() => searchQuery = v),
                ),
                const Positioned(
                  left: 12,
                  top: 10,
                  child: Icon(Icons.search, color: Colors.grey, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Categories
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryButton(
                    label: 'Semua',
                    selected: selectedCategory == null,
                    onTap: () => setState(() => selectedCategory = null),
                  ),
                  ...categories.map((cat) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _CategoryButton(
                          label: cat,
                          selected: selectedCategory == cat,
                          onTap: () => setState(() => selectedCategory = cat),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Notes Grid
            if (isLoading)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: List.generate(
                  4,
                  (i) => Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              )
            else if (filteredNotes.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Center(
                  child: Text(
                    searchQuery.isNotEmpty || selectedCategory != null
                        ? "Tidak ada catatan yang sesuai pencarian"
                        : "Belum ada catatan",
                    style: const TextStyle(color: Color(0xFF8B8B9E), fontSize: 16),
                  ),
                ),
              )
            else
              StaggeredGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: filteredNotes.map((note) {
                  return GestureDetector(
                    onTap: () => addOrEditNote(note: note),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Judul dan badge
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    note.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (note.course != null && note.course!.isNotEmpty)
                                  Container(
                                    constraints: const BoxConstraints(maxWidth: 70),
                                    margin: const EdgeInsets.only(left: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.13),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      note.course!,
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Isi catatan
                            Text(
                              note.content,
                              style: const TextStyle(color: Colors.black87, fontSize: 13),
                            ),
                            const SizedBox(height: 10),
                            // Bagian bawah: tanggal & hapus
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('d MMM yyyy', 'id_ID').format(note.lastUpdated),
                                  style: const TextStyle(color: Color(0xFF8B8B9E), fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  onPressed: () => deleteNote(note),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  splashRadius: 18,
                                ),
                              ],
                            ),
                          ],
                        ),
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
        backgroundColor: const Color(0xFF23243A),
        onPressed: () => addOrEditNote(),
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
                active: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TugasPage()),
                  );
                },
              ),
              _NavIcon(
                icon: Icons.sticky_note_2, // gunakan sticky_note_2 agar konsisten
                label: 'Catatan',
                active: true,
                onTap: () {},
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

class _CategoryButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? const Color(0xFF23243A) : Colors.white,
        foregroundColor: selected ? Colors.white : const Color(0xFF23243A),
        side: BorderSide(color: selected ? const Color(0xFF23243A) : Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }
}

class NoteDialog extends StatefulWidget {
  final Note? note;
  const NoteDialog({super.key, this.note});

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController titleC;
  late TextEditingController contentC;
  late TextEditingController courseC;

  @override
  void initState() {
    super.initState();
    titleC = TextEditingController(text: widget.note?.title ?? '');
    contentC = TextEditingController(text: widget.note?.content ?? '');
    courseC = TextEditingController(text: widget.note?.course ?? '');
  }

  @override
  void dispose() {
    titleC.dispose();
    contentC.dispose();
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
                Text(
                  widget.note == null ? 'Tambah Catatan' : 'Edit Catatan',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: titleC,
                  decoration: InputDecoration(
                    labelText: 'Judul Catatan',
                    hintText: 'Judul catatan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Judul wajib diisi' : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: contentC,
                  decoration: InputDecoration(
                    labelText: 'Isi Catatan',
                    hintText: 'Tulis isi catatan...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  minLines: 4,
                  maxLines: 8,
                  validator: (v) => v == null || v.isEmpty ? 'Isi catatan wajib diisi' : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: courseC,
                  decoration: InputDecoration(
                    labelText: 'Mata Kuliah (Opsional)',
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
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(
                        context,
                        Note(
                          id: widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleC.text,
                          content: contentC.text,
                          course: courseC.text,
                          lastUpdated: DateTime.now(),
                        ),
                      );
                    }
                  },
                  child: const Text('Simpan', style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 17)),
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