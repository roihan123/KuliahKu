import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../models/app_notification.dart';
import '../widgets/empty_state_card.dart';

/// Halaman Notifikasi in-app yang menampilkan pengingat otomatis dari
/// tugas mendekati tenggat & jadwal kelas hari ini.
class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({this.onSelectTab, super.key});

  /// Callback opsional untuk berpindah ke tab tertentu pada MainShell.
  final ValueChanged<int>? onSelectTab;

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  bool _onlyUnread = false;

  @override
  Widget build(BuildContext context) {
    final data = AppScope.dataOf(context);
    final settings = AppScope.settingsOf(context);
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: Listenable.merge([data, settings]),
      builder: (context, _) {
        final allItems = data.buildNotifications();
        final unreadCount = allItems.where((e) => !e.isRead).length;
        final items = _onlyUnread ? allItems.where((e) => !e.isRead).toList() : allItems;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifikasi'),
            actions: [
              IconButton(
                tooltip: 'Tes Notifikasi Sistem HP',
                icon: const Icon(Icons.send_to_mobile_outlined),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final shown = await data.sendTestOrSummarySystemNotification();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        shown
                            ? 'Notifikasi dikirim ke status bar HP!'
                            : 'Izinkan akses notifikasi di HP Android untuk menampilkan di status bar.',
                      ),
                    ),
                  );
                },
              ),
              if (unreadCount > 0)
                TextButton.icon(
                  onPressed: data.markAllNotificationsRead,
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Tandai dibaca'),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              if (!settings.notificationsEnabled)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_off_outlined, color: scheme.onSecondaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Notifikasi pengingat sedang dinonaktifkan di Pengaturan Profil.',
                          style: TextStyle(color: scheme.onSecondaryContainer, fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () => settings.setNotificationsEnabled(true),
                        child: const Text('Aktifkan'),
                      ),
                    ],
                  ),
                ),
              // Filter Semua / Belum Dibaca
              Row(
                children: [
                  ChoiceChip(
                    label: Text('Semua (${allItems.length})'),
                    selected: !_onlyUnread,
                    onSelected: (_) => setState(() => _onlyUnread = false),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Belum Dibaca ($unreadCount)'),
                    selected: _onlyUnread,
                    onSelected: (_) => setState(() => _onlyUnread = true),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                EmptyStateCard(
                  icon: Icons.notifications_none_rounded,
                  title: _onlyUnread
                      ? 'Semua notifikasi sudah dibaca'
                      : 'Tidak ada pengingat saat ini',
                  subtitle: 'Pengingat tugas mendekati tenggat & jadwal kuliah hari ini akan muncul di sini.',
                )
              else
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _NotificationTile(
                      item: item,
                      onTap: () async {
                        final nav = Navigator.of(context);
                        await data.markNotificationRead(item.id);
                        if (widget.onSelectTab != null) {
                          nav.pop();
                          widget.onSelectTab!(item.targetTabIndex);
                        }
                      },
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.onTap,
  });

  final AppNotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: item.isRead ? null : scheme.primary.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: item.color,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: item.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                        fontSize: 15,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (item.detail.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.detail,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
