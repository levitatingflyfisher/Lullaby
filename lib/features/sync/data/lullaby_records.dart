import 'package:drift/drift.dart';
import 'package:hearth_sync/hearth_sync.dart';

/// What Lullaby keeps in the household's sync log, and how each value is
/// written there (docs/adr/0007-household-sync.md). Every name and type here
/// is for good: never rename, retype or remove one (hearthSync ADR 0009). A
/// new field is a new name.
///
/// Field names are the Drift column names. Values in the log are text, int
/// or null only:
/// - [FieldKind.date] is an int of Unix seconds, what Drift itself stores, so
///   a stored row and its log entry always compare equal;
/// - [FieldKind.real] is text, Dart's shortest round-trip form of the double
///   (the kernel has no float type).
enum FieldKind { text, int, real, date }

/// One synced column.
class RecordField {
  const RecordField(this.name, this.kind);

  final String name;
  final FieldKind kind;
}

/// One synced table. Every record table but `babies` names its baby as its
/// container, so deleting a baby hides its records everywhere.
class RecordTable {
  const RecordTable(this.name, this.fields, {this.contained = true});

  final String name;
  final List<RecordField> fields;

  /// Whether `baby_id` holds this row's container (a row of `babies`).
  final bool contained;

  RecordField? field(String name) {
    for (final f in fields) {
      if (f.name == name) return f;
    }
    return null;
  }
}

const _created = RecordField('created_at', FieldKind.date);
const _modified = RecordField('modified_at', FieldKind.date);
const _baby = RecordField('baby_id', FieldKind.text);
const _notes = RecordField('notes', FieldKind.text);

const babiesSpec = RecordTable(
  'babies',
  [
    RecordField('name', FieldKind.text),
    RecordField('date_of_birth', FieldKind.date),
    RecordField('gender', FieldKind.text),
    _created,
    _modified,
  ],
  contained: false,
);

const feedingSpec = RecordTable('feeding_logs', [
  _baby,
  RecordField('type', FieldKind.text),
  RecordField('start_time', FieldKind.date),
  RecordField('end_time', FieldKind.date),
  RecordField('duration_minutes', FieldKind.int),
  RecordField('side', FieldKind.text),
  RecordField('amount_ml', FieldKind.real),
  RecordField('amount_oz', FieldKind.real),
  _notes,
  _created,
  _modified,
]);

const sleepSpec = RecordTable('sleep_logs', [
  _baby,
  RecordField('start_time', FieldKind.date),
  RecordField('end_time', FieldKind.date),
  RecordField('duration_minutes', FieldKind.int),
  RecordField('type', FieldKind.text),
  RecordField('location', FieldKind.text),
  _notes,
  _created,
  _modified,
]);

const diaperSpec = RecordTable('diaper_logs', [
  _baby,
  RecordField('time', FieldKind.date),
  RecordField('type', FieldKind.text),
  RecordField('color', FieldKind.text),
  _notes,
  _created,
  _modified,
]);

const growthSpec = RecordTable('growth_records', [
  _baby,
  RecordField('measured_at', FieldKind.date),
  RecordField('weight_kg', FieldKind.real),
  RecordField('height_cm', FieldKind.real),
  RecordField('head_circumference_cm', FieldKind.real),
  _notes,
  _created,
  _modified,
]);

const medicineSpec = RecordTable('medicine_logs', [
  _baby,
  RecordField('medicine_name', FieldKind.text),
  RecordField('dosage', FieldKind.real),
  RecordField('dosage_unit', FieldKind.text),
  RecordField('administered_at', FieldKind.date),
  _notes,
  _created,
  _modified,
]);

const vaccineSpec = RecordTable('vaccine_records', [
  _baby,
  RecordField('vaccine_name', FieldKind.text),
  RecordField('dose_number', FieldKind.int),
  RecordField('scheduled_date', FieldKind.date),
  RecordField('administered_date', FieldKind.date),
  RecordField('provider', FieldKind.text),
  _notes,
  _created,
  _modified,
]);

/// Every synced table, `babies` first (parents before children).
const recordTables = [
  babiesSpec,
  feedingSpec,
  sleepSpec,
  diaperSpec,
  growthSpec,
  medicineSpec,
  vaccineSpec,
];

/// The record tables that hang off a baby.
final childRecordTables = [
  for (final t in recordTables)
    if (t.contained) t,
];

RecordTable? recordTable(String name) {
  for (final t in recordTables) {
    if (t.name == name) return t;
  }
  return null;
}

/// The append-only stream of handoff notes: text records holding JSON
/// `{baby, text, by, at}` (`at` in Unix seconds).
const handoffStream = 'handoff_notes';

/// The kernel's app domain for Lullaby.
const lullabySyncApp = 'lullaby';

/// The schema this app version registers.
final lullabySyncSchema = SyncSchema([
  for (final t in recordTables)
    SyncTable(
      t.name,
      [
        for (final f in t.fields)
          SyncField(
            f.name,
            f.kind == FieldKind.int || f.kind == FieldKind.date
                ? SyncType.int
                : SyncType.text,
          ),
      ],
      containerField: t.contained ? 'baby_id' : null,
      containerTable: t.contained ? 'babies' : null,
    ),
  const SyncStream(handoffStream, SyncType.text),
], horizon: const Duration(days: 90));

/// A Dart value (String, int, double, DateTime or null) as the log holds it.
Object? encodeValue(FieldKind kind, Object? v) {
  if (v == null) return null;
  return switch (kind) {
    FieldKind.text => v as String,
    FieldKind.int => v as int,
    FieldKind.real => (v as num).toDouble().toString(),
    FieldKind.date => (v as DateTime).millisecondsSinceEpoch ~/ 1000,
  };
}

/// A value from the log as the Dart type Drift stores for [kind].
Object? decodeValue(FieldKind kind, Object? v) {
  if (v == null) return null;
  return switch (kind) {
    FieldKind.text => v as String,
    FieldKind.int => v as int,
    FieldKind.real => double.parse(v as String),
    FieldKind.date => DateTime.fromMillisecondsSinceEpoch((v as int) * 1000),
  };
}

/// Every field of [table] in [fields] (Dart values), encoded for the log.
/// Unknown names are an error: they would be held, never shown.
Map<String, Object?> encodeFields(RecordTable table, Map<String, Object?> fields) {
  return {
    for (final e in fields.entries)
      e.key: encodeValue(
        (table.field(e.key) ??
                (throw ArgumentError.value(e.key, 'field', 'not in ${table.name}')))
            .kind,
        e.value,
      ),
  };
}

/// A log value as a Drift [Variable] for [kind].
Variable<Object> variableFor(FieldKind kind, Object? logValue) {
  final v = decodeValue(kind, logValue);
  return switch (kind) {
    FieldKind.text => Variable<String>(v as String?),
    FieldKind.int => Variable<int>(v as int?),
    FieldKind.real => Variable<double>(v as double?),
    FieldKind.date => Variable<DateTime>(v as DateTime?),
  };
}

/// Reads [field] of a Drift result row back into its log encoding.
Object? readLogValue(QueryRow row, RecordField field) {
  return switch (field.kind) {
    FieldKind.text => row.readNullable<String>(field.name),
    FieldKind.int => row.readNullable<int>(field.name),
    FieldKind.real => encodeValue(FieldKind.real, row.readNullable<double>(field.name)),
    FieldKind.date => encodeValue(FieldKind.date, row.readNullable<DateTime>(field.name)),
  };
}
