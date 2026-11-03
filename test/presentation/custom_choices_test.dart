// Custom choices in settings: caregivers add, change, hide, reorder, and
// restore choices away from the board, which stays one tap per choice.
import 'dart:async';

import 'package:carebridge/domain/board_choices.dart';
import 'package:carebridge/presentation/care_bridge_theme.dart';
import 'package:carebridge/presentation/choices/choice_detail_screen.dart';
import 'package:carebridge/presentation/choices/choice_form_screen.dart';
import 'package:carebridge/presentation/choices/choices_editor_screen.dart';
import 'package:carebridge/presentation/widgets/communication_choice_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/board_harness.dart';
import '../support/fake_board_choices_store.dart';
import '../support/fake_display_preferences_store.dart';
import '../support/fake_speech_service.dart';
import '../support/sdk_fonts.dart';

const _editorList = Key('choices-editor-list');
const _detailList = Key('choice-detail-list');
const _formList = Key('choice-form-list');

Finder _inList(Key list, Finder finder) =>
    find.descendant(of: find.byKey(list), matching: finder);

/// Scrolls [list], down and then up, until [finder] is built and fully
/// visible.
Future<void> _reveal(WidgetTester tester, Key list, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final scrollable = _inList(list, find.byType(Scrollable)).first;
    try {
      await tester.scrollUntilVisible(finder, 120, scrollable: scrollable);
    } on StateError {
      await tester.scrollUntilVisible(finder, -120, scrollable: scrollable);
    }
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

/// Scrolls [list] until [key] is fully visible, then taps it.
Future<void> _tapIn(WidgetTester tester, Key list, Key key) async {
  await _reveal(tester, list, find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

/// Scrolls [list] back up until [finder] is built.
Future<void> _scrollBackTo(WidgetTester tester, Key list, Finder finder) =>
    tester.scrollUntilVisible(
      finder,
      -120,
      scrollable: _inList(list, find.byType(Scrollable)).first,
    );

Future<void> _openEditor(WidgetTester tester) async {
  await holdSettingsButton(tester);
  await tester.scrollUntilVisible(
    find.byKey(const Key('settings-edit-choices')),
    120,
    scrollable: find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.ensureVisible(find.byKey(const Key('settings-edit-choices')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('settings-edit-choices')));
  await tester.pumpAndSettle();
  expect(find.byType(ChoicesEditorScreen), findsOneWidget);
}

Future<void> _openChoice(WidgetTester tester, String id) async {
  await _tapIn(tester, _editorList, Key('choices-row-$id'));
  expect(find.byType(ChoiceDetailScreen), findsOneWidget);
}

Future<void> _backToBoard(WidgetTester tester, Key list, Key button) async {
  await _tapIn(tester, list, button);
  expect(find.byKey(const Key('communication-grid')), findsOneWidget);
}

/// Fills the form and saves it.
Future<void> _fillForm(
  WidgetTester tester, {
  String? label,
  String? phrase,
  String? icon,
  String? color,
}) async {
  if (label != null) {
    await tester.enterText(find.byKey(const Key('choice-label-field')), label);
  }
  if (phrase != null) {
    await tester.enterText(
      find.byKey(const Key('choice-phrase-field')),
      phrase,
    );
  }
  if (icon != null) await _tapIn(tester, _formList, Key('choice-icon-$icon'));
  if (color != null) {
    await _tapIn(tester, _formList, Key('choice-color-$color'));
  }
  await tester.pump();
}

/// Choice ids on the board, in reading order.
List<String> _boardOrder(WidgetTester tester) {
  final cards = find.byType(CommunicationChoiceCard).evaluate().toList()
    ..sort((a, b) {
      final pa = (a.renderObject! as RenderBox).localToGlobal(Offset.zero);
      final pb = (b.renderObject! as RenderBox).localToGlobal(Offset.zero);
      final byRow = pa.dy.compareTo(pb.dy);
      return byRow != 0 ? byRow : pa.dx.compareTo(pb.dx);
    });
  return [
    for (final card in cards)
      (card.widget as CommunicationChoiceCard).choice.id,
  ];
}

String _status(WidgetTester tester, Key key) => tester
    .widget<Semantics>(
      find
          .descendant(of: find.byKey(key), matching: find.byType(Semantics))
          .first,
    )
    .properties
    .label!;

void main() {
  setUpAll(loadSdkFonts);

  late FakeBoardChoicesStore store;
  late FakeSpeechService speech;

  setUp(() {
    store = FakeBoardChoicesStore();
    speech = FakeSpeechService();
  });

  Future<void> start(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    bool disableAnimations = false,
    DateTime Function()? now,
  }) => pumpCareBridge(
    tester,
    size: size,
    textScale: textScale,
    speech: speech,
    boardStore: store,
    store: FakeDisplayPreferencesStore(),
    disableAnimations: disableAnimations,
    now: now,
  );

  testWidgets('an existing user with nothing saved sees the original six '
      'choices, and the board itself offers no way to edit', (tester) async {
    await start(tester);
    expect(_boardOrder(tester), [
      'food',
      'drink',
      'drive',
      'help',
      'rest',
      'finished',
    ]);
    expect(find.byKey(const Key('choices-add')), findsNothing);
    expect(find.byKey(const Key('settings-edit-choices')), findsNothing);
    // A tap on settings does not open it; only a deliberate hold does.
    await tester.tap(find.byKey(const Key('settings-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-edit-choices')), findsNothing);
    expect(store.saveCount, 0);
  });

  testWidgets('a caregiver adds a choice; it is spoken with its own phrase '
      'in one tap and survives a restart', (tester) async {
    await start(tester);
    await _openEditor(tester);
    await _tapIn(tester, _editorList, const Key('choices-add'));
    expect(find.byType(ChoiceFormScreen), findsOneWidget);

    await _fillForm(
      tester,
      label: '  Snack  ',
      phrase: 'I would like a snack,\nplease.',
      icon: 'cookie',
      color: 'yellow',
    );
    await _tapIn(tester, _formList, const Key('choice-save'));

    expect(find.byType(ChoicesEditorScreen), findsOneWidget);
    expect(_status(tester, const Key('choices-status')), startsWith('Saved.'));
    final saved = store.saved!.byId('custom-1')!;
    expect(saved.label, 'Snack');
    expect(saved.spokenPhrase, 'I would like a snack, please.');
    expect(saved.iconId, 'cookie');
    expect(saved.colorId, 'yellow');

    await _backToBoard(tester, _editorList, const Key('choices-back-to-board'));
    expect(_boardOrder(tester).last, 'custom-1');
    await tester.tap(choiceFinder('custom-1'));
    await tester.pump();
    expect(speech.spokenPhrases, ['I would like a snack, please.']);
    expect(find.text('I would like a snack, please.'), findsWidgets);

    // Force-close and relaunch with the same device storage.
    await tester.pumpWidget(const SizedBox());
    await start(tester);
    expect(_boardOrder(tester).last, 'custom-1');
  });

  testWidgets('blank, whitespace-only, and pictureless choices are refused '
      'with clear reasons and nothing is saved', (tester) async {
    await start(tester);
    await _openEditor(tester);
    await _tapIn(tester, _editorList, const Key('choices-add'));
    await _fillForm(tester, label: '   ', phrase: '\n');
    await _tapIn(tester, _formList, const Key('choice-save'));

    expect(
      _status(tester, const Key('choice-save-error')),
      'Some details need attention. See the messages above.',
    );
    await _scrollBackTo(
      tester,
      _formList,
      find.byKey(const Key('choice-icon-error')),
    );
    expect(find.byKey(const Key('choice-icon-error')), findsOneWidget);
    await _scrollBackTo(
      tester,
      _formList,
      find.text('Enter the words for the button.'),
    );
    expect(find.text('Enter the words for the button.'), findsOneWidget);
    expect(find.text('Enter what CareBridge should say.'), findsOneWidget);
    expect(find.byType(ChoiceFormScreen), findsOneWidget);
    expect(store.saveCount, 0);
  });

  testWidgets('oversized text cannot be entered past the limits', (
    tester,
  ) async {
    await start(tester);
    await _openEditor(tester);
    await _tapIn(tester, _editorList, const Key('choices-add'));
    await _fillForm(tester, label: 'x' * 60, phrase: 'y' * 400);
    final label = tester.widget<TextField>(
      find.byKey(const Key('choice-label-field')),
    );
    final phrase = tester.widget<TextField>(
      find.byKey(const Key('choice-phrase-field')),
    );
    expect(label.controller!.text, hasLength(BoardLimits.maxLabelLength));
    expect(phrase.controller!.text, hasLength(BoardLimits.maxPhraseLength));
  });

  testWidgets('editing changes the label and the spoken phrase separately '
      'and keeps the id; speech uses the new phrase', (tester) async {
    await start(tester);
    await _openEditor(tester);
    await _openChoice(tester, 'drink');
    await _tapIn(tester, _detailList, const Key('choice-edit'));
    await _fillForm(tester, phrase: 'Water, please.');
    await _tapIn(tester, _formList, const Key('choice-save'));

    expect(find.byType(ChoiceDetailScreen), findsOneWidget);
    expect(find.text('Says: Water, please.'), findsOneWidget);
    await _backToBoard(tester, _detailList, const Key('choice-back-to-board'));

    expect(find.text('Drink'), findsOneWidget);
    await tester.tap(choiceFinder('drink'));
    await tester.pump();
    expect(speech.spokenPhrases, ['Water, please.']);
    expect(store.saved!.byId('drink')!.label, 'Drink');
  });

  testWidgets('hiding removes a choice from the board without losing it, and '
      'showing it puts it back in its place', (tester) async {
    await start(tester);
    await _openEditor(tester);
    await _openChoice(tester, 'drive');
    await _tapIn(tester, _detailList, const Key('choice-visibility'));
    expect(find.text('Show on board'), findsOneWidget);
    expect(
      _status(tester, const Key('choice-status')),
      'Saved. Position 3 of 6. Hidden from the board.',
    );
    await _backToBoard(tester, _detailList, const Key('choice-back-to-board'));
    expect(choiceFinder('drive'), findsNothing);
    expect(_boardOrder(tester), hasLength(5));

    await _openEditor(tester);
    expect(find.byKey(const Key('choices-hidden-drive')), findsOneWidget);
    await _openChoice(tester, 'drive');
    await _tapIn(tester, _detailList, const Key('choice-visibility'));
    await _backToBoard(tester, _detailList, const Key('choice-back-to-board'));
    expect(_boardOrder(tester)[2], 'drive');
  });

  testWidgets('the last shown choice cannot be hidden', (tester) async {
    store = FakeBoardChoicesStore(
      BoardChoices.original
          .withVisibility('drink', visible: false)
          .withVisibility('drive', visible: false)
          .withVisibility('help', visible: false)
          .withVisibility('rest', visible: false)
          .withVisibility('finished', visible: false),
    );
    await start(tester);
    await _openEditor(tester);
    await _openChoice(tester, 'food');
    final saves = store.saveCount;
    await _tapIn(tester, _detailList, const Key('choice-visibility'));
    expect(
      _status(tester, const Key('choice-status')),
      contains('At least one choice must stay on the board'),
    );
    expect(store.saveCount, saves);
  });

  testWidgets('reordering buttons never move under the finger, and the new '
      'order is saved and shown', (tester) async {
    await start(tester);
    await _openEditor(tester);
    await _openChoice(tester, 'finished');
    final earlier = find.byKey(const Key('choice-move-earlier'));
    await tester.ensureVisible(earlier);
    await tester.pumpAndSettle();
    final before = tester.getRect(earlier);
    for (var i = 0; i < 3; i++) {
      await tester.tap(earlier);
      await tester.pumpAndSettle();
      expect(tester.getRect(earlier), before);
    }
    expect(
      _status(tester, const Key('choice-status')),
      'Saved. Position 3 of 6. On the board.',
    );
    await _backToBoard(tester, _detailList, const Key('choice-back-to-board'));
    final order = ['food', 'drink', 'finished', 'drive', 'help', 'rest'];
    expect(_boardOrder(tester), order);
    expect(store.saved!.choices.map((c) => c.id), order);
  });

  testWidgets('screen readers can reorder with the same buttons', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await start(tester);
    await _openEditor(tester);
    await _openChoice(tester, 'food');
    await tester.ensureVisible(find.byKey(const Key('choice-move-later')));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byKey(const Key('choice-move-earlier'))),
      isSemantics(label: 'Move earlier', isButton: true, isEnabled: false),
    );
    tester.semantics.tap(find.semantics.byLabel('Move later'));
    await tester.pumpAndSettle();
    expect(store.saved!.choices[1].id, 'food');
    semantics.dispose();
  });

  testWidgets('keyboard and switch access can reorder repeatedly without '
      'losing focus', (tester) async {
    await start(tester);
    await _openEditor(tester);
    await _openChoice(tester, 'food');
    final later = find.byKey(const Key('choice-move-later'));
    await _reveal(tester, _detailList, later);
    bool laterFocused() {
      final focused = FocusManager.instance.primaryFocus?.context;
      return focused != null &&
          find
              .descendant(
                of: later,
                matching: find.byElementPredicate((e) => e == focused),
              )
              .evaluate()
              .isNotEmpty;
    }

    for (var i = 0; i < 30 && !laterFocused(); i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(laterFocused(), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(laterFocused(), isTrue, reason: 'focus stays after a move');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(store.saved!.choices.map((c) => c.id).take(3), [
      'drink',
      'drive',
      'food',
    ]);
  });

  testWidgets('restoring the original board asks first; keeping changes '
      'does nothing', (tester) async {
    store = FakeBoardChoicesStore(
      BoardChoices.original
          .withAdded(
            const ChoiceDraft(
              label: 'Swim',
              spokenPhrase: 'I want to swim.',
              iconId: 'walk',
              colorId: 'teal',
            ),
          )
          .withMoved('help', -3),
    );
    await start(tester);
    await _openEditor(tester);
    final custom = store.savedText;

    await _tapIn(tester, _editorList, const Key('choices-restore-original'));
    expect(
      find.byKey(const Key('restore-original-confirmation')),
      findsOneWidget,
    );
    expect(find.textContaining('The 1 added choice'), findsOneWidget);
    await tester.tap(find.byKey(const Key('restore-original-cancel')));
    await tester.pumpAndSettle();
    expect(store.savedText, custom);

    await _tapIn(tester, _editorList, const Key('choices-restore-original'));
    await tester.tap(find.byKey(const Key('restore-original-confirm')));
    await tester.pumpAndSettle();
    expect(store.saved, BoardChoices.original);
    await _backToBoard(tester, _editorList, const Key('choices-back-to-board'));
    expect(_boardOrder(tester), [
      'food',
      'drink',
      'drive',
      'help',
      'rest',
      'finished',
    ]);
  });

  testWidgets('a failed save is explained and the board is unchanged', (
    tester,
  ) async {
    await start(tester);
    await _openEditor(tester);
    await _openChoice(tester, 'help');
    store.saveError = StateError('disk full');
    await _tapIn(tester, _detailList, const Key('choice-visibility'));
    expect(
      _status(tester, const Key('choice-status')),
      'This change could not be saved. Nothing changed. Try again.',
    );
    expect(find.text('Hide from board'), findsOneWidget);

    await _tapIn(tester, _detailList, const Key('choice-edit'));
    await _fillForm(tester, label: 'Help me');
    await _tapIn(tester, _formList, const Key('choice-save'));
    expect(find.byType(ChoiceFormScreen), findsOneWidget);
    expect(find.byKey(const Key('choice-save-error')), findsOneWidget);
    expect(store.savedText, isNull);
  });

  testWidgets('a save that is still running ignores repeated taps', (
    tester,
  ) async {
    await start(tester);
    await _openEditor(tester);
    await _openChoice(tester, 'rest');
    store.pendingSave = Completer();
    final later = find.byKey(const Key('choice-move-later'));
    await tester.ensureVisible(later);
    await tester.pumpAndSettle();
    await tester.tap(later);
    await tester.pump();
    await tester.tap(later);
    await tester.pump();
    store.pendingSave!.complete();
    await tester.pumpAndSettle();
    expect(store.saveCount, 1);
    expect(store.saved!.choices.map((c) => c.id).last, 'rest');
  });

  testWidgets('leaving a form with changes asks before discarding them', (
    tester,
  ) async {
    await start(tester);
    await _openEditor(tester);
    await _tapIn(tester, _editorList, const Key('choices-add'));
    await _fillForm(tester, label: 'Park');

    await _tapIn(tester, _formList, const Key('choice-cancel'));
    expect(find.byKey(const Key('discard-confirmation')), findsOneWidget);
    await tester.tap(find.byKey(const Key('discard-cancel')));
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceFormScreen), findsOneWidget);
    await _scrollBackTo(tester, _formList, find.text('Park'));
    expect(find.text('Park'), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('discard-confirm')));
    await tester.pumpAndSettle();
    expect(find.byType(ChoicesEditorScreen), findsOneWidget);
    expect(store.saveCount, 0);
  });

  testWidgets('a form with no changes closes without asking', (tester) async {
    await start(tester);
    await _openEditor(tester);
    await _openChoice(tester, 'food');
    await _tapIn(tester, _detailList, const Key('choice-edit'));
    await _tapIn(tester, _formList, const Key('choice-cancel'));
    expect(find.byKey(const Key('discard-confirmation')), findsNothing);
    expect(find.byType(ChoiceDetailScreen), findsOneWidget);
  });

  testWidgets('the confirmation never shows words that were not spoken: '
      'editing the selected choice clears it, moving another keeps it', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(choiceFinder('help'));
    await tester.pump();
    expect(boardController(tester).selectedChoice?.id, 'help');

    await _openEditor(tester);
    await _openChoice(tester, 'food');
    await _tapIn(tester, _detailList, const Key('choice-move-later'));
    expect(boardController(tester).selectedChoice?.id, 'help');

    await tester.pageBack();
    await tester.pumpAndSettle();
    await _openChoice(tester, 'help');
    await _tapIn(tester, _detailList, const Key('choice-edit'));
    await _fillForm(tester, phrase: 'Please help me now.');
    await _tapIn(tester, _formList, const Key('choice-save'));
    expect(boardController(tester).selectedChoice, isNull);
    await _backToBoard(tester, _detailList, const Key('choice-back-to-board'));
    expect(find.text('Please help me now.'), findsNothing);
  });

  testWidgets('rapid taps on a custom choice speak it once; another choice '
      'interrupts it', (tester) async {
    store = FakeBoardChoicesStore(
      BoardChoices.original.withAdded(
        const ChoiceDraft(
          label: 'Swing',
          spokenPhrase: 'I want the swing.',
          iconId: 'tree',
          colorId: 'green',
        ),
      ),
    );
    final clock = DateTime(2026, 11, 3, 10);
    await start(tester, now: () => clock);
    speech.pendingSpeech = Completer();
    for (var i = 0; i < 4; i++) {
      await tester.tap(choiceFinder('custom-1'));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.tap(choiceFinder('drink'));
    await tester.pump();
    expect(speech.spokenPhrases, [
      'I want the swing.',
      'I would like a drink.',
    ]);
    expect(boardController(tester).selectedChoice?.id, 'drink');
    speech.pendingSpeech!.complete();
  });

  testWidgets('corrupted saved choices leave the original board usable and '
      'are explained to the caregiver', (tester) async {
    store.savedText = '{"schemaVersion":1,"choices":[{"id":';
    await start(tester);
    expect(_boardOrder(tester), hasLength(6));
    await tester.tap(choiceFinder('help'));
    await tester.pump();
    expect(speech.spokenPhrases, ['I need help.']);
    await _openEditor(tester);
    expect(find.byKey(const Key('choices-load-problem')), findsOneWidget);
    expect(store.saveCount, 0);
  });

  testWidgets('a full board says why no more choices can be added', (
    tester,
  ) async {
    var full = BoardChoices.original;
    while (!full.isFull) {
      full = full.withAdded(
        const ChoiceDraft(
          label: 'More',
          spokenPhrase: 'More.',
          iconId: 'plus',
          colorId: 'white',
        ),
      );
    }
    store = FakeBoardChoicesStore(full);
    await start(tester);
    await _openEditor(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('choices-full')),
      400,
      scrollable: _inList(_editorList, find.byType(Scrollable)).first,
    );
    final add = tester.widget<ButtonStyleButton>(
      find.descendant(
        of: find.byKey(const Key('choices-add')),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );
    expect(add.onPressed, isNull);
  });

  group('accessibility', () {
    testWidgets('rows, pictures, and colors are labeled for screen '
        'readers', (tester) async {
      final semantics = tester.ensureSemantics();
      await start(tester);
      await _openEditor(tester);
      expect(
        tester.getSemantics(find.byKey(const Key('choices-row-food'))),
        isSemantics(
          label:
              'Food. Says: I would like something to eat. On the board. '
              'Position 1 of 6.',
          isButton: true,
          hasTapAction: true,
        ),
      );
      await _openChoice(tester, 'food');
      await _tapIn(tester, _detailList, const Key('choice-edit'));
      await _reveal(
        tester,
        _formList,
        find.byKey(const Key('choice-icon-food')),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('choice-icon-food'))),
        isSemantics(
          label: 'Fork and knife',
          isButton: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      await _reveal(
        tester,
        _formList,
        find.byKey(const Key('choice-color-blue')),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('choice-color-blue'))),
        isSemantics(
          label: 'Blue',
          isButton: true,
          isSelected: false,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('every editor control is a large target', (tester) async {
      await start(tester);
      await _openEditor(tester);
      for (final key in [
        'choices-back-to-board',
        'choices-row-food',
        'choices-add',
        'choices-restore-original',
      ]) {
        await _reveal(tester, _editorList, find.byKey(Key(key)));
        final size = tester.getSize(find.byKey(Key(key)));
        expect(size.height, greaterThanOrEqualTo(72), reason: key);
      }
      await _openChoice(tester, 'food');
      for (final key in [
        'choice-edit',
        'choice-move-earlier',
        'choice-move-later',
        'choice-visibility',
        'choice-back-to-board',
      ]) {
        await _reveal(tester, _detailList, find.byKey(Key(key)));
        expect(
          tester.getSize(find.byKey(Key(key))).height,
          greaterThanOrEqualTo(72),
          reason: key,
        );
      }
      await _tapIn(tester, _detailList, const Key('choice-edit'));
      await _reveal(
        tester,
        _formList,
        find.byKey(const Key('choice-color-blue')),
      );
      final icon = tester.getSize(find.byKey(const Key('choice-icon-food')));
      expect(icon.shortestSide, greaterThanOrEqualTo(72));
      final color = tester.getSize(find.byKey(const Key('choice-color-blue')));
      expect(color.shortestSide, greaterThanOrEqualTo(72));
    });

    testWidgets('the editor follows high contrast', (tester) async {
      await pumpCareBridge(
        tester,
        boardStore: store,
        store: FakeDisplayPreferencesStore(),
        systemHighContrast: true,
      );
      await _openEditor(tester);
      await _openChoice(tester, 'food');
      expect(
        CareBridgePalette.of(
          tester.element(find.byKey(const Key('choice-edit'))),
        ).isHighContrast,
        isTrue,
      );
    });

    testWidgets('with reduced motion the editor appears at once', (
      tester,
    ) async {
      await start(tester, disableAnimations: true);
      await holdSettingsButton(tester);
      await tester.ensureVisible(
        find.byKey(const Key('settings-edit-choices')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-edit-choices')));
      await tester.pump();
      await tester.pump();
      expect(find.byType(ChoicesEditorScreen), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    for (final (name, size, scale) in [
      ('small phone at 3x text', const Size(320, 568), 3.0),
      ('phone landscape at 2x text', const Size(844, 390), 2.0),
      ('tablet portrait at 2x text', const Size(820, 1180), 2.0),
      ('tablet landscape', const Size(1366, 1024), 1.0),
    ]) {
      testWidgets('$name: every editor screen lays out and works', (
        tester,
      ) async {
        await start(tester, size: size, textScale: scale);
        await _openEditor(tester);
        await _openChoice(tester, 'food');
        await _tapIn(tester, _detailList, const Key('choice-move-later'));
        await _tapIn(tester, _detailList, const Key('choice-edit'));
        await _fillForm(tester, label: 'Lunch', icon: 'cookie', color: 'pink');
        await _tapIn(tester, _formList, const Key('choice-save'));
        expect(find.byType(ChoiceDetailScreen), findsOneWidget);
        await _backToBoard(
          tester,
          _detailList,
          const Key('choice-back-to-board'),
        );
        expect(tester.takeException(), isNull);
        expect(store.saved!.choices[1].label, 'Lunch');
        expect(find.text('Lunch'), findsOneWidget);
      });
    }
  });
}
