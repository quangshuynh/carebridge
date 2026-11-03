import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../care_bridge_theme.dart';

/// Opens settings only after a deliberate one-second hold, so a tap or a
/// resting hand on the board cannot leave it. Screen readers open it with
/// their own long-press action.
class SettingsHoldButton extends StatelessWidget {
  const SettingsHoldButton({required this.onOpen, super.key});
  final VoidCallback onOpen;

  static const holdDuration = Duration(seconds: 1);
  static const size = 56.0;

  @override
  Widget build(BuildContext context) {
    final palette = CareBridgePalette.of(context);
    return Semantics(
      button: true,
      label: 'Settings',
      onLongPress: onOpen,
      onLongPressHint: 'open settings',
      excludeSemantics: true,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          LongPressGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                () => LongPressGestureRecognizer(duration: holdDuration),
                (recognizer) => recognizer.onLongPress = onOpen,
              ),
        },
        child: Container(
          key: const Key('settings-button'),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: palette.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: palette.isHighContrast
                  ? palette.outline
                  : palette.idleBorder,
              width: palette.idleBorderWidth,
            ),
          ),
          child: Icon(
            Icons.settings_rounded,
            color: palette.outline,
            size: size * 0.55,
          ),
        ),
      ),
    );
  }
}
