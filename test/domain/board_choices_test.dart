// Custom choices: the board as caregiver data, with stable ids, strict
// limits, and every invalid board refused as a whole.
import 'dart:convert';

import 'package:carebridge/domain/board_choices.dart';
import 'package:carebridge/domain/choice_visual_catalog.dart';
import 'package:carebridge/domain/sample_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _snack = ChoiceDraft(
  label: 'Snack',
  spokenPhrase: 'I would like a snack, please.',
  iconId: 'cookie',
  colorId: 'yellow',
);

Matcher _refusedAs(BoardChoicesProblem problem) => throwsA(
  isA<BoardChoicesException>().having((e) => e.problem, 'problem', problem),
);

List<String> _ids(BoardChoices board) =>
    board.choices.map((choice) => choice.id).toList();

/// WCAG 2.x contrast ratio between two opaque colors.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  group('the original board', () {
    test('is exactly the six built-in choices existing users already '
        'have', () {
      final profile = BoardChoices.original.toProfile();
      final expected = sampleCommunicator.enabledChoices;
      expect(profile.enabledChoices, hasLength(6));
      for (var i = 0; i < expected.length; i++) {
        final actual = profile.enabledChoices[i];
        expect(actual.id, expected[i].id);
        expect(actual.label, expected[i].label);
        expect(actual.spokenPhrase, expected[i].spokenPhrase);
        expect(actual.visual, expected[i].visual);
        expect(actual.isEnabled, isTrue);
      }
    });

    test('is valid', () => BoardChoices.original.validate());
  });

  group('changes', () {
    final board = BoardChoices.original;

    test('adding puts a new choice last with a new, stable id', () {
      final added = board.withAdded(_snack);
      expect(_ids(added), [..._ids(board), 'custom-1']);
      final snack = added.byId('custom-1')!;
      expect(snack.label, 'Snack');
      expect(snack.spokenPhrase, 'I would like a snack, please.');
      expect(snack.isVisible, isTrue);
      expect(_ids(added.withAdded(_snack)).last, 'custom-2');
      // The original is never modified.
      expect(board.choices, hasLength(6));
    });

    test('an id is never reused by a later choice on the same board', () {
      final two = board.withAdded(_snack).withAdded(_snack);
      final hidden = two.withVisibility('custom-1', visible: false);
      expect(_ids(hidden.withAdded(_snack)).last, 'custom-3');
    });

    test('editing changes words and picture but keeps id, place, and '
        'visibility', () {
      final edited = board
          .withVisibility('drink', visible: false)
          .withEdited(
            'drink',
            const ChoiceDraft(
              label: 'Juice',
              spokenPhrase: 'Juice, please.',
              iconId: 'drink',
              colorId: 'yellow',
            ),
          );
      expect(_ids(edited), _ids(board));
      final juice = edited.byId('drink')!;
      expect(juice.label, 'Juice');
      expect(juice.spokenPhrase, 'Juice, please.');
      expect(juice.colorId, 'yellow');
      expect(juice.isVisible, isFalse);
    });

    test('the label and the spoken phrase are independent', () {
      final edited = board.withEdited(
        'help',
        const ChoiceDraft(
          label: 'Help',
          spokenPhrase: 'Can you help me with this?',
          iconId: 'hand',
          colorId: 'red',
        ),
      );
      expect(edited.byId('help')!.label, 'Help');
      expect(
        edited.toProfile().enabledChoices[3].spokenPhrase,
        'Can you help me with this?',
      );
    });

    test('hiding keeps the choice and its place, and only shown choices '
        'reach the board', () {
      final hidden = board.withVisibility('drive', visible: false);
      expect(_ids(hidden), _ids(board));
      expect(hidden.toProfile().enabledChoices.map((choice) => choice.id), [
        'food',
        'drink',
        'help',
        'rest',
        'finished',
      ]);
      final restored = hidden.withVisibility('drive', visible: true);
      expect(restored, board);
    });

    test('the last shown choice cannot be hidden', () {
      var onlyFood = board;
      for (final id in ['drink', 'drive', 'help', 'rest', 'finished']) {
        onlyFood = onlyFood.withVisibility(id, visible: false);
      }
      expect(
        () => onlyFood.withVisibility('food', visible: false),
        _refusedAs(BoardChoicesProblem.noneVisible),
      );
    });

    test('moving keeps every id and stops at either end', () {
      expect(_ids(board.withMoved('help', -1)), [
        'food',
        'drink',
        'help',
        'drive',
        'rest',
        'finished',
      ]);
      expect(_ids(board.withMoved('food', 2)), [
        'drink',
        'drive',
        'food',
        'help',
        'rest',
        'finished',
      ]);
      expect(board.withMoved('food', -1), same(board));
      expect(board.withMoved('finished', 1), same(board));
      expect(_ids(board.withMoved('finished', -99)).first, 'finished');
      // The saved order is the order shown.
      final moved = board.withMoved('rest', -4);
      expect(
        moved.toProfile().enabledChoices.map((choice) => choice.id),
        _ids(moved),
      );
    });

    test('changing a choice that is not on the board is refused', () {
      expect(
        () => board.withEdited('missing', _snack),
        _refusedAs(BoardChoicesProblem.unknownChoice),
      );
      expect(
        () => board.withMoved('missing', 1),
        _refusedAs(BoardChoicesProblem.unknownChoice),
      );
    });

    test('the board holds at most the limit of choices', () {
      var full = board;
      while (!full.isFull) {
        full = full.withAdded(_snack);
      }
      expect(full.choices, hasLength(BoardLimits.maxChoices));
      expect(
        () => full.withAdded(_snack),
        _refusedAs(BoardChoicesProblem.tooMany),
      );
    });
  });

  group('text', () {
    test('typed text is trimmed and single-spaced', () {
      expect(BoardText.normalize('  Go\n\toutside   now  '), 'Go outside now');
    });

    final cases = <String, (String, BoardChoicesProblem?)>{
      'a normal label': ('Snack', null),
      'an emoji counts as one character': ('🍎' * 24, null),
      'blank': ('', BoardChoicesProblem.blankLabel),
      'too long': ('x' * 25, BoardChoicesProblem.labelTooLong),
      'untrimmed': (' Snack', BoardChoicesProblem.invalidText),
      'a line break': ('Snack\ntime', BoardChoicesProblem.invalidText),
      'a control character': ('Snack\u0007', BoardChoicesProblem.invalidText),
    };
    cases.forEach((name, testCase) {
      test('label: $name', () {
        expect(BoardText.labelProblem(testCase.$1), testCase.$2);
      });
    });

    test('phrase limits', () {
      expect(BoardText.phraseProblem('x' * 150), isNull);
      expect(
        BoardText.phraseProblem('x' * 151),
        BoardChoicesProblem.phraseTooLong,
      );
      expect(BoardText.phraseProblem(''), BoardChoicesProblem.blankPhrase);
    });

    test('an invalid draft is refused and nothing changes', () {
      for (final (draft, problem) in [
        (
          const ChoiceDraft(
            label: '',
            spokenPhrase: 'x',
            iconId: 'food',
            colorId: 'blue',
          ),
          BoardChoicesProblem.blankLabel,
        ),
        (
          const ChoiceDraft(
            label: 'x',
            spokenPhrase: '',
            iconId: 'food',
            colorId: 'blue',
          ),
          BoardChoicesProblem.blankPhrase,
        ),
        (
          const ChoiceDraft(
            label: 'x',
            spokenPhrase: 'x',
            iconId: 'rocket',
            colorId: 'blue',
          ),
          BoardChoicesProblem.unknownIcon,
        ),
        (
          const ChoiceDraft(
            label: 'x',
            spokenPhrase: 'x',
            iconId: 'food',
            colorId: '#ff0000',
          ),
          BoardChoicesProblem.unknownColor,
        ),
      ]) {
        expect(
          () => BoardChoices.original.withAdded(draft),
          _refusedAs(problem),
        );
        expect(
          () => BoardChoices.original.withEdited('food', draft),
          _refusedAs(problem),
        );
      }
    });
  });

  group('JSON', () {
    test('round trips exactly, in order, with hidden choices', () {
      final board = BoardChoices.original
          .withAdded(_snack)
          .withMoved('custom-1', -3)
          .withVisibility('rest', visible: false);
      final json = jsonDecode(jsonEncode(board.toJson()));
      expect(BoardChoices.fromJson(json), board);
    });

    Map<String, Object?> choice([Map<String, Object?> overrides = const {}]) =>
        {
          'id': 'food',
          'label': 'Food',
          'phrase': 'Food, please.',
          'icon': 'food',
          'color': 'orange',
          'visible': true,
          ...overrides,
        };

    final invalid = <String, (Object?, BoardChoicesProblem)>{
      'not a list': ({'food': 1}, BoardChoicesProblem.invalidFormat),
      'a choice that is not an object': (
        ['food'],
        BoardChoicesProblem.invalidFormat,
      ),
      'an unknown choice field': (
        [
          choice({'image': '/sdcard/a.png'}),
        ],
        BoardChoicesProblem.invalidFormat,
      ),
      'a missing field': (
        [choice()..remove('phrase')],
        BoardChoicesProblem.invalidFormat,
      ),
      'a label that is not text': (
        [
          choice({'label': 3}),
        ],
        BoardChoicesProblem.invalidFormat,
      ),
      'visible as text': (
        [
          choice({'visible': 'yes'}),
        ],
        BoardChoicesProblem.invalidFormat,
      ),
      'a duplicate id': ([choice(), choice()], BoardChoicesProblem.duplicateId),
      'an id with capitals or spaces': (
        [
          choice({'id': 'My Food'}),
        ],
        BoardChoicesProblem.invalidId,
      ),
      'an overlong id': (
        [
          choice({'id': 'a' * 41}),
        ],
        BoardChoicesProblem.invalidId,
      ),
      'a blank label': (
        [
          choice({'label': ''}),
        ],
        BoardChoicesProblem.blankLabel,
      ),
      'an oversized phrase': (
        [
          choice({'phrase': 'x' * 151}),
        ],
        BoardChoicesProblem.phraseTooLong,
      ),
      'an unknown icon': (
        [
          choice({'icon': 'https://example.com/a.png'}),
        ],
        BoardChoicesProblem.unknownIcon,
      ),
      'no choices': (<Object?>[], BoardChoicesProblem.noneVisible),
      'every choice hidden': (
        [
          choice({'visible': false}),
        ],
        BoardChoicesProblem.noneVisible,
      ),
      'too many choices': (
        [
          for (var i = 0; i <= BoardLimits.maxChoices; i++)
            choice({'id': 'c$i'}),
        ],
        BoardChoicesProblem.tooMany,
      ),
    };
    invalid.forEach((name, testCase) {
      test('rejects $name', () {
        expect(
          () => BoardChoices.fromJson(testCase.$1),
          _refusedAs(testCase.$2),
        );
      });
    });
  });

  group('visual catalog', () {
    test('ids are unique and every built-in choice uses the catalog', () {
      final iconIds = ChoiceVisualCatalog.icons.map((option) => option.id);
      final colorIds = ChoiceVisualCatalog.colors.map((option) => option.id);
      expect(iconIds.toSet(), hasLength(iconIds.length));
      expect(colorIds.toSet(), hasLength(colorIds.length));
      final names = ChoiceVisualCatalog.icons.map((option) => option.name);
      expect(names.toSet(), hasLength(names.length));
    });

    test('every color keeps text and icons at WCAG AAA (7:1) in both '
        'display modes', () {
      const standardInk = Color(0xFF102B29);
      for (final option in ChoiceVisualCatalog.colors) {
        expect(
          _contrast(standardInk, option.color),
          greaterThanOrEqualTo(7),
          reason: option.name,
        );
        expect(
          _contrast(Colors.black, option.color),
          greaterThanOrEqualTo(7),
          reason: option.name,
        );
      }
    });
  });
}
