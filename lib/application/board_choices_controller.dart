import 'package:flutter/foundation.dart';

import '../domain/board_choices.dart';
import '../domain/communication_models.dart';
import '../services/board_choices_store.dart';

enum BoardEditOutcome {
  /// The change is saved and shown on the board.
  saved,

  /// The change was invalid; [BoardEditResult.problem] says why.
  rejected,

  /// The change could not be saved, so nothing changed.
  saveFailed,

  /// Another change was still saving, or saved choices were still loading.
  ignored,
}

@immutable
class BoardEditResult {
  const BoardEditResult(this.outcome, {this.problem});
  final BoardEditOutcome outcome;
  final BoardChoicesProblem? problem;
}

/// Owns the caregiver's board. The board shows the original choices until
/// saved ones are read, and when nothing usable is saved. Every change is
/// saved first and shown only once saved, so what the board shows is always
/// what will be there after a restart.
class BoardChoicesController extends ChangeNotifier {
  BoardChoicesController({this.store}) : _isLoaded = store == null;

  /// Null keeps the board in memory only.
  final BoardChoicesStore? store;

  BoardChoices _board = BoardChoices.original;
  late CommunicatorProfile _profile = _board.toProfile();
  bool _isLoaded;
  bool _loadFailed = false;
  bool _isSaving = false;
  bool _isDisposed = false;
  BoardEditResult? _lastResult;

  BoardChoices get board => _board;
  CommunicatorProfile get profile => _profile;

  /// False until saved choices have been read. Changes wait for it, so an
  /// early edit can never overwrite the caregiver's saved board.
  bool get isLoaded => _isLoaded;

  /// Saved choices existed but could not be read, so the original board is
  /// shown. The saved data is left alone until the caregiver changes the
  /// board.
  bool get loadFailed => _loadFailed;
  bool get isSaving => _isSaving;

  /// The result of the latest change, for the caregiver.
  BoardEditResult? get lastResult => _lastResult;

  Future<void> load() async {
    if (_isLoaded) return;
    BoardChoices? saved;
    var failed = false;
    try {
      saved = await store!.load();
      saved?.validate();
    } catch (_) {
      saved = null;
      failed = true;
    }
    if (_isDisposed || _isLoaded) return;
    _isLoaded = true;
    _loadFailed = failed;
    if (saved != null) _show(saved);
    _notify();
  }

  Future<BoardEditResult> add(ChoiceDraft draft) =>
      _change((board) => board.withAdded(draft));

  Future<BoardEditResult> edit(String id, ChoiceDraft draft) =>
      _change((board) => board.withEdited(id, draft));

  Future<BoardEditResult> setVisible(String id, {required bool visible}) =>
      _change((board) => board.withVisibility(id, visible: visible));

  Future<BoardEditResult> move(String id, int offset) =>
      _change((board) => board.withMoved(id, offset));

  Future<BoardEditResult> restoreOriginal() =>
      _change((_) => BoardChoices.original);

  /// Forgets the latest result, for example when the editor is opened.
  void clearResult() {
    if (_lastResult == null || _isSaving) return;
    _lastResult = null;
    _notify();
  }

  Future<BoardEditResult> _change(
    BoardChoices Function(BoardChoices board) change,
  ) async {
    if (_isDisposed || !_isLoaded || _isSaving) {
      return const BoardEditResult(BoardEditOutcome.ignored);
    }
    final BoardChoices next;
    try {
      next = change(_board);
    } on BoardChoicesException catch (error) {
      return _finish(
        BoardEditResult(BoardEditOutcome.rejected, problem: error.problem),
      );
    }
    _isSaving = true;
    _notify();
    try {
      await store?.save(next);
    } catch (_) {
      _isSaving = false;
      return _finish(const BoardEditResult(BoardEditOutcome.saveFailed));
    }
    _isSaving = false;
    _loadFailed = false;
    _show(next);
    return _finish(const BoardEditResult(BoardEditOutcome.saved));
  }

  /// Saves [board] without showing it, for an import that must save other
  /// settings too before anything changes. Throws when it cannot.
  Future<void> persist(BoardChoices board) async {
    if (_isDisposed || !_isLoaded || _isSaving) {
      throw StateError('The board cannot be saved right now.');
    }
    board.validate();
    _isSaving = true;
    try {
      await store?.save(board);
    } finally {
      _isSaving = false;
    }
  }

  /// Shows [board], already saved with [persist].
  void adopt(BoardChoices board) {
    if (_isDisposed) return;
    _loadFailed = false;
    _lastResult = null;
    _show(board);
    _notify();
  }

  void _show(BoardChoices board) {
    if (board == _board) return;
    _board = board;
    _profile = board.toProfile();
  }

  BoardEditResult _finish(BoardEditResult result) {
    _lastResult = result;
    _notify();
    return result;
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
