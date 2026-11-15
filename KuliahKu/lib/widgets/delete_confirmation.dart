import 'package:flutter/material.dart';

/// Menampilkan dialog konfirmasi hapus, lalu menjalankan [onDelete] dan
/// menampilkan SnackBar dengan tombol **Urungkan** ([onUndo]).
Future<void> confirmDeleteWithUndo({
  required BuildContext context,
  required String title,
  required String itemName,
  required Future<void> Function() onDelete,
  required Future<void> Function() onUndo,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final scheme = Theme.of(context).colorScheme;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text('Apakah Anda yakin ingin menghapus "$itemName"?'),
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
          child: const Text('Hapus'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  await onDelete();

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('"$itemName" dihapus'),
        action: SnackBarAction(
          label: 'Urungkan',
          onPressed: () {
            onUndo();
          },
        ),
      ),
    );
}
