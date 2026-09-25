import 'package:carebridge/app.dart';
import 'package:carebridge/domain/communication_models.dart';
import 'package:carebridge/domain/sample_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_speech_service.dart';
import '../support/fake_tactile_feedback.dart';
import '../support/sdk_fonts.dart';

const _choiceIds = ['food', 'drink', 'drive', 'help', 'rest', 'finished'];

/// Realistic longer content a caregiver might configure later.
const _longContentProfile = CommunicatorProfile(
  id: 'long',
  displayName: 'Long content',
  categories: [
    CommunicationCategory(
      id: 'everyday',
      label: 'Everyday',
      order: 0,
      choices: [
        CommunicationChoice(
          id: 'television',
          label: 'Watch television',
          spokenPhrase: 'I would like to watch television now, please.',
          visual: ChoiceVisual.icon(Icons.tv, backgroundColor: Colors.white),
          order: 0,
        ),
        CommunicationChoice(
          id: 'headphones',
          label: 'Headphones',
          spokenPhrase: 'Can you help me find my headphones, please?',
          visual: ChoiceVisual.icon(
            Icons.headphones,
            backgroundColor: Colors.white,
          ),
          order: 1,
        ),
        CommunicationChoice(
          id: 'bathroom',
          label: 'Bathroom',
          spokenPhrase: 'I need to use the bathroom.',
          visual: ChoiceVisual.icon(Icons.wc, backgroundColor: Colors.white),
          order: 2,
        ),
        CommunicationChoice(
          id: 'outside',
          label: 'Go outside',
          spokenPhrase: 'I want to go outside for a walk.',
          visual: ChoiceVisual.icon(Icons.park, backgroundColor: Colors.white),
          order: 3,
        ),
      ],
    ),
  ],
);

Future<void> _pumpBoard(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  FakeViewPadding padding = FakeViewPadding.zero,
  CommunicatorProfile profile = sampleCommunicator,
  FakeSpeechService? speech,
  FakeTactileFeedback? haptics,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = padding;
  tester.view.viewPadding = padding;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    CareBridgeApp(
      speechService: speech ?? FakeSpeechService(),
      tactileFeedback: haptics,
      profile: profile,
    ),
  );
}

Finder _choice(String id) => find.byKey(Key('choice-$id'));

RenderParagraph _paragraphIn(WidgetTester tester, Finder finder) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(of: finder, matching: find.byType(RichText)).first,
    );

