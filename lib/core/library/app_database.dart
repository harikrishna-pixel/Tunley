import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// Local store for library rows and counters. Raw SQL because drift's code
/// generator doesn't resolve on this Flutter SDK; switch to generated tables
/// after the SDK upgrade.
class AppDatabase extends GeneratedDatabase {
  AppDatabase(super.executor);

  factory AppDatabase.file(String path) {
    File(path).parent.createSync(recursive: true);
    return AppDatabase(NativeDatabase.createInBackground(File(path)));
  }

  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await customStatement('''
        CREATE TABLE library_items (
          id TEXT NOT NULL PRIMARY KEY,
          rel_path TEXT NOT NULL,
          name TEXT NOT NULL,
          format TEXT NOT NULL,
          bitrate_kbps INTEGER NOT NULL,
          bytes INTEGER NOT NULL,
          duration_sec REAL NOT NULL,
          tone_type TEXT,
          source_name TEXT NOT NULL,
          source_bytes INTEGER NOT NULL,
          source_is_video INTEGER NOT NULL,
          took_ms INTEGER NOT NULL,
          thumb_rel TEXT,
          created_at INTEGER NOT NULL
        )''');
      await customStatement(
        'CREATE INDEX library_items_created ON library_items (created_at DESC)',
      );
      await customStatement(
        'CREATE TABLE kv (key TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL)',
      );
    },
  );

  Future<String?> readValue(String key) async {
    final row = await customSelect(
      'SELECT value FROM kv WHERE key = ?',
      variables: [Variable.withString(key)],
    ).getSingleOrNull();
    return row?.read<String>('value');
  }

  Future<void> writeValue(String key, String value) {
    return customStatement(
      'INSERT INTO kv (key, value) VALUES (?, ?) '
      'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
      [key, value],
    );
  }
}
