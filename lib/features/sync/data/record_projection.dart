import 'dart:convert';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:hearth_sync/hearth_sync.dart';

import '../../../services/database/database.dart';
import 'lullaby_records.dart';

/// Writes Lullaby's Drift tables from row changes, whoever made them: the
/// kernel (inside `DriftPersist.applyTables`, in the kernel's own transaction)
/// or [DirectRecordWriter] while sync is off. One code path, so a record looks
/// the same in Drift however it got there.
///
/// It must be total over anything the kernel can legally send. A throw here
/// leaves the kernel ahead of the store, and the same changes would throw again
/// on the next open. So:
/// - parents land before children, and children leave before parents, whatever
///   order the changes list them in (foreign keys stay enforced);
/// - a record whose baby is not on this phone (not synced yet, or its author was
///   forgotten) is parked in `sync_parked_rows`, not inserted, and lands when its
///   baby does;
/// - rows of tables this version does not know are ignored;
/// - the device-local columns (`babies.is_active`, `babies.photo_path`) are never
///   written from the log.
class RecordProjection {
  RecordProjection(this.db);

  final AppDatabase db;
  bool _parkedReady = false;

  TableInfo _info(String name) =>
      db.allTables.firstWhere((t) => t.actualTableName == name);

  Future<void> _ensureParked() async {
    if (_parkedReady) return;
    await db.customStatement(
      'CREATE TABLE IF NOT EXISTS sync_parked_rows ('
      'tbl TEXT NOT NULL, id TEXT NOT NULL, baby_id TEXT, fields TEXT NOT NULL, '
      'PRIMARY KEY (tbl, id))',
    );
    _parkedReady = true;
  }

  bool _gapReady = false;

  Future<void> _ensureGap() async {
    if (_gapReady) return;
    await db.customStatement(
      'CREATE TABLE IF NOT EXISTS sync_gap_deletes ('
      'tbl TEXT NOT NULL, id TEXT NOT NULL, PRIMARY KEY (tbl, id))',
    );
    _gapReady = true;
  }

  /// [id] was deleted while sync was on but the log could not be opened (the
  /// words were missing): remember it, so the delete reaches the log when the
  /// words return instead of the record living on in the household.
  Future<void> noteGapDelete(RecordTable table, String id) async {
    await _ensureGap();
    await db.customStatement(
      'INSERT OR IGNORE INTO sync_gap_deletes (tbl, id) VALUES (?, ?)',
      [table.name, id],
    );
  }

  /// [id] was written again (an Undo) in the gap: it is no longer deleted.
  Future<void> clearGapDelete(RecordTable table, String id) async {
    await _ensureGap();
    await db.customStatement(
      'DELETE FROM sync_gap_deletes WHERE tbl = ? AND id = ?',
      [table.name, id],
    );
  }

  /// Every delete made in the gap, oldest first. Each stays recorded until
  /// [clearGapDelete] after its replay, so a stop halfway loses none.
  Future<List<(RecordTable, String)>> gapDeletes() async {
    await _ensureGap();
    final rows = await db
        .customSelect('SELECT tbl, id FROM sync_gap_deletes ORDER BY rowid')
        .get();
    return [
      for (final r in rows)
        if (recordTable(r.read<String>('tbl')) case final t?) (t, r.read<String>('id')),
    ];
  }

  /// Sync is off: no delete is owed to any log.
  Future<void> clearGapDeletes() async {
    await _ensureGap();
    await db.customStatement('DELETE FROM sync_gap_deletes');
  }

  /// Apply one call's changes. The caller holds the transaction.
  Future<void> apply(Changes changes) async {
    await _ensureParked();
    Map<String, ({bool active, String? photo})> local = {};
    if (changes.replaceView) local = await _clearAll();

    final visible = <RowUpdate>[];
    final hidden = <RowUpdate>[];
    for (final r in changes.rows) {
      if (recordTable(r.table) == null) {
        developer.log('ignored a row of unknown table ${r.table}', name: 'lullaby.sync');
        continue;
      }
      (r.visible ? visible : hidden).add(r);
    }

    // Parents first.
    for (final r in visible.where((r) => r.table == babiesSpec.name)) {
      await upsert(babiesSpec, r.row, r.fields);
      final kept = local[r.row];
      if (kept != null) {
        await db.customUpdate(
          'UPDATE babies SET is_active = ?, photo_path = ? WHERE id = ?',
          variables: [Variable<bool>(kept.active), Variable<String>(kept.photo), Variable<String>(r.row)],
          updates: {db.babies},
        );
      }
      await _unpark(r.row);
    }
    for (final r in visible.where((r) => r.table != babiesSpec.name)) {
      await upsert(recordTable(r.table)!, r.row, r.fields);
    }
    // Children leave before parents.
    for (final r in hidden.where((r) => r.table != babiesSpec.name)) {
      await hide(recordTable(r.table)!, r.row);
    }
    for (final r in hidden.where((r) => r.table == babiesSpec.name)) {
      await hide(babiesSpec, r.row);
    }

    for (final s in changes.streams) {
      if (s.stream != handoffStream) continue;
      await _note(s);
    }
    await ensureActiveBaby();
  }

