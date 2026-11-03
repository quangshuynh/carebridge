import 'dart:async';

import 'package:carebridge/domain/board_choices.dart';
import 'package:carebridge/infrastructure/shared_preferences_board_choices_store.dart';
import 'package:carebridge/services/board_choices_store.dart';

/// Stands in for on-device storage. It keeps the saved board as the same
/// text the real store writes, so one instance survives an app "restart"
/// in a test the way the platform's storage survives a real one.
class FakeBoardChoicesStore implements BoardChoicesStore {
  FakeBoardChoicesStore([BoardChoices? saved])
    : savedText = saved == null
          ? null
          : SharedPreferencesBoardChoicesStore.encode(saved);

  /// Exactly what is "on disk"; tests may corrupt it.
  String? savedText;
  Completer<void>? pendingLoad;
  Completer<void>? pendingSave;
  Object? loadError;
  Object? saveError;
  int saveCount = 0;

  BoardChoices? get saved => savedText == null
      ? null
      : SharedPreferencesBoardChoicesStore.decode(savedText!);

  @override
  Future<BoardChoices?> load() async {
    await pendingLoad?.future;
    if (loadError != null) throw loadError!;
    final text = savedText;
    return text == null
        ? null
        : SharedPreferencesBoardChoicesStore.decode(text);
  }

  @override
  Future<void> save(BoardChoices board) async {
    saveCount++;
    await pendingSave?.future;
    if (saveError != null) throw saveError!;
    savedText = SharedPreferencesBoardChoicesStore.encode(board);
  }
}