void main() {
  setUpAll(loadSdkFonts);

  testWidgets('configured choices render and activation confirms phrase', (
    tester,
  ) async {
    final speech = FakeSpeechService();
    await _pumpBoard(tester, speech: speech);
    for (final label in [
      'Food',
      'Drink',
      'Drive',
      'Help',
      'Rest',
      'Finished',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(_choice('drive'));
    await tester.pump();
    expect(find.text('I want to go for a drive.'), findsOneWidget);
    expect(find.byKey(const Key('selected-check')), findsOneWidget);
    expect(speech.spokenPhrases, ['I want to go for a drive.']);
  });

  testWidgets('the board is usable on the first frame, before any speech', (
    tester,
  ) async {
    final speech = FakeSpeechService();
    await _pumpBoard(tester, speech: speech);
    for (final id in _choiceIds) {
      expect(_choice(id).hitTestable(), findsOneWidget);
    }
    expect(speech.spokenPhrases, isEmpty);
    expect(speech.stopCount, 0);
  });

  testWidgets('visual confirmation survives a speech failure', (tester) async {
    final speech = FakeSpeechService()..error = StateError('no voice');
    await _pumpBoard(tester, speech: speech);
    await tester.tap(_choice('help'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('I need help.'), findsOneWidget);
    expect(find.byKey(const Key('selected-check')), findsOneWidget);
  });

  testWidgets('choice exposes accessible button semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await _pumpBoard(tester);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Drive')),
      matchesSemantics(
        label: 'Drive',
        hint: 'Says: I want to go for a drive.',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        hasSelectedState: true,
        isSelected: false,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('semantics follow the selection and announce the phrase', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pumpBoard(tester);
    expect(
      find.bySemanticsLabel('Choose what you want to say'),
      findsOneWidget,
    );

    await tester.tap(_choice('drive'));
    await tester.pump();
    await tester.tap(_choice('food'));
    await tester.pump();

    expect(
      tester.getSemantics(find.bySemanticsLabel('Food')),
      matchesSemantics(
        label: 'Food',
        hint: 'Says: I would like something to eat.',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Drive')),
      matchesSemantics(
        label: 'Drive',
        hint: 'Says: I want to go for a drive.',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        hasSelectedState: true,
        isSelected: false,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(
        find.bySemanticsLabel('Selected. I would like something to eat.'),
      ),
      matchesSemantics(
        label: 'Selected. I would like something to eat.',
        isLiveRegion: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('confirmation is non-modal: another choice replaces it at once', (
    tester,
  ) async {
    final speech = FakeSpeechService();
    await _pumpBoard(tester, speech: speech);
    await tester.tap(_choice('food'));
    await tester.pump();
    expect(_choice('drink').hitTestable(), findsOneWidget);
    await tester.tap(_choice('drink'));
    await tester.pump();

    expect(find.text('I would like a drink.'), findsOneWidget);
    expect(find.text('I would like something to eat.'), findsNothing);
    expect(find.byKey(const Key('selected-check')), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    expect(speech.spokenPhrases, [
      'I would like something to eat.',
      'I would like a drink.',
    ]);
  });

  testWidgets('a rapid double tap acknowledges once', (tester) async {
    final speech = FakeSpeechService();
    final haptics = FakeTactileFeedback();
    await _pumpBoard(tester, speech: speech, haptics: haptics);
    await tester.tap(_choice('help'));
    await tester.tap(_choice('help'));
    await tester.pump();

    expect(haptics.acknowledgements, 1);
    expect(speech.spokenPhrases, ['I need help.']);
  });

  testWidgets('a haptic failure still communicates', (tester) async {
    final speech = FakeSpeechService();
    final haptics = FakeTactileFeedback()..error = StateError('no motor');
    await _pumpBoard(tester, speech: speech, haptics: haptics);
    await tester.tap(_choice('rest'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('I need to rest.'), findsOneWidget);
    expect(speech.spokenPhrases, ['I need to rest.']);
  });

  testWidgets('leaving the foreground stops speech but keeps the selection', (
    tester,
  ) async {
    final speech = FakeSpeechService();
    await _pumpBoard(tester, speech: speech);
    await tester.tap(_choice('help'));
    await tester.pump();

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    expect(speech.stopCount, 1);
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('I need help.'), findsOneWidget);
    expect(find.byKey(const Key('selected-check')), findsOneWidget);
    expect(speech.spokenPhrases, ['I need help.'], reason: 'nothing replays');
  });

  testWidgets('losing focus alone does not interrupt speech', (tester) async {
    final speech = FakeSpeechService();
    await _pumpBoard(tester, speech: speech);
    await tester.tap(_choice('food'));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(speech.stopCount, 0);
  });

  testWidgets('a long phrase does not move the choices', (tester) async {
    await _pumpBoard(tester, profile: _longContentProfile, textScale: 1.5);
    final before = tester.getRect(_choice('bathroom'));
    await tester.tap(_choice('headphones'));
    await tester.pumpAndSettle();
    expect(tester.getRect(_choice('bathroom')), before);
  });

  const phone = FakeViewPadding(top: 47, bottom: 34);
  const phoneLandscape = FakeViewPadding(left: 47, right: 47, bottom: 21);
  const tablet = FakeViewPadding(top: 24, bottom: 20);
  for (final viewport in [
    (name: 'narrow phone', size: const Size(320, 568), padding: phone),
    (name: 'phone', size: const Size(390, 844), padding: phone),
    (name: 'large phone', size: const Size(430, 932), padding: phone),
    (
      name: 'narrow phone landscape',
      size: const Size(568, 320),
      padding: FakeViewPadding.zero,
    ),
    (
      name: 'phone landscape',
      size: const Size(844, 390),
      padding: phoneLandscape,
    ),
    (name: 'tablet portrait', size: const Size(768, 1024), padding: tablet),
    (name: 'tablet landscape', size: const Size(1024, 768), padding: tablet),
    (
      name: 'large tablet landscape',
      size: const Size(1366, 1024),
      padding: tablet,
    ),
  ]) {
    for (final textScale in [1.0, 2.0, 3.0]) {
      testWidgets('${viewport.name} at ${textScale}x text shows every choice '
          'whole, on screen, and clear of the confirmation', (tester) async {
        await _pumpBoard(
          tester,
          size: viewport.size,
          padding: viewport.padding,
          textScale: textScale,
        );
        await tester.tap(_choice('finished'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final screen = Offset.zero & viewport.size;
        final confirmation = tester.getRect(
          find.byKey(const Key('confirmation-banner')),
        );
        for (final id in _choiceIds) {
          final card = tester.getRect(_choice(id));
          expect(_choice(id).hitTestable(), findsOneWidget, reason: id);
          expect(screen.intersect(card), card, reason: '$id on screen');
          expect(card.shortestSide, greaterThanOrEqualTo(110), reason: id);
          expect(confirmation.overlaps(card), isFalse, reason: id);
          expect(
            _paragraphIn(tester, _choice(id)).didExceedMaxLines,
            isFalse,
            reason: '$id label truncated',
          );
        }
        expect(
          _paragraphIn(
            tester,
            find.byKey(const Key('confirmation-phrase')),
          ).didExceedMaxLines,
          isFalse,
        );
      });
    }
  }

  for (final viewport in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(1024, 768),
  ]) {
    testWidgets('long realistic labels and phrases stay whole at $viewport '
        'with 2x text', (tester) async {
      await _pumpBoard(
        tester,
        size: viewport,
        profile: _longContentProfile,
        textScale: 2,
      );
      await tester.tap(_choice('television'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final id in ['television', 'headphones', 'bathroom', 'outside']) {
        expect(
          _paragraphIn(tester, _choice(id)).didExceedMaxLines,
          isFalse,
          reason: id,
        );
      }
      expect(
        find.text('I would like to watch television now, please.'),
        findsOneWidget,
      );
      expect(
        _paragraphIn(
          tester,
          find.byKey(const Key('confirmation-phrase')),
        ).didExceedMaxLines,
        isFalse,
      );
    });
  }

  testWidgets('a very small window scrolls instead of shrinking targets', (
    tester,
  ) async {
    await _pumpBoard(tester, size: const Size(320, 360));
    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(_choice('food')).shortestSide,
      greaterThanOrEqualTo(110),
    );
    await tester.scrollUntilVisible(
      _choice('finished'),
      200,
      scrollable: find.descendant(
        of: find.byKey(const Key('communication-grid')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(_choice('finished').hitTestable(), findsOneWidget);
  });
}
