import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/app_theme.dart';
import '../core/date_utils.dart';
import '../models/note.dart';
import '../models/task.dart';
import 'catatan_page.dart';
import 'notifikasi_page.dart';
import 'profile_page.dart';

/// Halaman Beranda (Dashboard) KuliahKu.
class BerandaPage extends StatelessWidget {
  const BerandaPage({required this.onSelectTab, super.key});

  /// Berpindah tab pada MainShell (1 = Jadwal, 2 = Tugas, 3 = Catatan, 4 = Kalender).
  final ValueChanged<int> onSelectTab;

  Future<void> _openNoteEditor(BuildContext context, Note note) async {
    final data = AppScope.dataOf(context);
    final updated = await showDialog<Note>(
      context: context,
      builder: (context) => NoteDialog(
        note: note,
        courseSuggestions: data.knownCourses,
      ),
    );
    if (updated != null) {
      await data.upsertNote(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.authOf(context);
    final data = AppScope.dataOf(context);
    final settings = AppScope.settingsOf(context);
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: Listenable.merge([auth, data, settings]),
      builder: (context, _) {
        final user = auth.currentUser;
        final now = DateTime.now();
        final todaySchedules = data.schedulesForDate(now);
        final urgentTasks = data.urgentTasks(now);
        final recentNotes = data.recentNotes;
        final unreadNotifCount =
            settings.notificationsEnabled ? data.unreadNotificationCount(now) : 0;

        return Scaffold(
          appBar: AppBar(
            centerTitle: false,
            title: const Text(
              'Beranda',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            actions: [
              IconButton(
                tooltip: 'Notifikasi',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => NotifikasiPage(onSelectTab: onSelectTab),
                    ),
                  );
                },
                icon: Badge(
                  isLabelVisible: unreadNotifCount > 0,
                  label: Text('$unreadNotifCount'),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16, left: 4),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const ProfilePage(),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    child: Text(
                      user?.initial ?? 'M',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: data.loadAll,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                // Kartu Sambutan + Jadwal Hari Ini
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppDate.greeting(now)}, ${user?.fullName ?? 'Mahasiswa'}!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Semester ${user?.semester ?? '-'} • ${user?.programStudi ?? '-'}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppDate.capitalize(AppDate.longDate(now)),
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Jadwal Hari Ini (${todaySchedules.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: () => onSelectTab(1),
                            child: const Text(
                              'Lihat Semua',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: data.isLoading
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 18),
                                child: Center(
                                  child: CircularProgressIndicator(color: Colors.white),
                                ),
                              )
                            : (todaySchedules.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: Text(
                                        'Tidak ada kelas hari ini',
                                        style: TextStyle(color: Colors.white70, fontSize: 14),
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: [
                                      for (final s in todaySchedules)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 5),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: s.isOngoingAt(now)
                                                      ? AppColors.success
                                                      : Colors.white24,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  s.timeRange,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      s.courseTitle,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    if (s.location.trim().isNotEmpty)
                                                      Text(
                                                        s.location,
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  )),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Seksi Tugas Mendesak
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tugas Mendesak (${urgentTasks.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () => onSelectTab(2),
                      child: const Text('Lihat Semua'),
                    ),
                  ],
                ),
                Card(
                  child: data.isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : (urgentTasks.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'Tidak ada tugas mendesak',
                                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                for (final task in urgentTasks.take(3))
                                  _UrgentTaskTile(
                                    task: task,
                                    onToggle: () => data.toggleTaskCompleted(task.id),
                                    onTap: () => onSelectTab(2),
                                  ),
                                if (urgentTasks.length > 3)
                                  TextButton(
                                    onPressed: () => onSelectTab(2),
                                    child: Text('Lihat ${urgentTasks.length - 3} tugas lainnya'),
                                  ),
                              ],
                            )),
                ),
                const SizedBox(height: 22),

                // Seksi Catatan Terakhir
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Catatan Terakhir',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () => onSelectTab(3),
                      child: const Text('Lihat Semua'),
                    ),
                  ],
                ),
                Card(
                  child: data.isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : (recentNotes.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'Belum ada catatan kuliah',
                                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                for (final note in recentNotes)
                                  ListTile(
                                    title: Text(
                                      note.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      note.content,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Text(
                                      AppDate.shortDate(note.lastUpdated),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    onTap: () => _openNoteEditor(context, note),
                                  ),
                              ],
                            )),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UrgentTaskTile extends StatelessWidget {
  const _UrgentTaskTile({
    required this.task,
    required this.onToggle,
    required this.onTap,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final days = task.daysUntilDue();
    final isOverdue = days < 0;
    final badgeText = isOverdue
        ? 'Terlambat'
        : (days == 0 ? 'Hari Ini' : (days == 1 ? 'Besok' : '$days Hari'));
    final badgeColor = isOverdue ? AppColors.danger : AppColors.warning;

    return ListTile(
      leading: Checkbox(
        value: task.completed,
        onChanged: (_) => onToggle(),
      ),
      title: Text(
        task.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        task.course.trim().isNotEmpty
            ? '${task.course} • ${AppDate.fullDate(task.dueDate)}'
            : AppDate.fullDate(task.dueDate),
      ),
      trailing: Container(
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
      onTap: onTap,
    );
  }
}
