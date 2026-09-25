abstract interface class TactileFeedback {
  /// Gives a brief, supplementary acknowledgment of an accepted choice.
  Future<void> acknowledge();
}
