// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'baby_dao.dart';

// ignore_for_file: type=lint
mixin _$BabyDaoMixin on DatabaseAccessor<AppDatabase> {
  $BabiesTable get babies => attachedDatabase.babies;
  BabyDaoManager get managers => BabyDaoManager(this);
}

class BabyDaoManager {
  final _$BabyDaoMixin _db;
  BabyDaoManager(this._db);
  $$BabiesTableTableManager get babies =>
      $$BabiesTableTableManager(_db.attachedDatabase, _db.babies);
}
