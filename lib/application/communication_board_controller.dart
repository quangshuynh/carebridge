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
    final isRapidDuplicate =
        _lastActivatedChoiceId == choice.id &&
        _lastActivatedAt != null &&
        activatedAt.difference(_lastActivatedAt!) < duplicateActivationWindow;
    if (isRapidDuplicate) return false;

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

  /// Interrupts speech without changing what was communicated.
  Future<void> stopSpeech() async {
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
