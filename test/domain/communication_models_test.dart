import 'package:carebridge/domain/communication_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'enabledChoices filters disabled choices and preserves configured order',
    () {
      const profile = CommunicatorProfile(
        id: 'p',
        displayName: 'Board',
        categories: [
          CommunicationCategory(
            id: 'c',
            label: 'Category',
            order: 0,
            choices: [
              CommunicationChoice(
                id: 'second',
                label: 'Second',
                spokenPhrase: 'Second',
                visual: ChoiceVisual.icon(
                  Icons.looks_two,
                  backgroundColor: Colors.white,
                ),
                order: 2,
              ),
              CommunicationChoice(
                id: 'disabled',
                label: 'Disabled',
                spokenPhrase: 'Disabled',
                visual: ChoiceVisual.icon(
                  Icons.block,
                  backgroundColor: Colors.white,
                ),
                order: 0,
                isEnabled: false,
              ),
              CommunicationChoice(
                id: 'first',
                label: 'First',
                spokenPhrase: 'First',
                visual: ChoiceVisual.icon(
                  Icons.looks_one,
                  backgroundColor: Colors.white,
                ),
                order: 1,
              ),
            ],
          ),
        ],
      );
      expect(profile.enabledChoices.map((choice) => choice.id), [
        'first',
        'second',
      ]);
    },
  );
}
