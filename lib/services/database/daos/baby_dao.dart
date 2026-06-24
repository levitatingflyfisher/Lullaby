import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'baby_dao.g.dart';

@DriftAccessor(tables: [Babies])
class BabyDao extends DatabaseAccessor<AppDatabase> with _$BabyDaoMixin {
  BabyDao(super.db);

  Future<List<Baby>> getAllBabies() => select(babies).get();

  Stream<List<Baby>> watchAllBabies() => select(babies).watch();

  Future<Baby?> getBabyById(String id) =>
      (select(babies)..where((b) => b.id.equals(id))).getSingleOrNull();

  Stream<Baby?> watchBabyById(String id) =>
      (select(babies)..where((b) => b.id.equals(id))).watchSingleOrNull();

  /// Emits the single active baby (or null). Ordered and limited so a transient
  /// multiple-active state can never push a `StateError` into the stream — the
  /// dashboard, timeline, charts and calendar all subscribe to this.
  Stream<Baby?> watchActiveBaby() => (select(babies)
        ..where((b) => b.isActive.equals(true))
        ..orderBy([(b) => OrderingTerm.desc(b.modifiedAt)])
        ..limit(1))
      .watch()
      .map((rows) => rows.isEmpty ? null : rows.first);

  Future<int> insertBaby(BabiesCompanion baby) => into(babies).insert(baby);

  /// Inserts [baby] as the sole active baby, demoting any currently-active baby
  /// in the same transaction so the single-active invariant always holds.
  Future<void> insertBabyAsActive(BabiesCompanion baby) =>
      transaction(() async {
        await (update(babies)..where((b) => b.isActive.equals(true)))
            .write(const BabiesCompanion(isActive: Value(false)));
        await into(babies).insert(baby.copyWith(isActive: const Value(true)));
      });

  Future<bool> updateBaby(BabiesCompanion baby) =>
      update(babies).replace(baby);

  /// Makes [id] the sole active baby in one transaction (demote all, then
  /// promote one) so the partial-unique-active invariant is never transiently
  /// violated.
  Future<void> setActiveBaby(String id) => transaction(() async {
        await (update(babies)..where((b) => b.isActive.equals(true)))
            .write(const BabiesCompanion(isActive: Value(false)));
        // Bump modifiedAt so watchActiveBaby's (modifiedAt DESC) tie-break
        // resolves to the just-selected baby if a stray active row ever exists.
        await (update(babies)..where((b) => b.id.equals(id))).write(
            BabiesCompanion(
                isActive: const Value(true),
                modifiedAt: Value(DateTime.now())));
      });

  /// Deletes a baby and all of its child rows in one transaction. Foreign keys
  /// are enforced but declared without `ON DELETE CASCADE`, so children are
  /// removed explicitly in FK-safe order.
  Future<void> deleteBaby(String id) => transaction(() async {
        final db = attachedDatabase;
        await (delete(db.vaccineRecords)..where((r) => r.babyId.equals(id)))
            .go();
        await (delete(db.medicineLogs)..where((r) => r.babyId.equals(id))).go();
        await (delete(db.growthRecords)..where((r) => r.babyId.equals(id))).go();
        await (delete(db.diaperLogs)..where((r) => r.babyId.equals(id))).go();
        await (delete(db.sleepLogs)..where((r) => r.babyId.equals(id))).go();
        await (delete(db.feedingLogs)..where((r) => r.babyId.equals(id))).go();
        await (delete(babies)..where((b) => b.id.equals(id))).go();

        // If the deleted baby was the active one, promote the most-recently
        // modified remaining baby so the app is never left with babies but none
        // active (which would render an empty "no baby" state).
        final stillActive = await (select(babies)
              ..where((b) => b.isActive.equals(true)))
            .get();
        if (stillActive.isEmpty) {
          final next = await (select(babies)
                ..orderBy([(b) => OrderingTerm.desc(b.modifiedAt)])
                ..limit(1))
              .getSingleOrNull();
          if (next != null) {
            await (update(babies)..where((b) => b.id.equals(next.id))).write(
                BabiesCompanion(
                    isActive: const Value(true),
                    modifiedAt: Value(DateTime.now())));
          }
        }
      });
}
