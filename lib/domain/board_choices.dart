import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show StringCharacters;

import 'choice_visual_catalog.dart';
import 'communication_models.dart';

/// Bounds that keep every board readable and every saved board small.
abstract final class BoardLimits {
  /// Choices on a board, shown and hidden together.
  static const maxChoices = 24;

  /// Characters as a person counts them (an emoji is one).
  static const maxLabelLength = 24;
  static const maxPhraseLength = 150;
  static const maxIdLength = 40;
}

/// Why a board, or a change to it, was refused.
enum BoardChoicesProblem {
  blankLabel,
  labelTooLong,
  blankPhrase,
  phraseTooLong,

  /// Text with control characters, or not trimmed and single-spaced.
  invalidText,
  unknownIcon,
  unknownColor,
  invalidId,
  duplicateId,
  tooMany,

  /// Every choice hidden, or no choices at all: the board would be empty.
  noneVisible,

  /// The choice to change is not on the board.
  unknownChoice,

  /// Saved or imported data that is not shaped like a board.
  invalidFormat,
}

class BoardChoicesException implements Exception {
  const BoardChoicesException(this.problem, this.detail);
  final BoardChoicesProblem problem;

  /// For developers and tests; never shown on the board.
  final String detail;

  @override
  String toString() => 'BoardChoicesException(${problem.name}): $detail';
}

/// Text rules shared by the caregiver's form, saved boards, and backups.
abstract final class BoardText {
  static final _whitespace = RegExp(r'\s+');
  static final _control = RegExp(r'[\u0000-\u001F\u007F-\u009F]');

  /// What typed text becomes when saved: trimmed, with every run of spaces
  /// or line breaks turned into one space.
  static String normalize(String text) =>
      text.trim().replaceAll(_whitespace, ' ');

  static int length(String text) => text.characters.length;

  static BoardChoicesProblem? labelProblem(String label) => _problem(
    label,
    BoardLimits.maxLabelLength,
    blank: BoardChoicesProblem.blankLabel,
    tooLong: BoardChoicesProblem.labelTooLong,
  );

  static BoardChoicesProblem? phraseProblem(String phrase) => _problem(
    phrase,
    BoardLimits.maxPhraseLength,
    blank: BoardChoicesProblem.blankPhrase,
    tooLong: BoardChoicesProblem.phraseTooLong,
  );

  /// Checks already-normalized text; anything else is invalid.
  static BoardChoicesProblem? _problem(
    String text,
    int maxLength, {
    required BoardChoicesProblem blank,
    required BoardChoicesProblem tooLong,
  }) {
    if (text.isEmpty) return blank;
    if (text != normalize(text) || _control.hasMatch(text)) {
      return BoardChoicesProblem.invalidText;
    }
    if (length(text) > maxLength) return tooLong;
    return null;
  }
}

/// One choice as a caregiver configures it. The id never changes, whatever
/// is edited or wherever the choice is moved.
@immutable
class BoardChoice {
  const BoardChoice({
    required this.id,
    required this.label,
    required this.spokenPhrase,
    required this.iconId,
    required this.colorId,
    this.isVisible = true,
  });
  final String id;
  final String label;
  final String spokenPhrase;
  final String iconId;
  final String colorId;
  final bool isVisible;

  ChoiceIconOption get iconOption => ChoiceVisualCatalog.iconById(iconId)!;
  ChoiceColorOption get colorOption => ChoiceVisualCatalog.colorById(colorId)!;

  BoardChoice copyWith({
    String? label,
    String? spokenPhrase,
    String? iconId,
    String? colorId,
    bool? isVisible,
  }) => BoardChoice(
    id: id,
    label: label ?? this.label,
    spokenPhrase: spokenPhrase ?? this.spokenPhrase,
    iconId: iconId ?? this.iconId,
    colorId: colorId ?? this.colorId,
    isVisible: isVisible ?? this.isVisible,
  );

  CommunicationChoice toCommunicationChoice(int order) => CommunicationChoice(
    id: id,
    label: label,
    spokenPhrase: spokenPhrase,
    visual: ChoiceVisual.icon(
      iconOption.icon,
      backgroundColor: colorOption.color,
    ),
    order: order,
    isEnabled: isVisible,
  );

  @override
  bool operator ==(Object other) =>
      other is BoardChoice &&
      other.id == id &&
      other.label == label &&
      other.spokenPhrase == spokenPhrase &&
      other.iconId == iconId &&
      other.colorId == colorId &&
      other.isVisible == isVisible;

  @override
  int get hashCode =>
      Object.hash(id, label, spokenPhrase, iconId, colorId, isVisible);
}