  /// Insert [id] or update the given log-encoded [fields] of it. A record whose
  /// baby is not on this phone is parked instead.
  Future<void> upsert(RecordTable table, String id, Map<String, Object?> fields) async {
    await _ensureParked();
    final known = {
      for (final e in fields.entries)
        if (table.field(e.key) != null) e.key: e.value,
    };
    if (table.contained) {
      final babyId = (known['baby_id'] ?? await _storedBaby(table, id)) as String?;
      if (babyId == null || !await _babyHere(babyId)) {
        await _park(table, id, babyId, known);
        return;
      }
    }
    final names = known.keys.toList();
    final exists = (await db
            .customSelect('SELECT 1 FROM ${table.name} WHERE id = ?',
                variables: [Variable<String>(id)])
            .get())
        .isNotEmpty;
    if (exists) {
      // SQLite checks NOT NULL on an INSERT before ON CONFLICT, so a partial
      // write (an edit of a few fields) is a plain UPDATE.
      if (names.isNotEmpty) {
        await db.customUpdate(
          'UPDATE ${table.name} SET ${names.map((n) => '$n = ?').join(', ')} '
          'WHERE id = ?',
          variables: [
            for (final n in names) variableFor(table.field(n)!.kind, known[n]),
            Variable<String>(id),
          ],
          updates: {_info(table.name)},
        );
      }
    } else {
      final cols = ['id', ...names];
      final vars = <Variable<Object>>[
        Variable<String>(id),
        for (final n in names) variableFor(table.field(n)!.kind, known[n]),
      ];
      // A baby that arrives from the log is not selected on this phone until
      // ensureActiveBaby (or the person) picks it.
      if (table == babiesSpec) {
        cols.add('is_active');
        vars.add(const Variable<bool>(false));
      }
      await db.customInsert(
        'INSERT INTO ${table.name} (${cols.join(', ')}) '
        'VALUES (${List.filled(cols.length, '?').join(', ')})',
        variables: vars,
        updates: {_info(table.name)},
      );
    }
    await db.customUpdate(
      'DELETE FROM sync_parked_rows WHERE tbl = ? AND id = ?',
      variables: [Variable<String>(table.name), Variable<String>(id)],
    );
  }

  /// Remove [id] from Drift. Hiding a baby removes its records with it.
  Future<void> hide(RecordTable table, String id) async {
    await _ensureParked();
    if (table == babiesSpec) {
      for (final child in childRecordTables) {
        await db.customUpdate(
          'DELETE FROM ${child.name} WHERE baby_id = ?',
          variables: [Variable<String>(id)],
          updates: {_info(child.name)},
          updateKind: UpdateKind.delete,
        );
      }
      await db.customUpdate(
        'DELETE FROM sync_parked_rows WHERE baby_id = ?',
        variables: [Variable<String>(id)],
      );
    }
    await db.customUpdate(
      'DELETE FROM ${table.name} WHERE id = ?',
      variables: [Variable<String>(id)],
      updates: {_info(table.name)},
      updateKind: UpdateKind.delete,
    );
    await db.customUpdate(
      'DELETE FROM sync_parked_rows WHERE tbl = ? AND id = ?',
      variables: [Variable<String>(table.name), Variable<String>(id)],
    );
  }

  /// [id] of [table] as the log holds it (every synced field), or null.
  Future<Map<String, Object?>?> readRow(RecordTable table, String id) async {
    final rows = await db
        .customSelect('SELECT * FROM ${table.name} WHERE id = ?',
            variables: [Variable<String>(id)])
        .get();
    if (rows.isEmpty) return null;
    return {for (final f in table.fields) f.name: readLogValue(rows.single, f)};
  }

  /// Every row of [table] as the log holds it, by id.
  Future<Map<String, Map<String, Object?>>> readAll(RecordTable table) async {
    final rows = await db.customSelect('SELECT * FROM ${table.name}').get();
    return {
      for (final r in rows)
        r.read<String>('id'): {
          for (final f in table.fields) f.name: readLogValue(r, f),
        },
    };
  }

