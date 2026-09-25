import 'package:flutter/material.dart';

import 'communication_models.dart';

const sampleCommunicator = CommunicatorProfile(
  id: 'sample-communicator',
  displayName: 'My choices',
  categories: [
    CommunicationCategory(
      id: 'everyday',
      label: 'Everyday choices',
      order: 0,
      choices: [
        CommunicationChoice(
          id: 'food',
          label: 'Food',
          spokenPhrase: 'I would like something to eat.',
          visual: ChoiceVisual.icon(
            Icons.restaurant_rounded,
            backgroundColor: Color(0xFFFFD9A8),
          ),
          order: 0,
        ),
        CommunicationChoice(
          id: 'drink',
          label: 'Drink',
          spokenPhrase: 'I would like a drink.',
          visual: ChoiceVisual.icon(
            Icons.local_drink_rounded,
            backgroundColor: Color(0xFFBFE3F5),
          ),
          order: 1,
        ),
        CommunicationChoice(
          id: 'drive',
          label: 'Drive',
          spokenPhrase: 'I want to go for a drive.',
          visual: ChoiceVisual.icon(
            Icons.directions_car_rounded,
            backgroundColor: Color(0xFFCFE4C2),
          ),
          order: 2,
        ),
        CommunicationChoice(
          id: 'help',
          label: 'Help',
          spokenPhrase: 'I need help.',
          visual: ChoiceVisual.icon(
            Icons.front_hand_rounded,
            backgroundColor: Color(0xFFFFC8C2),
          ),
          order: 3,
        ),
        CommunicationChoice(
          id: 'rest',
          label: 'Rest',
          spokenPhrase: 'I need to rest.',
          visual: ChoiceVisual.icon(
            Icons.hotel_rounded,
            backgroundColor: Color(0xFFDCD0F2),
          ),
          order: 4,
        ),
        CommunicationChoice(
          id: 'finished',
          label: 'Finished',
          spokenPhrase: 'I am finished.',
          visual: ChoiceVisual.icon(
            Icons.sports_score_rounded,
            backgroundColor: Color(0xFFD5DAD8),
          ),
          order: 5,
        ),
      ],
    ),
  ],
);
