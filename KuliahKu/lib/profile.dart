import 'package:flutter/material.dart';
import 'main.dart' show updateAkun, AuthPage, darkModeNotifier;

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? user;
  const ProfilePage({super.key, this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController nimController;
  late TextEditingController programController;
  late Map<String, dynamic> user;
  bool notifOn = true;
  bool darkMode = false;
  String language = 'id';
  bool isEditing = false;

void handleLogout() {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => const AuthPage()),
    (route) => false,
  );
}

  @override
  void initState() {
    super.initState();
    user = widget.user ?? {};
    nimController = TextEditingController(text: user['nim'] ?? '');
    programController = TextEditingController(text: user['program_studi'] ?? '');
  }

  Future<void> saveProfile() async {
    user['nim'] = nimController.text;
    user['program_studi'] = programController.text;
    await updateAkun(
      user['email'],
      {
        ...user.map((k, v) => MapEntry(k, v?.toString() ?? '')),
      },
    );
    setState(() {
      isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil berhasil diperbarui')),
    );
  }

  void showSemesterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ganti Semester'),
        content: const Text('Fitur ganti semester belum tersedia.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Header
          Column(
            children: [
              Container(
                width: 96,
                height: 96,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2A2D43),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=150&h=150',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Text(
                user['full_name'] ?? '-',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Text(
                '${user['program_studi']} - Semester ${user['semester']}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Informasi Akademik
          Card(
            color: const Color(0xFF2A2D43),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Informasi Akademik', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                      ),
                      IconButton(
                        icon: Icon(isEditing ? Icons.close : Icons.edit, color: Colors.blue),
                        tooltip: isEditing ? 'Batal' : 'Edit',
                        onPressed: () {
                          setState(() {
                            isEditing = !isEditing;
                            if (!isEditing) {
                              // Reset ke data awal jika batal
                              nimController.text = user['nim'] ?? '';
                              programController.text = user['program_studi'] ?? '';
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('NIM', style: TextStyle(color: Colors.grey)),
                      SizedBox(
                        width: 150,
                        child: isEditing
                            ? TextFormField(
                                controller: nimController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                                ),
                                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                              )
                            : Text(
                                user['nim'] ?? '-',
                                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                              ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Program Studi', style: TextStyle(color: Colors.grey)),
                      SizedBox(
                        width: 150,
                        child: isEditing
                            ? TextFormField(
                                controller: programController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                                ),
                                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                              )
                            : Text(
                                user['program_studi'] ?? '-',
                                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                              ),
                      ),
                    ],
                  ),
                  if (isEditing)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ElevatedButton(
                        onPressed: saveProfile,
                        child: const Text('Simpan'),
                      ),
                    ),
                ],
              ),
            ),
          ),


          // Manajemen Semester
          Card(
            color: const Color(0xFF2A2D43),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Manajemen Semester', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Semester Aktif', style: TextStyle(color: Colors.grey)),
                      Text('Semester ${user['semester']} (Ganjil 2024)', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Pengaturan Aplikasi
          Card(
            color: const Color(0xFF2A2D43),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pengaturan Aplikasi', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: notifOn,
                    onChanged: (v) => setState(() => notifOn = v),
                    title: const Text('Notifikasi', style: TextStyle(color: Colors.grey)),
                    subtitle: const Text('Aktifkan notifikasi pengingat', style: TextStyle(color: Colors.grey)),
                  ),
                  ListTile(
                    title: const Text('Bahasa', style: TextStyle(color: Colors.grey)),
                    subtitle: const Text('Pilih bahasa aplikasi', style: TextStyle(color: Colors.grey)),
                    trailing: DropdownButton<String>(
                      value: language,
                      items: const [
                        DropdownMenuItem(value: 'id', child: Text('Indonesia', style: TextStyle(color: Colors.grey))),
                        // DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(color: Colors.grey) )),
                      ],
                      onChanged: (v) => setState(() => language = v ?? 'id'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Logout Button
          OutlinedButton(
            onPressed: handleLogout,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
            child: const Text('Keluar'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
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