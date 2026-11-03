// The caregiver's board: loaded without blocking, changed only once saved,
// and always usable when storage misbehaves.
import 'dart:async';

import 'package:carebridge/application/board_choices_controller.dart';
import 'package:carebridge/domain/board_choices.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_board_choices_store.dart';

const _snack = ChoiceDraft(
  label: 'Snack',
  spokenPhrase: 'Snack time, please.',
  iconId: 'cookie',
  colorId: 'yellow',
);

void main() {
  late FakeBoardChoicesStore store;
  late BoardChoicesController controller;
  late int notifications;

  Future<void> start([BoardChoices? saved]) async {
    store = FakeBoardChoicesStore(saved);
    controller = BoardChoicesController(store: store);
    await controller.load();
    notifications = 0;
    controller.addListener(() => notifications++);
  }

  test('with nothing saved the original board is shown and nothing is '
      'written', () async {
    await start();
    expect(controller.board, BoardChoices.original);
    expect(controller.loadFailed, isFalse);
    expect(store.saveCount, 0);
    expect(store.savedText, isNull);
  });

  test('a saved board is shown after loading', () async {
    final saved = BoardChoices.original.withAdded(_snack);
    await start(saved);
    expect(controller.board, saved);
    expect(
      controller.profile.enabledChoices.last.spokenPhrase,
      'Snack time, please.',
    );
  });

  test(
    'the original board shows at once, before saved choices are read',
    () async {
      store = FakeBoardChoicesStore(BoardChoices.original.withAdded(_snack))
        ..pendingLoad = Completer();
      controller = BoardChoicesController(store: store);
      final loading = controller.load();
      expect(controller.board, BoardChoices.original);
      expect(controller.isLoaded, isFalse);
      // A change cannot run before loading, so it cannot overwrite the saved
      // board with an edited original one.
      expect(
        (await controller.setVisible('food', visible: false)).outcome,
        BoardEditOutcome.ignored,
      );
      expect(store.saveCount, 0);
      store.pendingLoad!.complete();
      await loading;
      expect(controller.board.choices, hasLength(7));
    },
  );

  group('corrupted or unreadable storage', () {
    for (final (name, corrupt) in [
      ('truncated text', (FakeBoardChoicesStore s) => s.savedText = '{"sch'),
      (
        'duplicate ids',
        (FakeBoardChoicesStore s) => s.savedText =
            '{"schemaVersion":1,"choices":['
            '{"id":"a","label":"A","phrase":"A","icon":"food",'
            '"color":"blue","visible":true},'
            '{"id":"a","label":"A","phrase":"A","icon":"food",'
            '"color":"blue","visible":true}]}',
      ),
      (
        'a read error',
        (FakeBoardChoicesStore s) => s.loadError = StateError('io'),
      ),
    ]) {
      test('$name: the original board is shown, the saved data is left '
          'alone, and editing still works', () async {
        store = FakeBoardChoicesStore();
        corrupt(store);
        final before = store.savedText;
        controller = BoardChoicesController(store: store);
        await controller.load();

        expect(controller.board, BoardChoices.original);
        expect(controller.loadFailed, isTrue);
        expect(store.savedText, before);
        expect(store.saveCount, 0);

        store.loadError = null;
        final result = await controller.add(_snack);
        expect(result.outcome, BoardEditOutcome.saved);
        expect(controller.loadFailed, isFalse);
        expect(store.saved, controller.board);
      });
    }
  });

  group('changes', () {
    setUp(start);

    test('each change is saved, then shown, keeping ids', () async {
      expect((await controller.add(_snack)).outcome, BoardEditOutcome.saved);
      expect(
        (await controller.edit(
          'food',
          const ChoiceDraft(
            label: 'Lunch',
            spokenPhrase: 'I am hungry for lunch.',
            iconId: 'food',
            colorId: 'orange',
          ),
        )).outcome,
        BoardEditOutcome.saved,
      );
      await controller.move('custom-1', -6);
      await controller.setVisible('drink', visible: false);

      final ids = controller.board.choices.map((c) => c.id).toList();
      expect(ids, [
        'custom-1',
        'food',
        'drink',
        'drive',
        'help',
        'rest',
        'finished',
      ]);
      expect(store.saved, controller.board);
      expect(controller.board.byId('food')!.label, 'Lunch');
      expect(
        controller.profile.enabledChoices.map((c) => c.id),
        isNot(contains('drink')),
      );
      expect(store.saveCount, 4);
    });

    test('a failed save changes nothing, in memory or in storage', () async {
      await controller.add(_snack);
      final before = controller.board;
      final savedBefore = store.savedText;
      notifications = 0;
      store.saveError = StateError('disk full');

      final result = await controller.setVisible('food', visible: false);

      expect(result.outcome, BoardEditOutcome.saveFailed);
      expect(controller.board, same(before));
      expect(store.savedText, savedBefore);
      expect(controller.lastResult?.outcome, BoardEditOutcome.saveFailed);
      expect(controller.isSaving, isFalse);
    });

    test('an invalid change is rejected without saving', () async {
      for (final id in ['drink', 'drive', 'help', 'rest', 'finished']) {
        await controller.setVisible(id, visible: false);
      }
      final saves = store.saveCount;
      final result = await controller.setVisible('food', visible: false);
      expect(result.outcome, BoardEditOutcome.rejected);
      expect(result.problem, BoardChoicesProblem.noneVisible);
      expect(store.saveCount, saves);
      expect(controller.board.visibleCount, 1);
    });

    test('a change requested while another saves is ignored, and the '
        'interrupted one still completes', () async {
      store.pendingSave = Completer();
      final first = controller.move('finished', -1);
      expect(controller.isSaving, isTrue);
      expect(
        (await controller.move('finished', -1)).outcome,
        BoardEditOutcome.ignored,
      );
      expect(controller.board, BoardChoices.original);
      store.pendingSave!.complete();
      expect((await first).outcome, BoardEditOutcome.saved);
      expect(controller.board.choices[4].id, 'finished');
      expect(store.saveCount, 1);
    });

    test('restoring the original board replaces every change', () async {
      await controller.add(_snack);
      await controller.setVisible('help', visible: false);
      expect(
        (await controller.restoreOriginal()).outcome,
        BoardEditOutcome.saved,
      );
      expect(controller.board, BoardChoices.original);
      expect(store.saved, BoardChoices.original);
    });

    test('changes survive a restart', () async {
      await controller.add(_snack);
      await controller.move('custom-1', -2);
      final restarted = BoardChoicesController(store: store);
      await restarted.load();
      expect(restarted.board, controller.board);
    });

    test('nothing happens after disposal', () async {
      controller.dispose();
      expect((await controller.add(_snack)).outcome, BoardEditOutcome.ignored);
      expect(store.saveCount, 0);
    });
  });

  test('without a store the board is kept in memory', () async {
    final memory = BoardChoicesController();
    expect(memory.isLoaded, isTrue);
    await memory.load();
    expect((await memory.add(_snack)).outcome, BoardEditOutcome.saved);
    expect(memory.board.choices, hasLength(7));
  });
}
