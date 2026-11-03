import 'package:flutter/material.dart';

/// A page for caregiver screens that appears at once, with no transition,
/// when the device asks to reduce motion.
Route<T> caregiverRoute<T>(BuildContext context, WidgetBuilder builder) {
  if (MediaQuery.disableAnimationsOf(context)) {
    return PageRouteBuilder<T>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (context, _, _) => builder(context),
    );
  }
  return MaterialPageRoute<T>(builder: builder);
}

/// The dialog animation to use, none when the device reduces motion.
AnimationStyle? caregiverDialogAnimation(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ? AnimationStyle.noAnimation : null;