  /// Keep exactly one baby selected when there are babies: if none is, select
  /// the most recently changed one.
  Future<void> ensureActiveBaby() async {
    final active = await db
        .customSelect('SELECT 1 FROM babies WHERE is_active = 1 LIMIT 1')
        .get();
    if (active.isNotEmpty) return;
    await db.customUpdate(
      'UPDATE babies SET is_active = 1 WHERE id = '
      '(SELECT id FROM babies ORDER BY modified_at DESC LIMIT 1)',
      updates: {db.babies},
    );
  }

  Future<Map<String, ({bool active, String? photo})>> _clearAll() async {
    final kept = {
      for (final r in await db
          .customSelect('SELECT id, is_active, photo_path FROM babies')
          .get())
        r.read<String>('id'): (
          active: r.read<bool>('is_active'),
          photo: r.readNullable<String>('photo_path'),
        ),
    };
    for (final t in [...childRecordTables.reversed, babiesSpec]) {
      await db.customUpdate('DELETE FROM ${t.name}',
          updates: {_info(t.name)}, updateKind: UpdateKind.delete);
    }
    await db.customUpdate('DELETE FROM handoff_notes',
        updates: {db.handoffNotes}, updateKind: UpdateKind.delete);
    await db.customStatement('DELETE FROM sync_parked_rows');
    return kept;
  }

  Future<bool> _babyHere(String id) async => (await db
          .customSelect('SELECT 1 FROM babies WHERE id = ?',
              variables: [Variable<String>(id)])
          .get())
      .isNotEmpty;

  Future<String?> _storedBaby(RecordTable table, String id) async {
    final rows = await db
        .customSelect('SELECT baby_id FROM ${table.name} WHERE id = ?',
            variables: [Variable<String>(id)])
        .get();
    if (rows.isNotEmpty) return rows.single.read<String>('baby_id');
    final parked = await db
        .customSelect('SELECT baby_id FROM sync_parked_rows WHERE tbl = ? AND id = ?',
            variables: [Variable<String>(table.name), Variable<String>(id)])
        .get();
    return parked.isEmpty ? null : parked.single.readNullable<String>('baby_id');
  }

  Future<void> _park(RecordTable table, String id, String? babyId,
      Map<String, Object?> fields) async {
    final before = await db
        .customSelect('SELECT fields FROM sync_parked_rows WHERE tbl = ? AND id = ?',
            variables: [Variable<String>(table.name), Variable<String>(id)])
        .get();
    final merged = <String, Object?>{
      if (before.isNotEmpty)
        ...(jsonDecode(before.single.read<String>('fields')) as Map<String, Object?>),
      ...fields,
    };
    await db.customStatement(
      'INSERT OR REPLACE INTO sync_parked_rows (tbl, id, baby_id, fields) '
      'VALUES (?, ?, ?, ?)',
      [table.name, id, babyId, jsonEncode(merged)],
    );
  }

  Future<void> _unpark(String babyId) async {
    final rows = await db
        .customSelect('SELECT tbl, id, fields FROM sync_parked_rows WHERE baby_id = ?',
            variables: [Variable<String>(babyId)])
        .get();
    for (final r in rows) {
      final table = recordTable(r.read<String>('tbl'));
      if (table == null) continue;
      await upsert(table, r.read<String>('id'),
          jsonDecode(r.read<String>('fields')) as Map<String, Object?>);
    }
  }

  Future<void> _note(StreamUpdate s) async {
    final id = hex(s.id);
    if (!s.present) {
      await db.customUpdate('DELETE FROM handoff_notes WHERE id = ?',
          variables: [Variable<String>(id)],
          updates: {db.handoffNotes},
          updateKind: UpdateKind.delete);
      return;
    }
    final Map<String, Object?> body;
    try {
      body = jsonDecode(s.record as String) as Map<String, Object?>;
    } on Object {
      developer.log('ignored an unreadable handoff note', name: 'lullaby.sync');
      return;
    }
    final baby = body['baby'], text = body['text'];
    if (baby is! String || text is! String) return;
    final at = body['at'];
    await db.into(db.handoffNotes).insertOnConflictUpdate(HandoffNotesCompanion.insert(
          id: id,
          babyId: baby,
          body: text,
          author: Value(body['by'] is String ? body['by'] as String : null),
          writtenAt: at is int
              ? DateTime.fromMillisecondsSinceEpoch(at * 1000)
              : DateTime.fromMillisecondsSinceEpoch(s.millis),
        ));
  }
}
