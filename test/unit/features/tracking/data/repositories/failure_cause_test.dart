import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/core/errors/result.dart';
import 'package:lullaby/features/sync/data/record_projection.dart';
import 'package:lullaby/features/sync/data/record_writer.dart';
import 'package:lullaby/features/tracking/data/repositories/diaper_repository_impl.dart';
import 'package:lullaby/features/tracking/domain/entities/diaper_log.dart';
import 'package:lullaby/services/database/database.dart';
import 'package:openhearth_design/openhearth_design.dart';

import '../../../../../test_setup.dart';

class _DiskFullWriter extends DirectRecordWriter {
  _DiskFullWriter(super.projection);
  @override
  Future<void> send(table, String id, Map<String, Object?> fields) =>
      throw const FileSystemException('write failed', '/data/lullaby.db',
          OSError('No space left on device', 28));
}

/// Repositories turned every exception into `DatabaseFailure(e.toString())`
/// and controllers wrapped that string, so the fleet's friendly message only
/// ever saw a String and every failure read as the generic sentence, with
/// no real exception behind Details (parked from the rollout, concern 4).
void main() {
  ensureSqlite3();

  test('a failed write keeps the real exception as the failure cause',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DiaperRepositoryImpl(
        db.diaperDao, _DiskFullWriter(RecordProjection(db)));
    final t = DateTime(2026, 9, 1, 8);
    final r = await repo.createDiaper(DiaperLogEntity(
      id: 'd1',
      babyId: 'b1',
      time: t,
      type: DiaperType.wet,
      createdAt: t,
      modifiedAt: t,
    ));
    expect(r, isA<Err<void>>());
    final f = (r as Err<void>).failure;
    expect(f.cause, isA<FileSystemException>());
    expect(f.stackTrace, isNotNull);
    expect(ohFriendlyErrorMessage(f.cause!), OhErrorMessages.file);
  });

  test('no repository flattens an exception to its string alone', () {
    final hits = <String>[];
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final src = f.readAsStringSync();
      for (final m in RegExp(r'DatabaseFailure\(e\.toString\(\)\)')
          .allMatches(src)) {
        hits.add('${f.path}@${m.start}');
      }
    }
    expect(hits, isEmpty);
  });

  test('controllers surface the cause, not the flattened message', () {
    final hits = <String>[];
    for (final f in Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('_controller.dart'))) {
      if (f.readAsStringSync().contains('AsyncError(f.message,')) {
        hits.add(f.path);
      }
    }
    expect(hits, isEmpty);
  });
}
