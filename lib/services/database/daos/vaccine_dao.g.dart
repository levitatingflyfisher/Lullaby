// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vaccine_dao.dart';

// ignore_for_file: type=lint
mixin _$VaccineDaoMixin on DatabaseAccessor<AppDatabase> {
  $BabiesTable get babies => attachedDatabase.babies;
  $VaccineRecordsTable get vaccineRecords => attachedDatabase.vaccineRecords;
  VaccineDaoManager get managers => VaccineDaoManager(this);
}

class VaccineDaoManager {
  final _$VaccineDaoMixin _db;
  VaccineDaoManager(this._db);
  $$BabiesTableTableManager get babies =>
      $$BabiesTableTableManager(_db.attachedDatabase, _db.babies);
  $$VaccineRecordsTableTableManager get vaccineRecords =>
      $$VaccineRecordsTableTableManager(
        _db.attachedDatabase,
        _db.vaccineRecords,
      );
}
