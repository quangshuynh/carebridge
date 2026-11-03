import 'package:carebridge/domain/board_choices.dart';
import 'package:carebridge/infrastructure/shared_preferences_board_choices_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = SharedPreferencesBoardChoicesStore.boardKey;

final _custom = BoardChoices.original
    .withAdded(
      const ChoiceDraft(
        label: 'Swim',
        spokenPhrase: 'I want to go swimming.',
        iconId: 'walk',
        colorId: 'teal',
      ),
    )
    .withMoved('custom-1', -6)
    .withVisibility('drive', visible: false);

Matcher get _unreadable => throwsA(isA<BoardChoicesException>());

void main() {
  test('nothing saved reads as null, so existing users keep the original '
      'board', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await SharedPreferencesBoardChoicesStore().load(), isNull);
  });

  test('a saved board is read back exactly by a new store instance, as '
      'after a restart', () async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesBoardChoicesStore().save(_custom);
    expect(await SharedPreferencesBoardChoicesStore().load(), _custom);
  });

  test('the whole board is one value under one key', () async {
    SharedPreferences.setMockInitialValues({'display.highContrast': true});
    await SharedPreferencesBoardChoicesStore().save(_custom);
    final raw = await SharedPreferences.getInstance();
    expect(raw.getKeys(), {'display.highContrast', _key});
    expect(raw.getBool('display.highContrast'), isTrue);
  });

  test('saving the same board always writes the same text', () {
    expect(
      SharedPreferencesBoardChoicesStore.encode(_custom),
      SharedPreferencesBoardChoicesStore.encode(_custom),
    );
  });

  test('an invalid board is never written', () async {
    SharedPreferences.setMockInitialValues({});
    final invalid = BoardChoices([
      BoardChoices.original.choices.first,
      BoardChoices.original.choices.first,
    ]);
    await expectLater(
      SharedPreferencesBoardChoicesStore().save(invalid),
      throwsA(isA<BoardChoicesException>()),
    );
    final raw = await SharedPreferences.getInstance();
    expect(raw.containsKey(_key), isFalse);
  });

  test('a storage failure is reported, not swallowed', () async {
    final store = SharedPreferencesBoardChoicesStore(
      preferences: () async => throw StateError('storage unavailable'),
    );
    await expectLater(store.save(_custom), throwsStateError);
  });

  final corrupted = <String, Object>{
    'truncated JSON': '{"schemaVersion":1,"choices":[{"id":"fo',
    'not JSON': 'hello',
    'an unknown version': '{"schemaVersion":2,"choices":[]}',
    'an extra field': '{"schemaVersion":1,"choices":[],"x":1}',
    'duplicate ids':
        '{"schemaVersion":1,"choices":['
        '{"id":"a","label":"A","phrase":"A","icon":"food","color":"blue",'
        '"visible":true},'
        '{"id":"a","label":"B","phrase":"B","icon":"food","color":"blue",'
        '"visible":true}]}',
    'a value of the wrong type': 42,
  };
  corrupted.forEach((name, value) {
    test('corrupted storage ($name) is reported as unreadable', () async {
      SharedPreferences.setMockInitialValues({_key: value});
      await expectLater(
        SharedPreferencesBoardChoicesStore().load(),
        _unreadable,
      );
    });
  });
}
