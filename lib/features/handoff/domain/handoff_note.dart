import 'package:equatable/equatable.dart';

/// A line left for whoever takes the next shift ("last feed 3:10, left side").
/// Append-only: a correction is a new note (ADR-0007).
class HandoffNote extends Equatable {
  const HandoffNote({
    required this.id,
    required this.babyId,
    required this.text,
    required this.writtenAt,
    this.author,
  });

  final String id;
  final String babyId;
  final String text;
  final DateTime writtenAt;

  /// The name of the phone that wrote it, when sync is on.
  final String? author;

  @override
  List<Object?> get props => [id, babyId, text, writtenAt, author];
}
