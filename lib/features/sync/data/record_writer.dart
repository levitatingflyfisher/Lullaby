import 'dart:convert';

import 'package:drift/drift.dart' show UpdateCompanion, Value, Variable;
import 'package:hearth_sync/hearth_sync.dart';
import 'package:uuid/uuid.dart';

import '../../../services/database/database.dart';

import 'lullaby_records.dart';
import 'record_projection.dart';

/// The one way repositories change a synced record (docs/adr/0007).
///
/// Values are plain Dart (String, int, double, DateTime, null), keyed by
/// column name. With sync off the record goes straight into Drift
/// ([DirectRecordWriter]); with sync on it goes through the kernel, and Drift
/// is filled from the kernel's changes ([HearthRecordWriter]).
abstract class RecordWriter {
  RecordWriter(this.projection);

  final RecordProjection projection;

  /// Create (or wholly set) [id] in [table] with every field in [fields].
  Future<void> put(RecordTable table, String id, Map<String, Object?> fields) =>
      send(table, id, encodeFields(table, fields));

  /// Change [id], sending only the fields that differ from what is stored. A
  /// field the person did not touch is never re-stamped, so a partner's
  /// concurrent edit to it still wins (field-level last-writer-wins). If only
  /// `modified_at` would change, nothing is sent.
  Future<void> update(
      RecordTable table, String id, Map<String, Object?> fields) async {
    final next = encodeFields(table, fields);
    final stored = await projection.readRow(table, id);
    if (stored == null) return send(table, id, next);
    final changed = {
      for (final e in next.entries)
        if (stored[e.key] != e.value) e.key: e.value,
    };
    if (changed.keys.every((k) => k == 'modified_at')) return;
    return send(table, id, changed);
  }

  /// Delete [id]. Deleting a baby hides its records with it.
  Future<void> delete(RecordTable table, String id);

  /// Undo a delete of [id]. [fields] is the row as it was, for the direct
  /// path; the kernel keeps the deleted row's fields itself.
  Future<void> restore(RecordTable table, String id, Map<String, Object?> fields);

  /// Leave a handoff note about [babyId] for whoever takes the next shift.
  Future<void> addHandoffNote({
    required String babyId,
    required String text,
    required DateTime at,
  });

  /// Write log-encoded [fields] of [id].
  Future<void> send(RecordTable table, String id, Map<String, Object?> fields);
}

/// Sync is off: records go straight into Drift, through the same projection
/// the kernel's changes use.
class DirectRecordWriter extends RecordWriter {
  DirectRecordWriter(super.projection, {this.author, this.inGap = false});

  /// The name notes are signed with (this phone's name, if it has one).
  final String? author;

  /// Sync is on but its log cannot be opened (the words are missing): deletes
  /// are remembered for the log ([RecordProjection.noteGapDelete]).
  final bool inGap;

  @override
  Future<void> send(RecordTable table, String id, Map<String, Object?> fields) =>
      projection.db.transaction(() async {
        await projection.upsert(table, id, fields);
        if (inGap) await projection.clearGapDelete(table, id);
        await projection.ensureActiveBaby();
      });

  @override
  Future<void> delete(RecordTable table, String id) =>
      projection.db.transaction(() async {
        await projection.hide(table, id);
        if (inGap) await projection.noteGapDelete(table, id);
        await projection.ensureActiveBaby();
      });

  @override
  Future<void> restore(
          RecordTable table, String id, Map<String, Object?> fields) =>
      put(table, id, fields);

  @override
  Future<void> addHandoffNote({
    required String babyId,
    required String text,
    required DateTime at,
  }) async {
    final db = projection.db;
    await db.into(db.handoffNotes).insert(HandoffNotesCompanion.insert(
          id: const Uuid().v4(),
          babyId: babyId,
          body: text,
          author: Value(author),
          writtenAt: DateTime.fromMillisecondsSinceEpoch(
              (at.millisecondsSinceEpoch ~/ 1000) * 1000),
        ));
  }
}

/// Sync is on: every write is an op in the household's log. Drift changes
/// only when the kernel's changes are stored (`DriftPersist.applyTables`
/// calls [RecordProjection.apply] in the same transaction).
class HearthRecordWriter extends RecordWriter {
  HearthRecordWriter(super.projection, this.hs, {required this.author});

  final HearthSync hs;

  /// This phone's name, signed into every handoff note.
  final String author;

  @override
  Future<void> send(RecordTable table, String id, Map<String, Object?> fields) =>
      hs.put(table.name, id, fields);

  @override
  Future<void> delete(RecordTable table, String id) => hs.delete(table.name, id);

  @override
  Future<void> restore(
          RecordTable table, String id, Map<String, Object?> fields) =>
      hs.restore(table.name, id);

  @override
  Future<void> addHandoffNote({
    required String babyId,
    required String text,
    required DateTime at,
  }) =>
      hs.append(
        handoffStream,
        jsonEncode({
          'baby': babyId,
          'text': text,
          'by': author,
          'at': at.millisecondsSinceEpoch ~/ 1000,
        }),
      );
}

/// The synced fields of a Drift companion, as plain Dart values keyed by
/// column name (the id and device-local columns are left out).
Map<String, Object?> companionFields(RecordTable table, UpdateCompanion<Object> c) => {
      for (final e in c.toColumns(false).entries)
        if (table.field(e.key) != null) e.key: (e.value as Variable).value,
    };
