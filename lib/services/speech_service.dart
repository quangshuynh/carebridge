abstract interface class SpeechService {
  /// Speaks [phrase], replacing any speech already in progress or pending.
  Future<void> speak(String phrase);

  /// Stops current speech and discards any pending request.
  Future<void> stop();
}
