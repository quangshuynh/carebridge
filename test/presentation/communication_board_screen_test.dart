import 'package:carebridge/application/communication_board_controller.dart';
import 'package:carebridge/domain/sample_board.dart';
import 'package:carebridge/presentation/communication_board_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_speech_service.dart';

void main() {
  Widget board(FakeSpeechService speech) => MaterialApp(
    home: CommunicationBoardScreen(
      profile: sampleCommunicator,
      controller: CommunicationBoardController(speechService: speech),
    ),
  );
  testWidgets('configured choices render and activation confirms phrase', (
    tester,
  ) async {
    final speech = FakeSpeechService();
    await tester.pumpWidget(board(speech));
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
    await tester.tap(find.byKey(const Key('choice-drive')));
    await tester.pump();
    expect(find.text('I want to go for a drive.'), findsOneWidget);
    expect(find.byKey(const Key('selected-check')), findsOneWidget);
    expect(speech.spokenPhrases, ['I want to go for a drive.']);
  });
  testWidgets('visual confirmation survives a speech failure', (tester) async {
    final speech = FakeSpeechService()..error = StateError('no voice');
    await tester.pumpWidget(board(speech));
    await tester.tap(find.byKey(const Key('choice-help')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('I need help.'), findsOneWidget);
    expect(find.byKey(const Key('selected-check')), findsOneWidget);
  });
  testWidgets('choice exposes accessible button semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(board(FakeSpeechService()));
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
  for (final configuration in [
    (size: const Size(390, 844), textScale: 1.0),
    (size: const Size(844, 390), textScale: 1.0),
    (size: const Size(768, 1024), textScale: 1.0),
    (size: const Size(1024, 768), textScale: 1.0),
    (size: const Size(390, 844), textScale: 2.0),
  ]) {
    testWidgets('layout has no overflow at ${configuration.size} and '
        '${configuration.textScale}x text', (tester) async {
      tester.view.physicalSize = configuration.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: configuration.size,
            textScaler: TextScaler.linear(configuration.textScale),
          ),
          child: board(FakeSpeechService()),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byKey(const Key('choice-finished')),
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('communication-grid')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('choice-finished')), findsOneWidget);
    });
  }
}
