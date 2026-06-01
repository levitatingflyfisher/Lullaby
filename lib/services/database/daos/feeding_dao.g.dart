// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feeding_dao.dart';

// ignore_for_file: type=lint
mixin _$FeedingDaoMixin on DatabaseAccessor<AppDatabase> {
  $BabiesTable get babies => attachedDatabase.babies;
  $FeedingLogsTable get feedingLogs => attachedDatabase.feedingLogs;
  FeedingDaoManager get managers => FeedingDaoManager(this);
}

class FeedingDaoManager {
  final _$FeedingDaoMixin _db;
  FeedingDaoManager(this._db);
  $$BabiesTableTableManager get babies =>
      $$BabiesTableTableManager(_db.attachedDatabase, _db.babies);
  $$FeedingLogsTableTableManager get feedingLogs =>
      $$FeedingLogsTableTableManager(_db.attachedDatabase, _db.feedingLogs);
}
