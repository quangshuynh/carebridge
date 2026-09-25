import 'dart:async';

import 'package:carebridge/infrastructure/flutter_tts_speech_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Records the plugin calls CareBridge makes; nothing reaches a platform.
class _RecordingTts implements FlutterTts {
  final calls = <String>[];
  Completer<void>? pendingLanguage;
  bool failConfiguration = false;

  @override
  Future<dynamic> setLanguage(String language) async {
    calls.add('setLanguage $language');
    await pendingLanguage?.future;
    if (failConfiguration) throw StateError('no en-US voice');
  }

  @override
  Future<dynamic> setSpeechRate(double rate) async {
    calls.add('setSpeechRate');
    if (failConfiguration) throw StateError('rate');
  }

  @override
  Future<dynamic> setIosAudioCategory(
    IosTextToSpeechAudioCategory category,
    List<IosTextToSpeechAudioCategoryOptions> options, [
    IosTextToSpeechAudioMode mode = IosTextToSpeechAudioMode.defaultMode,
  ]) async {
    calls.add('setIosAudioCategory ${category.name}');
  }

  @override
  Future<dynamic> stop() async => calls.add('stop');

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async =>
      calls.add('speak $text');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('configures once, then stops before each new phrase', () async {
    final tts = _RecordingTts();
    final service = FlutterTtsSpeechService(flutterTts: tts);

    await service.speak('I need help.');
    await service.speak('I am finished.');

    expect(tts.calls, [
      'setLanguage en-US',
      'setSpeechRate',
      'setIosAudioCategory playback',
      'stop',
      'speak I need help.',
      'stop',
      'speak I am finished.',
    ]);
  });

  test('a phrase superseded before it starts is never spoken', () async {
    final tts = _RecordingTts()..pendingLanguage = Completer<void>();
    final service = FlutterTtsSpeechService(flutterTts: tts);

    final first = service.speak('I would like a drink.');
    final second = service.speak('I need help.');
    tts.pendingLanguage!.complete();
    await Future.wait([first, second]);

    expect(tts.calls.where((call) => call.startsWith('speak')), [
      'speak I need help.',
    ]);
  });

  test('stop discards speech that has not started yet', () async {
    final tts = _RecordingTts()..pendingLanguage = Completer<void>();
    final service = FlutterTtsSpeechService(flutterTts: tts);

    final pending = service.speak('I want to go for a drive.');
    await service.stop();
    tts.pendingLanguage!.complete();
    await pending;

    expect(tts.calls.where((call) => call.startsWith('speak')), isEmpty);
  });

  test('failed voice configuration still speaks with the default', () async {
    final tts = _RecordingTts()..failConfiguration = true;
    final service = FlutterTtsSpeechService(flutterTts: tts);

    await service.speak('I need to rest.');

    expect(tts.calls.last, 'speak I need to rest.');
  });
}
