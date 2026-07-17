import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

import '../../../services/database/database.dart';

/// Serializes all Lullaby user data to/from a JSON [Uint8List] for encrypted
/// backup via sanctuary_backup_ui.
///
/// Works directly with [AppDatabase] to get full-table dumps — not filtered by
/// baby like the DAOs. Implements the package's [BackupSerializer] interface;
/// the JSON envelope and table logic are unchanged from Lullaby's shipped
/// format (SANCTUARY-BRIEF §4.W1: keep envelope/table logic identical).
class LullabyBackupSerializer
    implements BackupSerializer, PreviewableBackupSerializer {
  final AppDatabase _db;

  const LullabyBackupSerializer(this._db);

  static const String _appId = 'lullaby';

  /// Reads every user-data table and returns the JSON payload as bytes.
  ///
  /// The shape is Lullaby's SHIPPED one (`schemaVersion`/`exportedAt`/
  /// top-level `tables`) with two ADDITIVE keys the v2 retention spec
  /// needs (`app`, `createdAt`). Old shipped readers only look at
  /// schemaVersion + tables and ignore unknown keys, so backups made by
  /// this build still restore on pre-v2 Lullaby installs — the wire
  /// format is extended, never broken.
  @override
  Future<Uint8List> dumpAll() async {
    final allBabies = await _db.select(_db.babies).get();
    final allFeedings = await _db.select(_db.feedingLogs).get();
    final allSleeps = await _db.select(_db.sleepLogs).get();
    final allDiapers = await _db.select(_db.diaperLogs).get();
    final allGrowth = await _db.select(_db.growthRecords).get();
    final allMedicine = await _db.select(_db.medicineLogs).get();
    final allVaccines = await _db.select(_db.vaccineRecords).get();

    final stamp = DateTime.now().toUtc().toIso8601String();
    final payload = <String, dynamic>{
      'app': _appId,
      'schemaVersion': _db.schemaVersion,
      'exportedAt': stamp,
      'createdAt': stamp,
      'tables': {
        'babies': allBabies.map((r) => r.toJson()).toList(),
        'feedingLogs': allFeedings.map((r) => r.toJson()).toList(),
        'sleepLogs': allSleeps.map((r) => r.toJson()).toList(),
        'diaperLogs': allDiapers.map((r) => r.toJson()).toList(),
        'growthRecords': allGrowth.map((r) => r.toJson()).toList(),
        'medicineLogs': allMedicine.map((r) => r.toJson()).toList(),
        'vaccineRecords': allVaccines.map((r) => r.toJson()).toList(),
      },
    };

    return Uint8List.fromList(utf8.encode(jsonEncode(payload)));
  }

  /// The dry-run parse behind preview-before-restore and export
  /// read-back: validates like [restoreAll], never writes.
  @override
  Future<BackupManifest> describeBackup(Uint8List plaintext) async {
    _unwrap(plaintext);
    return BackupEnvelope.describe(plaintext);
  }

  /// Envelope validation via the shared helper. `requireAppKey: false`
  /// because every backup shipped Lullaby ever wrote has NO `app` key —
  /// an absent key is tolerated, a present-and-wrong one still rejects.
  /// (The AEAD context already binds the blob to Lullaby
  /// cryptographically; this is defense in depth.)
  UnwrappedBackup _unwrap(Uint8List data) => BackupEnvelope.unwrap(
        data,
        expectedAppId: _appId,
        currentSchemaVersion: _db.schemaVersion,
        requireAppKey: false,
      );

  /// Restores all user data from a JSON [Uint8List] previously created by
  /// [dumpAll].
  ///
  /// **This is destructive** — all existing data is wiped before inserting.
  ///
  /// Throws [BackupSchemaException] if the payload's schema version is newer
  /// than the current database version.
  /// Throws [FormatException] if the payload is not valid JSON or is missing
  /// required fields.
  @override
  Future<void> restoreAll(Uint8List data) async {
    final tables = _unwrap(data).payload['tables'];
    if (tables is! Map<String, dynamic>) {
      throw const FormatException('Missing tables in backup payload');
    }

    await _db.transaction(() async {
      // Wipe in reverse FK order to avoid constraint violations.
      await _db.delete(_db.vaccineRecords).go();
      await _db.delete(_db.medicineLogs).go();
      await _db.delete(_db.growthRecords).go();
      await _db.delete(_db.diaperLogs).go();
      await _db.delete(_db.sleepLogs).go();
      await _db.delete(_db.feedingLogs).go();
      await _db.delete(_db.babies).go();

      // Insert in FK order: babies first, then child tables.
      for (final row in _jsonList(tables, 'babies')) {
        await _db.into(_db.babies).insert(
              BabiesCompanion.insert(
                id: row['id'] as String,
                name: row['name'] as String,
                dateOfBirth: _dateTime(row['dateOfBirth']),
                gender: Value(row['gender'] as String?),
                photoPath: Value(row['photoPath'] as String?),
                isActive: Value(row['isActive'] as bool? ?? true),
                createdAt: _dateTime(row['createdAt']),
                modifiedAt: _dateTime(row['modifiedAt']),
              ),
            );
      }

      for (final row in _jsonList(tables, 'feedingLogs')) {
        await _db.into(_db.feedingLogs).insert(
              FeedingLogsCompanion.insert(
                id: row['id'] as String,
                babyId: row['babyId'] as String,
                type: row['type'] as String,
                startTime: _dateTime(row['startTime']),
                endTime: Value(_dateTimeOrNull(row['endTime'])),
                durationMinutes: Value(row['durationMinutes'] as int?),
                side: Value(row['side'] as String?),
                amountMl: Value((row['amountMl'] as num?)?.toDouble()),
                amountOz: Value((row['amountOz'] as num?)?.toDouble()),
                notes: Value(row['notes'] as String?),
                createdAt: _dateTime(row['createdAt']),
                modifiedAt: _dateTime(row['modifiedAt']),
              ),
            );
      }

      for (final row in _jsonList(tables, 'sleepLogs')) {
        await _db.into(_db.sleepLogs).insert(
              SleepLogsCompanion.insert(
                id: row['id'] as String,
                babyId: row['babyId'] as String,
                startTime: _dateTime(row['startTime']),
                endTime: Value(_dateTimeOrNull(row['endTime'])),
                durationMinutes: Value(row['durationMinutes'] as int?),
                type: row['type'] as String,
                location: Value(row['location'] as String?),
                notes: Value(row['notes'] as String?),
                createdAt: _dateTime(row['createdAt']),
                modifiedAt: _dateTime(row['modifiedAt']),
              ),
            );
      }

      for (final row in _jsonList(tables, 'diaperLogs')) {
        await _db.into(_db.diaperLogs).insert(
              DiaperLogsCompanion.insert(
                id: row['id'] as String,
                babyId: row['babyId'] as String,
                time: _dateTime(row['time']),
                type: row['type'] as String,
                color: Value(row['color'] as String?),
                notes: Value(row['notes'] as String?),
                createdAt: _dateTime(row['createdAt']),
                modifiedAt: _dateTime(row['modifiedAt']),
              ),
            );
      }

      for (final row in _jsonList(tables, 'growthRecords')) {
        await _db.into(_db.growthRecords).insert(
              GrowthRecordsCompanion.insert(
                id: row['id'] as String,
                babyId: row['babyId'] as String,
                measuredAt: _dateTime(row['measuredAt']),
                weightKg: Value((row['weightKg'] as num?)?.toDouble()),
                heightCm: Value((row['heightCm'] as num?)?.toDouble()),
                headCircumferenceCm:
                    Value((row['headCircumferenceCm'] as num?)?.toDouble()),
                notes: Value(row['notes'] as String?),
                createdAt: _dateTime(row['createdAt']),
                modifiedAt: _dateTime(row['modifiedAt']),
              ),
            );
      }

      for (final row in _jsonList(tables, 'medicineLogs')) {
        await _db.into(_db.medicineLogs).insert(
              MedicineLogsCompanion.insert(
                id: row['id'] as String,
                babyId: row['babyId'] as String,
                medicineName: row['medicineName'] as String,
                dosage: Value((row['dosage'] as num?)?.toDouble()),
                dosageUnit: Value(row['dosageUnit'] as String?),
                administeredAt: _dateTime(row['administeredAt']),
                notes: Value(row['notes'] as String?),
                createdAt: _dateTime(row['createdAt']),
                modifiedAt: _dateTime(row['modifiedAt']),
              ),
            );
      }

      for (final row in _jsonList(tables, 'vaccineRecords')) {
        await _db.into(_db.vaccineRecords).insert(
              VaccineRecordsCompanion.insert(
                id: row['id'] as String,
                babyId: row['babyId'] as String,
                vaccineName: row['vaccineName'] as String,
                doseNumber: Value(row['doseNumber'] as int?),
                scheduledDate: Value(_dateTimeOrNull(row['scheduledDate'])),
                administeredDate:
                    Value(_dateTimeOrNull(row['administeredDate'])),
                provider: Value(row['provider'] as String?),
                notes: Value(row['notes'] as String?),
                createdAt: _dateTime(row['createdAt']),
                modifiedAt: _dateTime(row['modifiedAt']),
              ),
            );
      }
    });
  }

  List<Map<String, dynamic>> _jsonList(
    Map<String, dynamic> tables,
    String key,
  ) {
    final list = tables[key] as List<dynamic>?;
    if (list == null) return const [];
    return list.cast<Map<String, dynamic>>();
  }

  /// Drift's default serializer encodes DateTime as Unix milliseconds (int).
  DateTime _dateTime(dynamic value) {
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.parse(value);
    throw FormatException('Cannot parse DateTime from: $value');
  }

  DateTime? _dateTimeOrNull(dynamic value) {
    if (value == null) return null;
    return _dateTime(value);
  }
}
