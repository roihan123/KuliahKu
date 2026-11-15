import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Penyimpanan JSON lokal di direktori dokumen aplikasi.
///
/// - Direktori dicari sekali saja (bukan setiap baca/tulis).
/// - Penulisan atomik (tulis ke `.tmp` lalu rename) supaya file tidak korup
///   jika aplikasi ditutup di tengah proses.
/// - Penulisan ke file yang sama diantrikan sehingga tidak saling tumpang tindih.
class JsonStorage {
  JsonStorage(this.directory);

  final Directory directory;
  final Map<String, Future<void>> _queues = {};

  static Future<JsonStorage> create() async => JsonStorage(await getApplicationDocumentsDirectory());

  File file(String name) => File('${directory.path}${Platform.pathSeparator}$name');

  Future<bool> exists(String name) => file(name).exists();

  Future<Object?> read(String name) async {
    await _queues[name];
    final f = file(name);
    try {
      if (!await f.exists()) return null;
      final text = await f.readAsString();
      if (text.trim().isEmpty) return null;
      return jsonDecode(text);
    } catch (e) {
      debugPrint('JsonStorage: gagal membaca $name: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> readList(String name) async {
    final data = await read(name);
    if (data is! List) return [];
    return [
      for (final item in data)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  Future<Map<String, dynamic>?> readMap(String name) async {
    final data = await read(name);
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  Future<void> write(String name, Object? data) {
    // Encode sekarang supaya yang tersimpan adalah snapshot data saat ini.
    final encoded = jsonEncode(data);
    final previous = _queues[name] ?? Future<void>.value();
    final next = previous.then((_) => _writeAtomic(name, encoded));
    _queues[name] = next;
    return next;
  }

  Future<void> _writeAtomic(String name, String content) async {
    final target = file(name);
    final tmp = File('${target.path}.tmp');
    try {
      await tmp.writeAsString(content, flush: true);
      try {
        await tmp.rename(target.path);
      } on FileSystemException {
        // Beberapa platform tidak mengizinkan rename menimpa file yang ada.
        await target.writeAsString(content, flush: true);
        if (await tmp.exists()) await tmp.delete();
      }
    } catch (e) {
      debugPrint('JsonStorage: gagal menulis $name: $e');
    }
  }

  Future<void> delete(String name) async {
    await _queues[name];
    try {
      final f = file(name);
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('JsonStorage: gagal menghapus $name: $e');
    }
  }

  Future<void> rename(String from, String to) async {
    try {
      final f = file(from);
      if (await f.exists()) await f.rename(file(to).path);
    } catch (e) {
      debugPrint('JsonStorage: gagal rename $from -> $to: $e');
    }
  }
}
