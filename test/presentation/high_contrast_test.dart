// High contrast (issue #4): the setting, its persistence, readability, and
// semantics, plus the settings entry point on the board.
import 'package:carebridge/domain/display_preferences.dart';
import 'package:carebridge/domain/sample_board.dart';
import 'package:carebridge/infrastructure/shared_preferences_display_preferences_store.dart';
import 'package:carebridge/presentation/care_bridge_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/board_harness.dart';
import '../support/fake_display_preferences_store.dart';
import '../support/fake_speech_service.dart';
import '../support/sdk_fonts.dart';

const _choiceIds = ['food', 'drink', 'drive', 'help', 'rest', 'finished'];

RoundedRectangleBorder _cardShape(WidgetTester tester, String id) =>
    tester
            .widget<Material>(
              find
                  .ancestor(
                    of: choiceFinder(id),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .shape!
        as RoundedRectangleBorder;

Color? _textColor(WidgetTester tester, Finder within) => tester
    .widget<RichText>(
      find.descendant(of: within, matching: find.byType(RichText)).first,
    )
    .text
    .style
    ?.color;

BoxDecoration _confirmationDecoration(WidgetTester tester) =>
    tester
            .widget<AnimatedContainer>(
              find.byKey(const Key('confirmation-banner')),
            )
            .decoration!
        as BoxDecoration;

Future<void> _setHighContrastInSettings(WidgetTester tester) async {
  await holdSettingsButton(tester);
  await tester.tap(find.byKey(const Key('high-contrast-switch')));
  await tester.pump();
  await returnToBoard(tester);
}

/// WCAG 2.x contrast ratio between two opaque colors.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  setUpAll(loadSdkFonts);

  group('contrast ratios', () {
    final choiceColors = sampleCommunicator.enabledChoices.map(
      (choice) => choice.visual.backgroundColor,
    );

    test('high contrast text and icons meet WCAG AAA (7:1) on every choice '
        'and on the confirmation', () {
      const palette = CareBridgePalette.highContrast;
      for (final background in choiceColors) {
        expect(_contrast(palette.ink, background), greaterThanOrEqualTo(7));
        expect(_contrast(palette.outline, background), greaterThanOrEqualTo(7));
      }
      expect(
        _contrast(palette.onSelectedSurface, palette.selectedSurface),
        greaterThanOrEqualTo(7),
      );
      expect(_contrast(palette.ink, palette.surface), greaterThanOrEqualTo(7));
    });

    test('high contrast borders and focus meet the 3:1 non-text minimum', () {
      const palette = CareBridgePalette.highContrast;
      for (final background in [...choiceColors, palette.background]) {
        expect(
          _contrast(palette.idleBorder, background),
          greaterThanOrEqualTo(3),
        );
        expect(_contrast(palette.focus, background), greaterThanOrEqualTo(3));
      }
      expect(
        palette.selectedBorderWidth,
        greaterThan(palette.idleBorderWidth * 2),
        reason: 'selection differs by border weight, not color',
      );
    });

    test('the standard palette keeps its documented ratios', () {
      const palette = CareBridgePalette.standard;
      for (final background in choiceColors) {
        expect(_contrast(palette.ink, background), greaterThanOrEqualTo(10));
      }
      expect(
        _contrast(palette.onSelectedSurface, palette.selectedSurface),
        greaterThanOrEqualTo(7),
      );
    });
  });

  testWidgets('high contrast is off by default and nothing is saved', (
    tester,
  ) async {
    final store = FakeDisplayPreferencesStore();
    await pumpCareBridge(tester, store: store);

    expect(paletteOnBoard(tester).isHighContrast, isFalse);
    final shape = _cardShape(tester, 'food');
    expect(shape.side.color, CareBridgePalette.standard.idleBorder);
    expect(shape.side.width, 2);
    expect(store.saveCount, 0);

    await holdSettingsButton(tester);
    expect(find.text('Off'), findsOneWidget);
  });

  testWidgets('enabling high contrast darkens text, icons, and borders on the '
      'board at once', (tester) async {
    await pumpCareBridge(tester, store: FakeDisplayPreferencesStore());
    await _setHighContrastInSettings(tester);

    expect(paletteOnBoard(tester).isHighContrast, isTrue);
    for (final id in _choiceIds) {
      final shape = _cardShape(tester, id);
      expect(shape.side.color, Colors.black, reason: id);
      expect(shape.side.width, 3, reason: id);
      expect(_textColor(tester, choiceFinder(id)), Colors.black, reason: id);
    }
    expect(_confirmationDecoration(tester).border!.top.color, Colors.black);

    await tester.tap(choiceFinder('help'));
    await tester.pump();
    final selected = _cardShape(tester, 'help');
    expect(selected.side.width, 8);
    expect(find.byKey(const Key('selected-check')), findsOneWidget);
    expect(_confirmationDecoration(tester).color, Colors.black);
    expect(
      _textColor(tester, find.byKey(const Key('confirmation-phrase'))),
      Colors.white,
    );
    // Each choice keeps its own color, so choices stay distinguishable.
    final helpMaterial = tester.widget<Material>(
      find
          .ancestor(of: choiceFinder('help'), matching: find.byType(Material))
          .first,
    );
    expect(helpMaterial.color, const Color(0xFFFFC8C2));
  });

  testWidgets('disabling high contrast restores the standard display', (
    tester,
  ) async {
    final store = FakeDisplayPreferencesStore(
      const DisplayPreferences(highContrast: true),
    );
    await pumpCareBridge(tester, store: store);
    expect(paletteOnBoard(tester).isHighContrast, isTrue);

    await _setHighContrastInSettings(tester);

    expect(paletteOnBoard(tester).isHighContrast, isFalse);
    expect(
      _cardShape(tester, 'food').side.color,
      CareBridgePalette.standard.idleBorder,
    );
    expect(store.saved, const DisplayPreferences(highContrast: false));
  });

  testWidgets('the preference survives a restart', (tester) async {
    final store = FakeDisplayPreferencesStore();
    await pumpCareBridge(tester, store: store);
    await _setHighContrastInSettings(tester);

    // Restart: the old app is torn down and a new one reads the same store.
    await tester.pumpWidget(const SizedBox());
    await pumpCareBridge(tester, store: store);

    expect(paletteOnBoard(tester).isHighContrast, isTrue);
    await holdSettingsButton(tester);
    expect(find.text('On'), findsOneWidget);
  });

  testWidgets('the preference survives a restart through on-device storage', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await pumpCareBridge(
      tester,
      store: SharedPreferencesDisplayPreferencesStore(),
    );
    await _setHighContrastInSettings(tester);

    await tester.pumpWidget(const SizedBox());
    await pumpCareBridge(
      tester,
      store: SharedPreferencesDisplayPreferencesStore(),
    );
    await tester.pump();

    expect(paletteOnBoard(tester).isHighContrast, isTrue);
  });

  testWidgets('unreadable or unwritable storage never blocks the board', (
    tester,
  ) async {
    final speech = FakeSpeechService();
    final store = FakeDisplayPreferencesStore()
      ..loadError = StateError('corrupt')
      ..saveError = StateError('disk full');
    await pumpCareBridge(tester, store: store, speech: speech);
    expect(tester.takeException(), isNull);

    await tester.tap(choiceFinder('drink'));
    await tester.pump();
    expect(speech.spokenPhrases, ['I would like a drink.']);

    await _setHighContrastInSettings(tester);
    expect(tester.takeException(), isNull);
    expect(paletteOnBoard(tester).isHighContrast, isTrue);
    expect(find.text('I would like a drink.'), findsOneWidget);
  });

  testWidgets('the device asking for more contrast turns high contrast on', (
    tester,
  ) async {
    await pumpCareBridge(
      tester,
      store: FakeDisplayPreferencesStore(),
      systemHighContrast: true,
    );
    expect(paletteOnBoard(tester).isHighContrast, isTrue);

    await holdSettingsButton(tester);
    expect(find.byKey(const Key('system-high-contrast-note')), findsOneWidget);
  });

  testWidgets('phrases, speech, and choices are unchanged in high contrast', (
    tester,
  ) async {
    final speech = FakeSpeechService();
    await pumpCareBridge(
      tester,
      speech: speech,
      store: FakeDisplayPreferencesStore(
        const DisplayPreferences(highContrast: true),
      ),
    );
    for (final choice in sampleCommunicator.enabledChoices) {
      expect(find.text(choice.label), findsOneWidget);
    }
    await tester.tap(choiceFinder('drive'));
    await tester.pump();
    expect(find.text('I want to go for a drive.'), findsOneWidget);
    expect(speech.spokenPhrases, ['I want to go for a drive.']);
  });

  testWidgets('changing contrast keeps the selection and session events', (
    tester,
  ) async {
    await pumpCareBridge(tester, store: FakeDisplayPreferencesStore());
    await tester.tap(choiceFinder('rest'));
    await tester.pump();

    await _setHighContrastInSettings(tester);

    expect(boardController(tester).selectedChoice?.id, 'rest');
    expect(boardController(tester).sessionEvents, hasLength(1));
    expect(find.text('I need to rest.'), findsOneWidget);
    expect(find.byKey(const Key('selected-check')), findsOneWidget);
  });

  group('semantics', () {
    testWidgets('choices keep their labels, hints, and selected state in high '
        'contrast', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpCareBridge(
        tester,
        store: FakeDisplayPreferencesStore(
          const DisplayPreferences(highContrast: true),
        ),
      );
      await tester.tap(choiceFinder('food'));
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
        tester.getSemantics(find.bySemanticsLabel('Drink')),
        isSemantics(isSelected: false, hasSelectedState: true),
      );
      expect(
        find.bySemanticsLabel('Selected. I would like something to eat.'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('the settings button offers only a long-press action', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpCareBridge(tester);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Settings')),
        matchesSemantics(
          label: 'Settings',
          isButton: true,
          hasLongPressAction: true,
          hasTapAction: false,
          onLongPressHint: 'open settings',
        ),
      );

      tester.semantics.longPress(find.semantics.byLabel('Settings'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('high-contrast-switch')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('the high contrast switch announces its name and state', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpCareBridge(tester, store: FakeDisplayPreferencesStore());
      await holdSettingsButton(tester);

      expect(
        tester.getSemantics(find.bySemanticsLabel('High contrast')),
        isSemantics(
          label: 'High contrast',
          hasToggledState: true,
          isToggled: false,
          hasTapAction: true,
        ),
      );
      tester.semantics.tap(find.semantics.byLabel('High contrast'));
      await tester.pump();
      expect(
        tester.getSemantics(find.bySemanticsLabel('High contrast')),
        isSemantics(isToggled: true),
      );
      expect(find.text('On'), findsOneWidget, reason: 'state shown in words');
      semantics.dispose();
    });
  });

  group('settings button', () {
    testWidgets('a repeated open request shows settings only once', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpCareBridge(tester);
      tester.semantics.longPress(find.semantics.byLabel('Settings'));
      tester.semantics.longPress(find.semantics.byLabel('Settings'));
      await tester.pumpAndSettle();

      await returnToBoard(tester);
      expect(find.byKey(const Key('high-contrast-switch')), findsNothing);
      expect(choiceFinder('food').hitTestable(), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a tap or an ordinary long press does not leave the board', (
      tester,
    ) async {
      await pumpCareBridge(tester);
      await tester.tap(find.byKey(const Key('settings-button')));
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(const Key('settings-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('high-contrast-switch')), findsNothing);
      expect(choiceFinder('food').hitTestable(), findsOneWidget);
    });
  });

  testWidgets('keyboard and switch focus shows a ring and activates the '
      'choice', (tester) async {
    var time = DateTime.utc(2026, 9, 20);
    final speech = FakeSpeechService();
    await pumpCareBridge(tester, speech: speech, now: () => time);
    await tester.tap(choiceFinder('food'));
    await tester.pump();
    time = time.add(const Duration(seconds: 1));
    expect(
      find.byKey(const Key('choice-focus-ring')),
      findsNothing,
      reason: 'touch does not show a focus ring',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(find.byKey(const Key('choice-focus-ring')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(speech.spokenPhrases, hasLength(2));
  });

  group('reduced motion', () {
    for (final highContrast in [false, true]) {
      for (final disableAnimations in [false, true]) {
        testWidgets('confirmation animates for '
            '${disableAnimations ? 0 : 150} ms with high contrast '
            '${highContrast ? 'on' : 'off'}', (tester) async {
          await pumpCareBridge(
            tester,
            disableAnimations: disableAnimations,
            store: FakeDisplayPreferencesStore(
              DisplayPreferences(highContrast: highContrast),
            ),
          );
          expect(
            tester
                .widget<AnimatedContainer>(
                  find.byKey(const Key('confirmation-banner')),
                )
                .duration,
            disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 150),
          );
        });
      }
    }

    testWidgets('switching contrast applies in a single frame', (tester) async {
      await pumpCareBridge(tester, store: FakeDisplayPreferencesStore());
      await holdSettingsButton(tester);
      await tester.tap(find.byKey(const Key('high-contrast-switch')));
      await tester.pump();
      expect(
        CareBridgePalette.of(
          tester.element(find.byKey(const Key('high-contrast-switch'))),
        ).isHighContrast,
        isTrue,
      );
    });
  });

  group('layout', () {
    for (final viewport in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(568, 320),
      const Size(844, 390),
      const Size(768, 1024),
      const Size(1024, 768),
      const Size(1366, 1024),
    ]) {
      for (final highContrast in [false, true]) {
        testWidgets('$viewport at 3x text with high contrast '
            '${highContrast ? 'on' : 'off'}: choices stay whole, and the '
            'settings button is reachable and clear of them', (tester) async {
          await pumpCareBridge(
            tester,
            size: viewport,
            textScale: 3,
            store: FakeDisplayPreferencesStore(
              DisplayPreferences(highContrast: highContrast),
            ),
          );
          await tester.tap(choiceFinder('finished'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          final screen = Offset.zero & viewport;
          final settings = tester.getRect(
            find.byKey(const Key('settings-button')),
          );
          final confirmation = tester.getRect(
            find.byKey(const Key('confirmation-banner')),
          );
          expect(screen.intersect(settings), settings);
          expect(settings.shortestSide, greaterThanOrEqualTo(48));
          expect(settings.overlaps(confirmation), isFalse);
          for (final id in _choiceIds) {
            final card = tester.getRect(choiceFinder(id));
            expect(choiceFinder(id).hitTestable(), findsOneWidget, reason: id);
            expect(screen.intersect(card), card, reason: id);
            expect(card.shortestSide, greaterThanOrEqualTo(110), reason: id);
            expect(settings.overlaps(card), isFalse, reason: id);
            expect(confirmation.overlaps(card), isFalse, reason: id);
            expect(
              tester
                  .renderObject<RenderParagraph>(
                    find
                        .descendant(
                          of: choiceFinder(id),
                          matching: find.byType(RichText),
                        )
                        .first,
                  )
                  .didExceedMaxLines,
              isFalse,
              reason: '$id label truncated',
            );
          }
        });
      }
    }

    testWidgets('settings stays readable at 3x text on a small phone', (
      tester,
    ) async {
      await pumpCareBridge(
        tester,
        size: const Size(320, 568),
        textScale: 3,
        store: FakeDisplayPreferencesStore(),
      );
      await holdSettingsButton(tester);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('high-contrast-switch')));
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      await returnToBoard(tester);
      expect(paletteOnBoard(tester).isHighContrast, isTrue);
      expect(choiceFinder('food').hitTestable(), findsOneWidget);
    });
  });
}
