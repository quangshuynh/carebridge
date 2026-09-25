import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/communication_models.dart';
import '../care_bridge_theme.dart';
import 'fitted_text.dart';

/// Persistent answer to "what did I just communicate?": the selected
/// choice's visual beside its configured phrase.
///
/// It occupies a fixed area chosen by the board, never an overlay, so a new
/// phrase cannot resize it and move the choices under a finger.
class CommunicationConfirmation extends StatelessWidget {
  const CommunicationConfirmation({
    required this.choice,
    required this.direction,
    super.key,
  });
  final CommunicationChoice? choice;

  /// [Axis.horizontal] for a banner above the board, [Axis.vertical] for a
  /// panel beside it.
  final Axis direction;

  static const idlePhrase = 'Choose what you want to say';

  @override
  Widget build(BuildContext context) {
    final selected = choice;
    final phrase = selected?.spokenPhrase ?? idlePhrase;
    final isHorizontal = direction == Axis.horizontal;
    return Semantics(
      container: true,
      liveRegion: selected != null,
      label: selected == null ? phrase : 'Selected. $phrase',
      excludeSemantics: true,
      child: AnimatedContainer(
        key: const Key('confirmation-banner'),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected == null
              ? CareBridgeColors.surface
              : CareBridgeColors.brand,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CareBridgeColors.brand, width: 2),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final visualSize = isHorizontal
                ? math.min(constraints.maxHeight, 96.0)
                : math.min(constraints.maxWidth * 0.6, 120.0);
            // The phrase grows with the space given to it, so tablets show
            // it as prominently as the choice labels.
            final phraseSize = isHorizontal
                ? (constraints.maxHeight * 0.4).clamp(22.0, 40.0)
                : (constraints.maxWidth * 0.14).clamp(22.0, 34.0);
            final text = FittedText(
              phrase,
              key: const Key('confirmation-phrase'),
              maxLines: isHorizontal ? 3 : 5,
              minFontSize: 16,
              textAlign: isHorizontal ? TextAlign.start : TextAlign.center,
              style: TextStyle(
                color: selected == null
                    ? CareBridgeColors.ink
                    : CareBridgeColors.surface,
                fontSize: selected == null ? phraseSize * 0.85 : phraseSize,
                fontWeight: selected == null
                    ? FontWeight.w600
                    : FontWeight.w800,
                height: 1.15,
              ),
            );
            final visual = _ConfirmationVisual(
              choice: selected,
              size: visualSize,
            );
            return isHorizontal
                ? Row(
                    children: [
                      visual,
                      const SizedBox(width: 16),
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: text,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      visual,
                      const SizedBox(height: 12),
                      Expanded(
                        child: Align(alignment: Alignment.center, child: text),
                      ),
                    ],
                  );
          },
        ),
      ),
    );
  }
}

class _ConfirmationVisual extends StatelessWidget {
  const _ConfirmationVisual({required this.choice, required this.size});
  final CommunicationChoice? choice;
  final double size;

  @override
  Widget build(BuildContext context) {
    final selected = choice;
    return Container(
      key: const Key('confirmation-visual'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected?.visual.backgroundColor ?? CareBridgeColors.idleVisual,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Icon(
        selected?.visual.icon ?? Icons.touch_app_rounded,
        color: CareBridgeColors.outline,
        size: size * 0.66,
      ),
    );
  }
}
