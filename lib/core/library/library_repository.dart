import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';

import '../rules/ringtone_rules.dart';
import 'app_database.dart';
import 'app_paths.dart';

/// One output in My files. The file lives in `Documents/Library/`.
class LibraryItem {
  const LibraryItem({
    required this.id,
    required this.relPath,
    required this.name,
    required this.format,
    required this.bitrateKbps,
    required this.bytes,
    required this.durationSec,
    required this.sourceName,
    required this.sourceBytes,
    required this.sourceIsVideo,
    required this.tookMs,
    required this.createdAt,
    this.toneType,
    this.thumbRel,
  });

  final String id;
  final String relPath;
  final String name;

  /// `OutFormat.name`, e.g. `mp3`.
  final String format;
  final int bitrateKbps;
  final int bytes;
  final double durationSec;
  final ToneType? toneType;
  final String sourceName;
  final int sourceBytes;
  final bool sourceIsVideo;
  final int tookMs;
  final String? thumbRel;
  final DateTime createdAt;

  bool get isTone => toneType != null;
}

class LibraryRepository {
  LibraryRepository(this._db, this._paths);

  final AppDatabase _db;
  final AppPaths _paths;
  final _changes = StreamController<void>.broadcast();

  /// Fires after every add or delete.
  Stream<void> get changes => _changes.stream;

  String absolutePath(LibraryItem item) => _paths.absolute(item.relPath);

  String? thumbnailPath(LibraryItem item) =>
      item.thumbRel == null ? null : _paths.inContainer(item.thumbRel!);

  Future<List<LibraryItem>> list({int? limit}) async {
    final rows = await _db
        .customSelect(
          'SELECT * FROM library_items ORDER BY created_at DESC'
          '${limit == null ? '' : ' LIMIT $limit'}',
        )
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<int> count() async {
    final row = await _db
        .customSelect('SELECT COUNT(*) AS n FROM library_items')
        .getSingle();
    return row.read<int>('n');
  }

  Future<void> add(LibraryItem item) async {
    await _db.customStatement(
      'INSERT INTO library_items (id, rel_path, name, format, bitrate_kbps, '
      'bytes, duration_sec, tone_type, source_name, source_bytes, '
      'source_is_video, took_ms, thumb_rel, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        item.id,
        item.relPath,
        item.name,
        item.format,
        item.bitrateKbps,
        item.bytes,
        item.durationSec,
        item.toneType?.name,
        item.sourceName,
        item.sourceBytes,
        item.sourceIsVideo ? 1 : 0,
        item.tookMs,
        item.thumbRel,
        item.createdAt.millisecondsSinceEpoch,
      ],
    );
    _changes.add(null);
  }

  /// Renames the real file in `Documents/Library/`. Returns false when the
  /// name is taken or empty.
  Future<bool> rename(LibraryItem item, String newBase) async {
    final clean = newBase.replaceAll(RegExp(r'[/:\\]'), ' ').trim();
    if (clean.isEmpty) return false;
    final source = File(absolutePath(item));
    final ext = item.name.contains('.')
        ? item.name.split('.').last
        : item.format;
    final newName = '$clean.$ext';
    if (newName == item.name) return true;
    final target = File('${source.parent.path}/$newName');
    if (target.existsSync()) return false;
    if (source.existsSync()) await source.rename(target.path);
    await _db.customStatement(
      'UPDATE library_items SET name = ?, rel_path = ? WHERE id = ?',
      [newName, _paths.relative(target.path), item.id],
    );
    _changes.add(null);
    return true;
  }

  /// Removes the library copy only. Copies in the Tunely folder and the
  /// original in Photos are never touched (`05` §8).
  Future<void> delete(LibraryItem item) async {
    final file = File(absolutePath(item));
    if (file.existsSync()) {
      await file.delete();
    }
    await _db.customStatement('DELETE FROM library_items WHERE id = ?', [
      item.id,
    ]);
    _changes.add(null);
  }

  LibraryItem _fromRow(QueryRow row) {
    final tone = row.readNullable<String>('tone_type');
    return LibraryItem(
      id: row.read<String>('id'),
      relPath: row.read<String>('rel_path'),
      name: row.read<String>('name'),
      format: row.read<String>('format'),
      bitrateKbps: row.read<int>('bitrate_kbps'),
      bytes: row.read<int>('bytes'),
      durationSec: row.read<double>('duration_sec'),
      toneType: tone == null ? null : ToneType.values.byName(tone),
      sourceName: row.read<String>('source_name'),
      sourceBytes: row.read<int>('source_bytes'),
      sourceIsVideo: row.read<int>('source_is_video') == 1,
      tookMs: row.read<int>('took_ms'),
      thumbRel: row.readNullable<String>('thumb_rel'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('created_at'),
      ),
    );
  }

  Future<void> dispose() => _changes.close();
}
