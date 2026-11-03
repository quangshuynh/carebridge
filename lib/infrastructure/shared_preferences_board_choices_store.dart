import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/board_choices.dart';
import '../services/board_choices_store.dart';

/// Keeps the caregiver's board in the platform's app-private key-value
/// storage as one JSON value under one key, so a save replaces the whole
/// board or nothing: there is no partly written board to read back.
class SharedPreferencesBoardChoicesStore implements BoardChoicesStore {
  SharedPreferencesBoardChoicesStore({
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;
  final Future<SharedPreferences> Function() _preferences;

  static const boardKey = 'board.choices';

  /// The version of the saved value, separate from the backup file's.
  static const schemaVersion = 1;

  /// The saved value, kept as text in a fixed layout.
  static String encode(BoardChoices board) => jsonEncode(<String, Object>{
    'schemaVersion': schemaVersion,
    'choices': board.toJson(),
  });

  /// Throws [BoardChoicesException] unless [text] is a valid saved board.
  static BoardChoices decode(String text) {
    final Object? root;
    try {
      root = jsonDecode(text);
    } on FormatException {
      throw const BoardChoicesException(
        BoardChoicesProblem.invalidFormat,
        'saved board is not JSON',
      );
    }
    if (root is! Map<String, Object?> ||
        root['schemaVersion'] != schemaVersion ||
        root.length != 2) {
      throw const BoardChoicesException(
        BoardChoicesProblem.invalidFormat,
        'saved board has an unknown layout or version',
      );
    }
    return BoardChoices.fromJson(root['choices']);
  }

  @override
  Future<BoardChoices?> load() async {
    final preferences = await _preferences();
    final Object? saved = preferences.get(boardKey);
    if (saved == null) return null;
    if (saved is! String) {
      throw const BoardChoicesException(
        BoardChoicesProblem.invalidFormat,
        'saved board is not text',
      );
    }
    return decode(saved);
  }

  @override
  Future<void> save(BoardChoices board) async {
    board.validate();
    final stored = await _preferences();
    final saved = await stored.setString(boardKey, encode(board));
    if (!saved) throw StateError('The board was not saved.');
  }
}
