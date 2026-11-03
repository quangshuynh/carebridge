// Duplicate activation at the widget and semantics boundary (issue #5).
// Time is a fake clock advanced by hand; nothing sleeps.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/board_harness.dart';
import '../support/fake_speech_service.dart';
import '../support/fake_tactile_feedback.dart';

const _drivePhrase = 'I want to go for a drive.';
const _helpPhrase = 'I need help.';

void main() {
  late DateTime time;
  late FakeSpeechService speech;
  late FakeTactileFeedback haptics;

  setUp(() {
    time = DateTime.utc(2026, 9, 20, 12);
    speech = FakeSpeechService();
    haptics = FakeTactileFeedback();
  });

  Future<void> pumpBoard(WidgetTester tester) =>
      pumpCareBridge(tester, speech: speech, haptics: haptics, now: () => time);

  Future<void> semanticTap(WidgetTester tester, String label) async {
    tester.semantics.tap(find.semantics.byLabel(label));
    await tester.pump();
  }

  void advance(int milliseconds) =>
      time = time.add(Duration(milliseconds: milliseconds));

  List<String> events(WidgetTester tester) =>
      boardController(tester).sessionEvents
          .map((event) => event.choiceId)
          .toList();

  testWidgets('two same-target activations inside the window produce one '
      'event, one phrase, and one acknowledgment', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpBoard(tester);

    await semanticTap(tester, 'Drive');
    advance(300);
    await semanticTap(tester, 'Drive');

    expect(events(tester), ['drive']);
    expect(speech.spokenPhrases, [_drivePhrase]);
    expect(haptics.acknowledgements, 1);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Drive')),
      isSemantics(isSelected: true, isButton: true, hasTapAction: true),
    );
    semantics.dispose();
  });

  testWidgets('a touch and a screen-reader activation of the same target '
      'count once', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpBoard(tester);

    await tester.tap(choiceFinder('help'));
    await tester.pump();
    advance(100);
    await semanticTap(tester, 'Help');

    expect(events(tester), ['help']);
    expect(speech.spokenPhrases, [_helpPhrase]);
    semantics.dispose();
  });

  testWidgets('a different target is accepted at once inside the window, '
      'and the selected state follows it', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpBoard(tester);

    await semanticTap(tester, 'Drive');
    advance(50);
    await semanticTap(tester, 'Help');

    expect(events(tester), ['drive', 'help']);
    expect(speech.spokenPhrases, [_drivePhrase, _helpPhrase]);
    expect(haptics.acknowledgements, 2);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Help')),
      isSemantics(isSelected: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Drive')),
      isSemantics(isSelected: false, hasSelectedState: true),
    );
    expect(find.text(_helpPhrase), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('an intentional same-target activation after the window is '
      'accepted', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpBoard(tester);

    await semanticTap(tester, 'Drive');
    advance(599);
    await semanticTap(tester, 'Drive');
    expect(events(tester), ['drive'], reason: 'still inside the window');

    advance(1);
    await semanticTap(tester, 'Drive');

    expect(events(tester), ['drive', 'drive']);
    expect(speech.spokenPhrases, [_drivePhrase, _drivePhrase]);
    expect(haptics.acknowledgements, 2);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Drive')),
      isSemantics(isSelected: true),
    );
    semantics.dispose();
  });

  testWidgets('a burst of rapid taps speaks once', (tester) async {
    await pumpBoard(tester);
    for (var i = 0; i < 5; i++) {
      await tester.tap(choiceFinder('help'));
      advance(80);
    }
    await tester.pump();

    expect(speech.spokenPhrases, [_helpPhrase]);
    expect(haptics.acknowledgements, 1);
  });

  testWidgets('a repeat is accepted after the window while the first phrase '
      'is still speaking', (tester) async {
    speech.pendingSpeech = Completer<void>();
    await pumpBoard(tester);

    await tester.tap(choiceFinder('help'));
    advance(600);
    await tester.tap(choiceFinder('help'));
    await tester.pump();

    expect(speech.spokenPhrases, [_helpPhrase, _helpPhrase]);
    speech.pendingSpeech!.complete();
    await tester.pump();
    expect(find.text(_helpPhrase), findsOneWidget);
  });

  testWidgets('after a speech failure the same choice can be repeated', (
    tester,
  ) async {
    speech.error = StateError('voice unavailable');
    await pumpBoard(tester);
    await tester.tap(choiceFinder('help'));
    await tester.pump();
    expect(find.text(_helpPhrase), findsOneWidget);

    speech.error = null;
    advance(600);
    await tester.tap(choiceFinder('help'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(events(tester), ['help', 'help']);
  });

  testWidgets('opening settings during speech stops it; returning keeps the '
      'selection, replays nothing, and accepts the next tap', (tester) async {
    speech.pendingSpeech = Completer<void>();
    await pumpBoard(tester);
    await tester.tap(choiceFinder('drive'));
    await tester.pump();

    await holdSettingsButton(tester);
    expect(speech.stopCount, 1);
    expect(find.byKey(const Key('high-contrast-switch')), findsOneWidget);
    expect(choiceFinder('drive').hitTestable(), findsNothing);

    // The earlier phrase finishing while settings is open changes nothing.
    speech.pendingSpeech!.complete();
    speech.pendingSpeech = null;
    await returnToBoard(tester);

    expect(find.text(_drivePhrase), findsOneWidget);
    expect(find.byKey(const Key('selected-check')), findsOneWidget);
    expect(speech.spokenPhrases, [_drivePhrase], reason: 'nothing replays');

    // The clock has not moved: the window ended when the board was left.
    await tester.tap(choiceFinder('drive'));
    await tester.pump();
    expect(speech.spokenPhrases, [_drivePhrase, _drivePhrase]);
    expect(events(tester), ['drive', 'drive']);
  });

  testWidgets('backgrounding stops speech; after restoring, the same choice '
      'is accepted at once and nothing replays', (tester) async {
    await pumpBoard(tester);
    await tester.tap(choiceFinder('help'));
    await tester.pump();

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
    expect(speech.stopCount, 1);
    expect(speech.spokenPhrases, [_helpPhrase]);
    expect(find.byKey(const Key('selected-check')), findsOneWidget);

    await tester.tap(choiceFinder('help'));
    await tester.pump();
    expect(speech.spokenPhrases, [_helpPhrase, _helpPhrase]);
    expect(haptics.acknowledgements, 2);
  });
}
