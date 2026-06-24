import 'package:drift/drift.dart';

class Babies extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  DateTimeColumn get dateOfBirth => dateTime()();
  TextColumn get gender => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class FeedingLogs extends Table {
  TextColumn get id => text()();
  TextColumn get babyId => text().references(Babies, #id)();
  TextColumn get type => text()(); // breast, bottle, solid
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get durationMinutes => integer().nullable()();
  TextColumn get side => text().nullable()(); // left, right, both
  RealColumn get amountMl => real().nullable()();
  RealColumn get amountOz => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class SleepLogs extends Table {
  TextColumn get id => text()();
  TextColumn get babyId => text().references(Babies, #id)();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get durationMinutes => integer().nullable()();
  TextColumn get type => text()(); // nap, night
  TextColumn get location => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class DiaperLogs extends Table {
  TextColumn get id => text()();
  TextColumn get babyId => text().references(Babies, #id)();
  DateTimeColumn get time => dateTime()();
  TextColumn get type => text()(); // wet, dirty, both, dry
  TextColumn get color => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class GrowthRecords extends Table {
  TextColumn get id => text()();
  TextColumn get babyId => text().references(Babies, #id)();
  DateTimeColumn get measuredAt => dateTime()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get heightCm => real().nullable()();
  RealColumn get headCircumferenceCm => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class MedicineLogs extends Table {
  TextColumn get id => text()();
  TextColumn get babyId => text().references(Babies, #id)();
  TextColumn get medicineName => text()();
  RealColumn get dosage => real().nullable()();
  TextColumn get dosageUnit => text().nullable()();
  DateTimeColumn get administeredAt => dateTime()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class VaccineRecords extends Table {
  TextColumn get id => text()();
  TextColumn get babyId => text().references(Babies, #id)();
  TextColumn get vaccineName => text()();
  IntColumn get doseNumber => integer().nullable()();
  DateTimeColumn get scheduledDate => dateTime().nullable()();
  DateTimeColumn get administeredDate => dateTime().nullable()();
  TextColumn get provider => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
