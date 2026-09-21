import 'package:flutter/material.dart';

@immutable
class CommunicatorProfile {
  const CommunicatorProfile({
    required this.id,
    required this.displayName,
    required this.categories,
  });
  final String id;
  final String displayName;
  final List<CommunicationCategory> categories;

  List<CommunicationChoice> get enabledChoices => categories
      .where((category) => category.isEnabled)
      .expand((category) => category.orderedChoices)
      .where((choice) => choice.isEnabled)
      .toList(growable: false);
}

@immutable
class CommunicationCategory {
  const CommunicationCategory({
    required this.id,
    required this.label,
    required this.order,
    required this.choices,
    this.isEnabled = true,
  });
  final String id;
  final String label;
  final int order;
  final List<CommunicationChoice> choices;
  final bool isEnabled;

  List<CommunicationChoice> get orderedChoices =>
      [...choices]..sort((a, b) => a.order.compareTo(b.order));
}

@immutable
class CommunicationChoice {
  const CommunicationChoice({
    required this.id,
    required this.label,
    required this.spokenPhrase,
    required this.visual,
    required this.order,
    this.isEnabled = true,
  });
  final String id;
  final String label;
  final String spokenPhrase;
  final ChoiceVisual visual;
  final int order;
  final bool isEnabled;
}

@immutable
class ChoiceVisual {
  const ChoiceVisual.icon(this.icon, {required this.backgroundColor});
  final IconData icon;
  final Color backgroundColor;
}

@immutable
class CommunicationEvent {
  const CommunicationEvent({
    required this.choiceId,
    required this.phrase,
    required this.occurredAt,
  });
  final String choiceId;
  final String phrase;
  final DateTime occurredAt;
}