/// The words and picture a caregiver enters for a new or edited choice.
@immutable
class ChoiceDraft {
  const ChoiceDraft({
    required this.label,
    required this.spokenPhrase,
    required this.iconId,
    required this.colorId,
  });
  final String label;
  final String spokenPhrase;
  final String iconId;
  final String colorId;
}

/// The caregiver's board: its choices in the order they are shown. Every
/// operation returns a new, fully valid board or throws
/// [BoardChoicesException] and changes nothing.
@immutable
class BoardChoices {
  BoardChoices(Iterable<BoardChoice> choices)
    : choices = List.unmodifiable(choices);

  final List<BoardChoice> choices;

  static const _profileId = 'communicator';
  static const _categoryId = 'everyday';
  static const _customIdPrefix = 'custom-';
  static final _idPattern = RegExp(r'^[a-z0-9][a-z0-9-]*$');

  /// The six built-in choices every board starts with, matching
  /// `sampleCommunicator`.
  static final original = BoardChoices(const [
    BoardChoice(
      id: 'food',
      label: 'Food',
      spokenPhrase: 'I would like something to eat.',
      iconId: 'food',
      colorId: 'orange',
    ),
    BoardChoice(
      id: 'drink',
      label: 'Drink',
      spokenPhrase: 'I would like a drink.',
      iconId: 'drink',
      colorId: 'blue',
    ),
    BoardChoice(
      id: 'drive',
      label: 'Drive',
      spokenPhrase: 'I want to go for a drive.',
      iconId: 'car',
      colorId: 'green',
    ),
    BoardChoice(
      id: 'help',
      label: 'Help',
      spokenPhrase: 'I need help.',
      iconId: 'hand',
      colorId: 'red',
    ),
    BoardChoice(
      id: 'rest',
      label: 'Rest',
      spokenPhrase: 'I need to rest.',
      iconId: 'bed',
      colorId: 'purple',
    ),
    BoardChoice(
      id: 'finished',
      label: 'Finished',
      spokenPhrase: 'I am finished.',
      iconId: 'flag',
      colorId: 'gray',
    ),
  ]);

  int get visibleCount => choices.where((choice) => choice.isVisible).length;
  bool get isFull => choices.length >= BoardLimits.maxChoices;

  BoardChoice? byId(String id) {
    for (final choice in choices) {
      if (choice.id == id) return choice;
    }
    return null;
  }

  int indexOf(String id) => choices.indexWhere((choice) => choice.id == id);

  /// The board as the communicator sees it. Hidden choices stay in the
  /// profile, disabled, so their place is kept.
  CommunicatorProfile toProfile() => CommunicatorProfile(
    id: _profileId,
    displayName: 'My choices',
    categories: [
      CommunicationCategory(
        id: _categoryId,
        label: 'Everyday choices',
        order: 0,
        choices: [
          for (var i = 0; i < choices.length; i++)
            choices[i].toCommunicationChoice(i),
        ],
      ),
    ],
  );

  /// Adds a choice at the end with a new id no choice has used.
  BoardChoices withAdded(ChoiceDraft draft) {
    if (isFull) {
      throw BoardChoicesException(
        BoardChoicesProblem.tooMany,
        'a board holds at most ${BoardLimits.maxChoices} choices',
      );
    }
    return BoardChoices([
      ...choices,
      BoardChoice(
        id: _nextCustomId(),
        label: draft.label,
        spokenPhrase: draft.spokenPhrase,
        iconId: draft.iconId,
        colorId: draft.colorId,
      ),
    ])..validate();
  }

  /// Changes a choice's words and picture, keeping its id, place, and
  /// visibility.
  BoardChoices withEdited(String id, ChoiceDraft draft) => _replacing(
    id,
    (choice) => choice.copyWith(
      label: draft.label,
      spokenPhrase: draft.spokenPhrase,
      iconId: draft.iconId,
      colorId: draft.colorId,
    ),
  );

  BoardChoices withVisibility(String id, {required bool visible}) =>
      _replacing(id, (choice) => choice.copyWith(isVisible: visible));

  /// Moves a choice [offset] places later (negative is earlier), stopping
  /// at either end.
  BoardChoices withMoved(String id, int offset) {
    final from = _requireIndex(id);
    final to = (from + offset).clamp(0, choices.length - 1);
    if (to == from) return this;
    final reordered = [...choices];
    final moved = reordered.removeAt(from);
    reordered.insert(to, moved);
    return BoardChoices(reordered)..validate();
  }

  BoardChoices _replacing(String id, BoardChoice Function(BoardChoice) edit) {
    final index = _requireIndex(id);
    final edited = [...choices];
    edited[index] = edit(edited[index]);
    return BoardChoices(edited)..validate();
  }

