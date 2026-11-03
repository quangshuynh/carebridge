import '../domain/board_choices.dart';

abstract interface class BoardChoicesStore {
  /// The saved board, or null when the caregiver has never changed it.
  /// Throws when saved data exists but cannot be read or is invalid.
  Future<BoardChoices?> load();

  /// Saves the whole board in one write, replacing what was saved.
  Future<void> save(BoardChoices board);
}
