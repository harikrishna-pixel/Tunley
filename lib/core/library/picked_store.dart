import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_paths.dart';

/// Durable index of files the user imported in Choose a file.
/// Paths live under `Documents/Picked/` so they survive relaunch.
class PickedStore {
  PickedStore(this._prefs, this._paths);

  /// In-memory index for widget/unit tests.
  PickedStore.memory(this._paths) : _prefs = null;

  final SharedPreferences? _prefs;
  final AppPaths _paths;
  String? _memory;

  static const _key = 'picked_sources';
  static const _max = 50;

  Directory get directory {
    final dir = Directory('${_paths.documents}/Picked');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// Copy [path] into Documents/Picked when it isn't already there.
  Future<String> durablePath(String path, String name) async {
    final dir = directory;
    if (path.startsWith('${dir.path}/')) return path;
    final source = File(path);
    if (!await source.exists()) return path;
    final base = name.contains('.')
        ? name.substring(0, name.lastIndexOf('.'))
        : name;
    final ext = name.contains('.')
        ? name.substring(name.lastIndexOf('.') + 1)
        : path.split('.').last;
    var dest = '${dir.path}/$base.$ext';
    var n = 2;
    while (await File(dest).exists()) {
      dest = '${dir.path}/$base $n.$ext';
      n++;
    }
    await source.copy(dest);
    return dest;
  }

  List<({String path, String name})> read() {
    final raw = _prefs?.getString(_key) ?? _memory;
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          if (item is Map)
            (
              path: '${item['path'] ?? ''}',
              name: '${item['name'] ?? ''}',
            ),
      ].where((e) => e.path.isNotEmpty).toList();
    } on Object {
      return const [];
    }
  }

  Future<void> write(List<({String path, String name})> sources) async {
    final kept = sources.take(_max).toList();
    final encoded = jsonEncode([
      for (final s in kept) {'path': s.path, 'name': s.name},
    ]);
    final prefs = _prefs;
    if (prefs != null) {
      await prefs.setString(_key, encoded);
    } else {
      _memory = encoded;
    }
  }
}
