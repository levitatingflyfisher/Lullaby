// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diaper_dao.dart';

// ignore_for_file: type=lint
mixin _$DiaperDaoMixin on DatabaseAccessor<AppDatabase> {
  $BabiesTable get babies => attachedDatabase.babies;
  $DiaperLogsTable get diaperLogs => attachedDatabase.diaperLogs;
  DiaperDaoManager get managers => DiaperDaoManager(this);
}

class DiaperDaoManager {
  final _$DiaperDaoMixin _db;
  DiaperDaoManager(this._db);
  $$BabiesTableTableManager get babies =>
      $$BabiesTableTableManager(_db.attachedDatabase, _db.babies);
  $$DiaperLogsTableTableManager get diaperLogs =>
      $$DiaperLogsTableTableManager(_db.attachedDatabase, _db.diaperLogs);
}
