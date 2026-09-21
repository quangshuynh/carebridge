import 'dart:async';

import 'package:carebridge/application/communication_board_controller.dart';
import 'package:carebridge/domain/communication_models.dart';
import 'package:carebridge/domain/sample_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_speech_service.dart';

void main() {
  test('disabled choices cannot communicate', () async {
    final speech = FakeSpeechService();
    final controller = CommunicationBoardController(speechService: speech);
    const disabled = CommunicationChoice(
      id: 'disabled',
      label: 'Disabled',
      spokenPhrase: 'Do not say this.',
      visual: ChoiceVisual.icon(Icons.block, backgroundColor: Colors.white),
      order: 0,
      isEnabled: false,
    );

    expect(await controller.activate(disabled), isFalse);
    expect(controller.selectedChoice, isNull);
    expect(controller.sessionEvents, isEmpty);
    expect(speech.spokenPhrases, isEmpty);
  });

  test(
    'activation selects, speaks, and records the configured phrase',
    () async {
      final speech = FakeSpeechService();
      final time = DateTime.utc(2026, 9, 20);
      final controller = CommunicationBoardController(
        speechService: speech,
        now: () => time,
      );
      final drive = sampleCommunicator.enabledChoices.singleWhere(
        (choice) => choice.id == 'drive',
      );
      expect(await controller.activate(drive), isTrue);
      expect(controller.selectedChoice, drive);
      expect(speech.spokenPhrases, ['I want to go for a drive.']);
      expect(controller.sessionEvents.single.choiceId, 'drive');
      expect(controller.sessionEvents.single.occurredAt, time);
    },
  );

  test('rapid duplicate actions are ignored while speech is pending', () async {
    final speech = FakeSpeechService()..pendingSpeech = Completer<void>();
    final controller = CommunicationBoardController(speechService: speech);
    final drive = sampleCommunicator.enabledChoices.singleWhere(
      (choice) => choice.id == 'drive',
    );
    final first = controller.activate(drive);
    expect(await controller.activate(drive), isFalse);
    expect(speech.spokenPhrases, hasLength(1));
    expect(controller.sessionEvents, hasLength(1));
    speech.pendingSpeech!.complete();
    expect(await first, isTrue);
  });
}