  int _requireIndex(String id) {
    final index = indexOf(id);
    if (index < 0) {
      throw BoardChoicesException(
        BoardChoicesProblem.unknownChoice,
        'no choice "$id"',
      );
    }
    return index;
  }

  /// One more than the highest custom number in use, so an id is never
  /// given to a second choice on the same board.
  String _nextCustomId() {
    var highest = 0;
    for (final choice in choices) {
      if (!choice.id.startsWith(_customIdPrefix)) continue;
      final number = int.tryParse(choice.id.substring(_customIdPrefix.length));
      if (number != null && number > highest) highest = number;
    }
    return '$_customIdPrefix${highest + 1}';
  }

  /// Throws [BoardChoicesException] for the first rule the board breaks.
  void validate() {
    if (choices.length > BoardLimits.maxChoices) {
      throw BoardChoicesException(
        BoardChoicesProblem.tooMany,
        '${choices.length} choices exceeds ${BoardLimits.maxChoices}',
      );
    }
    final ids = <String>{};
    for (final choice in choices) {
      final id = choice.id;
      if (id.length > BoardLimits.maxIdLength || !_idPattern.hasMatch(id)) {
        throw BoardChoicesException(
          BoardChoicesProblem.invalidId,
          'invalid id "$id"',
        );
      }
      if (!ids.add(id)) {
        throw BoardChoicesException(
          BoardChoicesProblem.duplicateId,
          'id "$id" appears more than once',
        );
      }
      final problem =
          BoardText.labelProblem(choice.label) ??
          BoardText.phraseProblem(choice.spokenPhrase);
      if (problem != null) {
        throw BoardChoicesException(problem, 'choice "$id": ${problem.name}');
      }
      if (ChoiceVisualCatalog.iconById(choice.iconId) == null) {
        throw BoardChoicesException(
          BoardChoicesProblem.unknownIcon,
          'choice "$id": unknown icon "${choice.iconId}"',
        );
      }
      if (ChoiceVisualCatalog.colorById(choice.colorId) == null) {
        throw BoardChoicesException(
          BoardChoicesProblem.unknownColor,
          'choice "$id": unknown color "${choice.colorId}"',
        );
      }
    }
    if (visibleCount == 0) {
      throw const BoardChoicesException(
        BoardChoicesProblem.noneVisible,
        'at least one choice must be shown',
      );
    }
  }

  static const _choiceFields = {
    'id',
    'label',
    'phrase',
    'icon',
    'color',
    'visible',
  };

  /// The choices as JSON data in a fixed field order, in board order.
  List<Map<String, Object>> toJson() => [
    for (final choice in choices)
      <String, Object>{
        'id': choice.id,
        'label': choice.label,
        'phrase': choice.spokenPhrase,
        'icon': choice.iconId,
        'color': choice.colorId,
        'visible': choice.isVisible,
      },
  ];

  /// Reads the output of [toJson] strictly: every field required, no
  /// unknown fields, and a board that passes [validate]. Order is the
  /// position in the list, so it cannot be missing, repeated, or out of
  /// range.
  static BoardChoices fromJson(Object? json) {
    if (json is! List<Object?>) throw _format('"choices" must be a list');
    if (json.length > BoardLimits.maxChoices) {
      throw BoardChoicesException(
        BoardChoicesProblem.tooMany,
        '${json.length} choices exceeds ${BoardLimits.maxChoices}',
      );
    }
    final choices = <BoardChoice>[];
    for (final item in json) {
      if (item is! Map<String, Object?>) {
        throw _format('each choice must be an object');
      }
      for (final field in item.keys) {
        if (!_choiceFields.contains(field)) {
          throw _format('unknown choice field "$field"');
        }
      }
      String text(String field) => switch (item[field]) {
        final String value => value,
        _ => throw _format('choice "$field" must be text'),
      };
      final visible = item['visible'];
      if (visible is! bool) throw _format('"visible" must be true or false');
      choices.add(
        BoardChoice(
          id: text('id'),
          label: text('label'),
          spokenPhrase: text('phrase'),
          iconId: text('icon'),
          colorId: text('color'),
          isVisible: visible,
        ),
      );
    }
    return BoardChoices(choices)..validate();
  }

  static BoardChoicesException _format(String detail) =>
      BoardChoicesException(BoardChoicesProblem.invalidFormat, detail);

  @override
  bool operator ==(Object other) =>
      other is BoardChoices && listEquals(other.choices, choices);

  @override
  int get hashCode => Object.hashAll(choices);
}
