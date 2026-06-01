import 'package:drift/drift.dart';

import 'tables.dart';
import 'daos/baby_dao.dart';
import 'daos/feeding_dao.dart';
import 'daos/sleep_dao.dart';
import 'daos/diaper_dao.dart';
import 'daos/growth_dao.dart';
import 'daos/medicine_dao.dart';
import 'daos/vaccine_dao.dart';
import 'connection/connection.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Babies,
    FeedingLogs,
    SleepLogs,
    DiaperLogs,
    GrowthRecords,
    MedicineLogs,
    VaccineRecords,
  ],
  daos: [BabyDao, FeedingDao, SleepDao, DiaperDao, GrowthDao, MedicineDao, VaccineDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createIndices();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(growthRecords);
          }
          if (from < 3) {
            await m.createTable(medicineLogs);
            await m.createTable(vaccineRecords);
          }
          if (from < 4) {
            // Foreign keys were never enforced before v4, so child rows from
            // previously-deleted babies may be stranded — clean them up before
            // enforcement is enabled in beforeOpen.
            await _cleanOrphanedRows();
            // Collapse any pre-existing multiple-active-baby state down to one.
            await _normalizeActiveBaby();
            await _createIndices();
          }
        },
        beforeOpen: (details) async {
          // SQLite enforces foreign keys per-connection and defaults to OFF.
          // Drift disables them during migrations, so enabling here is safe.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Indices backing the hot per-baby, time-ordered queries every tracker runs.
  Future<void> _createIndices() async {
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_feeding_baby_start ON feeding_logs (baby_id, start_time)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sleep_baby_start ON sleep_logs (baby_id, start_time)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_diaper_baby_time ON diaper_logs (baby_id, time)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_growth_baby_measured ON growth_records (baby_id, measured_at)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_medicine_baby_administered ON medicine_logs (baby_id, administered_at)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_vaccine_baby_administered ON vaccine_records (baby_id, administered_date)');
  }

  Future<void> _cleanOrphanedRows() async {
    const childTables = [
      'feeding_logs',
      'sleep_logs',
      'diaper_logs',
      'growth_records',
      'medicine_logs',
      'vaccine_records',
    ];
    for (final table in childTables) {
      await customStatement(
          'DELETE FROM $table WHERE baby_id NOT IN (SELECT id FROM babies)');
    }
  }

  Future<void> _normalizeActiveBaby() async {
    // Keep the most recently modified active baby active; demote the rest.
    await customStatement(
      'UPDATE babies SET is_active = 0 WHERE is_active = 1 AND id NOT IN '
      '(SELECT id FROM babies WHERE is_active = 1 '
      'ORDER BY modified_at DESC LIMIT 1)',
    );
  }
}
