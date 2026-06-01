// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medicine_dao.dart';

// ignore_for_file: type=lint
mixin _$MedicineDaoMixin on DatabaseAccessor<AppDatabase> {
  $BabiesTable get babies => attachedDatabase.babies;
  $MedicineLogsTable get medicineLogs => attachedDatabase.medicineLogs;
  MedicineDaoManager get managers => MedicineDaoManager(this);
}

class MedicineDaoManager {
  final _$MedicineDaoMixin _db;
  MedicineDaoManager(this._db);
  $$BabiesTableTableManager get babies =>
      $$BabiesTableTableManager(_db.attachedDatabase, _db.babies);
  $$MedicineLogsTableTableManager get medicineLogs =>
      $$MedicineLogsTableTableManager(_db.attachedDatabase, _db.medicineLogs);
}
