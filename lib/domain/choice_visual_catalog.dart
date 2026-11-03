import 'package:flutter/material.dart';

/// A picture a caregiver can give a choice. [name] describes the picture
/// itself, never what it means, so screen readers can announce it.
@immutable
class ChoiceIconOption {
  const ChoiceIconOption(this.id, this.name, this.icon);

  /// Stored in saved boards and backups; never changes once released.
  final String id;
  final String name;
  final IconData icon;
}

/// A background color a caregiver can give a choice. Every color is light
/// enough for the board's dark text and icons in both display modes.
@immutable
class ChoiceColorOption {
  const ChoiceColorOption(this.id, this.name, this.color);

  /// Stored in saved boards and backups; never changes once released.
  final String id;
  final String name;
  final Color color;
}

/// The built-in pictures and colors for choices. They ship with the app
/// (Material Symbols, Apache 2.0), so customization needs no files, network,
/// or permission. Ids are part of the saved format: add new ones, but never
/// rename or remove one.
abstract final class ChoiceVisualCatalog {
  static const icons = <ChoiceIconOption>[
    ChoiceIconOption('food', 'Fork and knife', Icons.restaurant_rounded),
    ChoiceIconOption('drink', 'Cup', Icons.local_drink_rounded),
    ChoiceIconOption('car', 'Car', Icons.directions_car_rounded),
    ChoiceIconOption('hand', 'Raised hand', Icons.front_hand_rounded),
    ChoiceIconOption('bed', 'Bed', Icons.hotel_rounded),
    ChoiceIconOption('flag', 'Finish flag', Icons.sports_score_rounded),
    ChoiceIconOption('toilet', 'Toilet sign', Icons.wc_rounded),
    ChoiceIconOption('bath', 'Bathtub', Icons.bathtub_rounded),
    ChoiceIconOption('moon', 'Moon', Icons.bedtime_rounded),
    ChoiceIconOption('home', 'House', Icons.home_rounded),
    ChoiceIconOption('tree', 'Tree', Icons.park_rounded),
    ChoiceIconOption('walk', 'Person walking', Icons.directions_walk_rounded),
    ChoiceIconOption('toy', 'Toy', Icons.toys_rounded),
    ChoiceIconOption('ball', 'Ball', Icons.sports_soccer_rounded),
    ChoiceIconOption('game', 'Game controller', Icons.sports_esports_rounded),
    ChoiceIconOption('tv', 'Television', Icons.tv_rounded),
    ChoiceIconOption('tablet', 'Tablet', Icons.tablet_android_rounded),
    ChoiceIconOption('music', 'Music note', Icons.music_note_rounded),
    ChoiceIconOption('book', 'Open book', Icons.menu_book_rounded),
    ChoiceIconOption('school', 'Graduation cap', Icons.school_rounded),
    ChoiceIconOption('people', 'Two people', Icons.people_rounded),
    ChoiceIconOption('heart', 'Heart', Icons.favorite_rounded),
    ChoiceIconOption('phone', 'Phone', Icons.phone_rounded),
    ChoiceIconOption('clothes', 'Clothes hanger', Icons.checkroom_rounded),
    ChoiceIconOption('cookie', 'Cookie', Icons.cookie_rounded),
    ChoiceIconOption('pet', 'Paw print', Icons.pets_rounded),
    ChoiceIconOption('sun', 'Sun', Icons.wb_sunny_rounded),
    ChoiceIconOption('snow', 'Snowflake', Icons.ac_unit_rounded),
    ChoiceIconOption('quiet', 'Speaker turned off', Icons.volume_off_rounded),
    ChoiceIconOption('yes', 'Thumbs up', Icons.thumb_up_rounded),
    ChoiceIconOption('no', 'Thumbs down', Icons.thumb_down_rounded),
    ChoiceIconOption('plus', 'Plus sign', Icons.add_circle_rounded),
    ChoiceIconOption('stop', 'Circle with a line', Icons.block_rounded),
    ChoiceIconOption('question', 'Question mark', Icons.help_rounded),
  ];

  static const colors = <ChoiceColorOption>[
    ChoiceColorOption('orange', 'Orange', Color(0xFFFFD9A8)),
    ChoiceColorOption('blue', 'Blue', Color(0xFFBFE3F5)),
    ChoiceColorOption('green', 'Green', Color(0xFFCFE4C2)),
    ChoiceColorOption('red', 'Red', Color(0xFFFFC8C2)),
    ChoiceColorOption('purple', 'Purple', Color(0xFFDCD0F2)),
    ChoiceColorOption('gray', 'Gray', Color(0xFFD5DAD8)),
    ChoiceColorOption('yellow', 'Yellow', Color(0xFFFFF0A6)),
    ChoiceColorOption('pink', 'Pink', Color(0xFFFAD0E6)),
    ChoiceColorOption('teal', 'Teal', Color(0xFFBDEBE3)),
    ChoiceColorOption('white', 'White', Color(0xFFFFFFFF)),
  ];

  static ChoiceIconOption? iconById(String id) {
    for (final option in icons) {
      if (option.id == id) return option;
    }
    return null;
  }

  static ChoiceColorOption? colorById(String id) {
    for (final option in colors) {
      if (option.id == id) return option;
    }
    return null;
  }
}
