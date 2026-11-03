import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/communication_models.dart';
import '../services/speech_service.dart';
import '../services/tactile_feedback.dart';

class CommunicationBoardController extends ChangeNotifier {
  CommunicationBoardController({
    required this.speechService,
    this.tactileFeedback,
    DateTime Function()? now,
    this.duplicateActivationWindow = const Duration(milliseconds: 600),
  }) : _now = now ?? DateTime.now;
  final SpeechService speechService;
  final TactileFeedback? tactileFeedback;
  final DateTime Function() _now;
  final Duration duplicateActivationWindow;
  CommunicationChoice? _selectedChoice;
  String? _lastActivatedChoiceId;
  DateTime? _lastActivatedAt;
  bool _isDisposed = false;
  final List<CommunicationEvent> _sessionEvents = [];

  CommunicationChoice? get selectedChoice => _selectedChoice;
  List<CommunicationEvent> get sessionEvents =>
      List.unmodifiable(_sessionEvents);

  Future<bool> activate(CommunicationChoice choice) async {
    if (_isDisposed || !choice.isEnabled) return false;
    final activatedAt = _now();
    if (_isRapidDuplicate(choice, activatedAt)) return false;

    _lastActivatedChoiceId = choice.id;
    _lastActivatedAt = activatedAt;
    _selectedChoice = choice;
    _sessionEvents.add(
      CommunicationEvent(
        choiceId: choice.id,
        phrase: choice.spokenPhrase,
        occurredAt: activatedAt,
      ),
    );
    notifyListeners();
    unawaited(_acknowledge());
    try {
      await speechService.speak(choice.spokenPhrase);
    } catch (_) {
      // Speech is an enhancement. Visual communication remains successful
      // when a platform voice is unavailable or fails.
    }
    return true;
  }

  /// A repeat of the last accepted choice inside [duplicateActivationWindow]
  /// is treated as accidental. Only elapsed time counts: a clock that moved
  /// backwards (for example an automatic time correction) never blocks the
  /// choice.
  bool _isRapidDuplicate(CommunicationChoice choice, DateTime activatedAt) {
    final lastAt = _lastActivatedAt;
    if (_lastActivatedChoiceId != choice.id || lastAt == null) return false;
    final sinceLast = activatedAt.difference(lastAt);
    return !sinceLast.isNegative && sinceLast < duplicateActivationWindow;
  }

  /// Interrupts speech without changing what was communicated.
  ///
  /// Called when the board is left (the app is hidden or another screen
  /// opens). Leaving also ends the duplicate window, so the first activation
  /// after coming back is always treated as deliberate.
  Future<void> stopSpeech() async {
    _lastActivatedChoiceId = null;
    _lastActivatedAt = null;
    try {
      await speechService.stop();
    } catch (_) {}
  }

  Future<void> _acknowledge() async {
    try {
      await tactileFeedback?.acknowledge();
    } catch (_) {
      // Tactile feedback is supplementary and never affects communication.
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
