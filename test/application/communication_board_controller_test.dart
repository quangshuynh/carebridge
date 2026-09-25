import 'dart:async';

import 'package:carebridge/application/communication_board_controller.dart';
import 'package:carebridge/domain/communication_models.dart';
import 'package:carebridge/domain/sample_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_speech_service.dart';
import '../support/fake_tactile_feedback.dart';

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

  test(
    'rapid same-choice actions create one event and one speech call',
    () async {
      var time = DateTime.utc(2026, 9, 20);
      final speech = FakeSpeechService()..pendingSpeech = Completer<void>();
      final controller = CommunicationBoardController(
        speechService: speech,
        now: () => time,
      );
      final drive = sampleCommunicator.enabledChoices.singleWhere(
        (choice) => choice.id == 'drive',
      );
      final first = controller.activate(drive);
      expect(await controller.activate(drive), isFalse);
      expect(speech.spokenPhrases, hasLength(1));
      expect(controller.sessionEvents, hasLength(1));
      speech.pendingSpeech!.complete();
      expect(await first, isTrue);

      time = time.add(const Duration(milliseconds: 600));
      expect(await controller.activate(drive), isTrue);
      expect(speech.spokenPhrases, hasLength(2));
      expect(controller.sessionEvents, hasLength(2));
    },
  );

  test(
    'a different choice is accepted while earlier speech is pending',
    () async {
      final speech = FakeSpeechService()..pendingSpeech = Completer<void>();
      final controller = CommunicationBoardController(speechService: speech);
      final drive = sampleCommunicator.enabledChoices.singleWhere(
        (choice) => choice.id == 'drive',
      );
      final help = sampleCommunicator.enabledChoices.singleWhere(
        (choice) => choice.id == 'help',
      );

      final first = controller.activate(drive);
      final second = controller.activate(help);

      expect(controller.selectedChoice, help);
      expect(controller.sessionEvents.map((event) => event.choiceId), [
        'drive',
        'help',
      ]);
      expect(speech.spokenPhrases, [
        'I want to go for a drive.',
        'I need help.',
      ]);
      speech.pendingSpeech!.complete();
      expect(await first, isTrue);
      expect(await second, isTrue);
    },
  );

  test('speech failure does not undo visual or event communication', () async {
    final speech = FakeSpeechService()..error = StateError('voice unavailable');
    final controller = CommunicationBoardController(speechService: speech);
    final help = sampleCommunicator.enabledChoices.singleWhere(
      (choice) => choice.id == 'help',
    );

    expect(await controller.activate(help), isTrue);
    expect(controller.selectedChoice, help);
    expect(controller.sessionEvents.single.choiceId, 'help');
  });

  CommunicationChoice choiceWithId(String id) => sampleCommunicator
      .enabledChoices
      .singleWhere((choice) => choice.id == id);

  test('accepted activation gives one tactile acknowledgment', () async {
    var time = DateTime.utc(2026, 9, 20);
    final haptics = FakeTactileFeedback();
    final controller = CommunicationBoardController(
      speechService: FakeSpeechService(),
      tactileFeedback: haptics,
      now: () => time,
    );

    expect(await controller.activate(choiceWithId('food')), isTrue);
    expect(haptics.acknowledgements, 1);

    time = time.add(const Duration(milliseconds: 100));
    expect(await controller.activate(choiceWithId('food')), isFalse);
    expect(haptics.acknowledgements, 1, reason: 'ignored duplicate');

    expect(await controller.activate(choiceWithId('drink')), isTrue);
    expect(haptics.acknowledgements, 2);
  });

  for (final synchronous in [true, false]) {
    test('tactile failure (${synchronous ? 'sync' : 'async'}) never '
        'affects communication or speech', () async {
      final speech = FakeSpeechService();
      final haptics = FakeTactileFeedback()
        ..error = StateError('no vibrator')
        ..throwSynchronously = synchronous;
      final controller = CommunicationBoardController(
        speechService: speech,
        tactileFeedback: haptics,
      );

      expect(await controller.activate(choiceWithId('help')), isTrue);
      expect(controller.selectedChoice?.id, 'help');
      expect(controller.sessionEvents.single.choiceId, 'help');
      expect(speech.spokenPhrases, ['I need help.']);
    });
  }

  test('stopping speech keeps the communicated choice', () async {
    final speech = FakeSpeechService();
    final controller = CommunicationBoardController(speechService: speech);
    await controller.activate(choiceWithId('rest'));

    speech.error = StateError('engine gone');
    await controller.stopSpeech();

    expect(speech.stopCount, 1);
    expect(controller.selectedChoice?.id, 'rest');
    expect(controller.sessionEvents, hasLength(1));
  });

  test('a disposed controller ignores activation', () async {
    final speech = FakeSpeechService();
    final controller = CommunicationBoardController(speechService: speech)
      ..dispose();

    expect(await controller.activate(choiceWithId('food')), isFalse);
    expect(speech.spokenPhrases, isEmpty);
    expect(controller.sessionEvents, isEmpty);
  });
}
