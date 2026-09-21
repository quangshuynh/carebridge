abstract interface class SpeechService {
  /// Speaks [phrase], replacing any speech already in progress.
  Future<void> speak(String phrase);
}
