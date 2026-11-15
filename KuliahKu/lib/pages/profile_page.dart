import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/date_utils.dart';
import '../core/validators.dart';
import '../models/app_user.dart';

/// Halaman Profil & Pengaturan Mahasiswa.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameC;
  late final TextEditingController _nimC;
  late final TextEditingController _programC;
  late final TextEditingController _semesterC;

  bool _isEditing = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController();
    _nimC = TextEditingController();
    _programC = TextEditingController();
    _semesterC = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final user = AppScope.authOf(context).currentUser;
      _syncControllers(user);
      _initialized = true;
    }
  }

  void _syncControllers(AppUser? user) {
    _nameC.text = user?.fullName ?? '';
    _nimC.text = user?.nim ?? '';
    _programC.text = user?.programStudi ?? '';
    _semesterC.text = user?.semester ?? '1';
  }

  @override
  void dispose() {
    _nameC.dispose();
    _nimC.dispose();
    _programC.dispose();
    _semesterC.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = AppScope.authOf(context);
    final messenger = ScaffoldMessenger.of(context);
    await auth.updateProfile(
      fullName: _nameC.text,
      programStudi: _programC.text,
      semester: _semesterC.text,
      nim: _nimC.text,
    );
    if (!mounted) return;
    setState(() => _isEditing = false);
    messenger.showSnackBar(
      const SnackBar(content: Text('Profil berhasil diperbarui')),
    );
  }

  Future<void> _showSemesterPicker(AppUser user) async {
    final auth = AppScope.authOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final current = int.tryParse(user.semester) ?? 1;

    final picked = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Pilih Semester Aktif'),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var s = 1; s <= 14; s++)
                  ChoiceChip(
                    label: Text('Semester $s'),
                    selected: s == current,
                    onSelected: (_) => Navigator.of(dialogContext).pop(s),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (picked == null || picked == current) return;
    await auth.updateProfile(semester: picked.toString());
    _semesterC.text = picked.toString();
    messenger.showSnackBar(
      SnackBar(content: Text('Semester aktif diubah ke Semester $picked')),
    );
  }

  Future<void> _confirmLogout() async {
    final auth = AppScope.authOf(context);
    final nav = Navigator.of(context);
    final scheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text('Anda perlu masuk kembali untuk mengakses akun ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    nav.popUntil((route) => route.isFirst);
    await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.authOf(context);
    final settings = AppScope.settingsOf(context);
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: Listenable.merge([auth, settings]),
      builder: (context, _) {
        final user = auth.currentUser;
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Sesi berakhir')));
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Profil & Pengaturan')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header Profil
              Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    child: Text(
                      user.initial,
                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.programStudi} • Semester ${user.semester}',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Informasi Akademik
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.school_outlined, size: 20, color: scheme.primary),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Informasi Akademik',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isEditing = !_isEditing;
                                  if (!_isEditing) _syncControllers(user);
                                });
                              },
                              icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined, size: 18),
                              label: Text(_isEditing ? 'Batal' : 'Edit'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_isEditing) ...[
                          TextFormField(
                            controller: _nameC,
                            decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                            validator: (v) => Validators.notEmpty(v, 'Nama wajib diisi'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nimC,
                            decoration: const InputDecoration(labelText: 'NIM'),
                            validator: Validators.nim,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _programC,
                                  decoration: const InputDecoration(labelText: 'Program Studi'),
                                  validator: (v) =>
                                      Validators.notEmpty(v, 'Program studi wajib diisi'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _semesterC,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Semester'),
                                  validator: Validators.semester,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _saveProfile,
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Simpan Perubahan'),
                            ),
                          ),
                        ] else ...[
                          _InfoRow(label: 'Nama Lengkap', value: user.fullName),
                          const Divider(height: 20),
                          _InfoRow(
                            label: 'NIM',
                            value: user.nim.trim().isEmpty ? 'Belum diisi' : user.nim,
                          ),
                          const Divider(height: 20),
                          _InfoRow(label: 'Program Studi', value: user.programStudi),
                          const Divider(height: 20),
                          _InfoRow(label: 'Email', value: user.email),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Manajemen Semester
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timeline_rounded, size: 20, color: scheme.primary),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Manajemen Semester',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showSemesterPicker(user),
                            child: const Text('Ubah Semester'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Semester Aktif',
                        value: 'Semester ${user.semester} (${AppDate.academicPeriod()})',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pengaturan Aplikasi
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
                        child: Row(
                          children: [
                            Icon(Icons.tune_rounded, size: 20, color: scheme.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'Pengaturan Aplikasi',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      SwitchListTile(
                        value: settings.isDarkMode,
                        onChanged: settings.setDarkMode,
                        secondary: Icon(
                          settings.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                        ),
                        title: const Text('Mode Gelap'),
                        subtitle: const Text('Gunakan tampilan gelap yang nyaman di mata'),
                      ),
                      SwitchListTile(
                        value: settings.notificationsEnabled,
                        onChanged: settings.setNotificationsEnabled,
                        secondary: const Icon(Icons.notifications_active_outlined),
                        title: const Text('Notifikasi Pengingat'),
                        subtitle: const Text('Tampilkan badge pengingat tugas & kelas hari ini'),
                      ),
                      const ListTile(
                        leading: Icon(Icons.language_outlined),
                        title: Text('Bahasa Aplikasi'),
                        subtitle: Text('Bahasa Indonesia (id_ID)'),
                      ),
                      const ListTile(
                        leading: Icon(Icons.info_outline_rounded),
                        title: Text('Versi Aplikasi'),
                        subtitle: Text('KuliahKu v2.0.0 (Build 2)'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Keluar
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.error,
                  side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
                ),
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar dari Akun'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
