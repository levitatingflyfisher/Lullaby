import 'package:drift/drift.dart';

import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../services/database/database.dart' hide HandoffNote;
import '../../sync/data/record_writer.dart';
import '../domain/handoff_note.dart';
import '../domain/handoff_repository.dart';

class HandoffRepositoryImpl implements HandoffRepository {
  HandoffRepositoryImpl(this._db, this._writer, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final RecordWriter _writer;
  final DateTime Function() _clock;

  @override
  Stream<List<HandoffNote>> watchRecent(String babyId, {int limit = 20}) =>
      (_db.select(_db.handoffNotes)
            ..where((n) => n.babyId.equals(babyId))
            ..orderBy([
              (n) => OrderingTerm.desc(n.writtenAt),
              (n) => OrderingTerm.desc(n.id),
            ])
            ..limit(limit))
          .watch()
          .map((rows) => [
                for (final r in rows)
                  HandoffNote(
                    id: r.id,
                    babyId: r.babyId,
                    text: r.body,
                    writtenAt: r.writtenAt,
                    author: r.author,
                  ),
              ]);

  @override
  Future<Result<void>> add(String babyId, String text) async {
    final t = text.trim();
    if (t.isEmpty) return const Err(ValidationFailure('Write something first.'));
    try {
      await _writer.addHandoffNote(babyId: babyId, text: t, at: _clock());
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(e.toString()));
    }
  }
}
