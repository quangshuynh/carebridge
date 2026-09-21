import 'dart:async';

import 'package:carebridge/services/speech_service.dart';

class FakeSpeechService implements SpeechService {
  final List<String> spokenPhrases = [];
  Completer<void>? pendingSpeech;
  @override
  Future<void> speak(String phrase) {
    spokenPhrases.add(phrase);
    return pendingSpeech?.future ?? Future.value();
  }
}
