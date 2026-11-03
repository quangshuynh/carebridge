import 'package:flutter/foundation.dart';

/// How the board is drawn for the person using it. Kept on the device only.
@immutable
class DisplayPreferences {
  const DisplayPreferences({this.highContrast = false});

  /// The default for a first launch, or when nothing could be read.
  static const standard = DisplayPreferences();

  /// Black text, icons, and borders on light surfaces, with heavier outlines.
  final bool highContrast;

  DisplayPreferences copyWith({bool? highContrast}) =>
      DisplayPreferences(highContrast: highContrast ?? this.highContrast);

  @override
  bool operator ==(Object other) =>
      other is DisplayPreferences && other.highContrast == highContrast;

  @override
  int get hashCode => highContrast.hashCode;
}
