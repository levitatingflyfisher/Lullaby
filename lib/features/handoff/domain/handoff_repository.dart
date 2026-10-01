import '../../../core/errors/result.dart';
import 'handoff_note.dart';

abstract class HandoffRepository {
  /// The newest notes about [babyId] first, at most [limit].
  Stream<List<HandoffNote>> watchRecent(String babyId, {int limit = 20});

  /// Leave [text] for the next shift.
  Future<Result<void>> add(String babyId, String text);
}
