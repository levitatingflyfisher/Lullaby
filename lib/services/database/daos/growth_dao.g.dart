// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'growth_dao.dart';

// ignore_for_file: type=lint
mixin _$GrowthDaoMixin on DatabaseAccessor<AppDatabase> {
  $BabiesTable get babies => attachedDatabase.babies;
  $GrowthRecordsTable get growthRecords => attachedDatabase.growthRecords;
  GrowthDaoManager get managers => GrowthDaoManager(this);
}

class GrowthDaoManager {
  final _$GrowthDaoMixin _db;
  GrowthDaoManager(this._db);
  $$BabiesTableTableManager get babies =>
      $$BabiesTableTableManager(_db.attachedDatabase, _db.babies);
  $$GrowthRecordsTableTableManager get growthRecords =>
      $$GrowthRecordsTableTableManager(_db.attachedDatabase, _db.growthRecords);
}
