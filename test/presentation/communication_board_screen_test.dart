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
    expect(speech.spokenPhrases, ['I want to go for a drive.']);
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
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });
  for (final size in [const Size(390, 844), const Size(1024, 768)]) {
    testWidgets('layout has no overflow at ${size.width}x${size.height}', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(board(FakeSpeechService()));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('choice-finished')), findsOneWidget);
    });
  }
}
