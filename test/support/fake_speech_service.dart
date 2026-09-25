import 'dart:async';

import 'package:carebridge/services/speech_service.dart';

class FakeSpeechService implements SpeechService {
  final List<String> spokenPhrases = [];
  Completer<void>? pendingSpeech;
  Object? error;
  int stopCount = 0;
  @override
  Future<void> speak(String phrase) {
    spokenPhrases.add(phrase);
    if (error != null) return Future.error(error!);
    return pendingSpeech?.future ?? Future.value();
  }

  @override
  Future<void> stop() async {
    stopCount++;
    if (error != null) throw error!;
  }
}
