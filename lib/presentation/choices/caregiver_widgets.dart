import 'package:flutter/material.dart';

import '../care_bridge_theme.dart';
import '../caregiver_route.dart';

/// Heading-sized text for caregiver screens, larger on tablets.
TextStyle caregiverTitleStyle(BuildContext context) {
  final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
  return TextStyle(
    color: CareBridgePalette.of(context).ink,
    fontSize: isTablet ? 28 : 24,
    fontWeight: FontWeight.w800,
  );
}

TextStyle caregiverBodyStyle(BuildContext context) =>
    TextStyle(color: CareBridgePalette.of(context).ink, fontSize: 18);

/// A full-width button at least 72 points tall. [filled] marks the main
/// action of a screen.
class CaregiverButton extends StatelessWidget {
  const CaregiverButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
    super.key,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final palette = CareBridgePalette.of(context);
    final textStyle = caregiverTitleStyle(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );
    const padding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    if (filled) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(72),
          padding: padding,
          backgroundColor: palette.selectedSurface,
          foregroundColor: palette.onSelectedSurface,
          textStyle: textStyle,
          shape: shape,
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 32),
        label: Text(label),
      );
    }
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(72),
        alignment: AlignmentDirectional.centerStart,
        padding: padding,
        backgroundColor: palette.surface,
        foregroundColor: palette.ink,
        textStyle: textStyle,
        side: BorderSide(
          color: palette.outline,
          width: palette.isHighContrast ? 3 : 2,
        ),
        shape: shape,
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 36),
      label: Text(label),
    );
  }
}

/// A message announced by screen readers when it appears or changes.
class CaregiverStatus extends StatelessWidget {
  const CaregiverStatus({
    required this.message,
    required this.isProblem,
    super.key,
  });
  final String message;
  final bool isProblem;

  @override
  Widget build(BuildContext context) {
    final palette = CareBridgePalette.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isProblem ? Icons.error_rounded : Icons.check_circle_rounded,
              color: palette.ink,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks before something that cannot be undone. Resolves to true only when
/// the caregiver picks [confirmLabel]; dismissing keeps everything as it is.
Future<bool> confirmCaregiverAction(
  BuildContext context, {
  required Key dialogKey,
  required String title,
  required String message,
  required String cancelLabel,
  required String confirmLabel,
  required Key cancelKey,
  required Key confirmKey,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    animationStyle: caregiverDialogAnimation(context),
    builder: (context) {
      final palette = CareBridgePalette.of(context);
      final titleStyle = caregiverTitleStyle(context);
      final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      );
      return MediaQuery.withClampedTextScaling(
        maxScaleFactor: 2,
        child: AlertDialog(
          key: dialogKey,
          scrollable: true,
          backgroundColor: palette.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: palette.outline,
              width: palette.isHighContrast ? 3 : 2,
            ),
          ),
          title: Text(title, style: titleStyle),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: TextStyle(color: palette.ink, fontSize: 20)),
              const SizedBox(height: 24),
              // The safe choice comes first.
              OutlinedButton(
                key: cancelKey,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(72),
                  foregroundColor: palette.ink,
                  backgroundColor: palette.surface,
                  textStyle: titleStyle,
                  side: BorderSide(color: palette.outline, width: 2),
                  shape: shape,
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelLabel),
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: confirmKey,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(72),
                  backgroundColor: palette.selectedSurface,
                  foregroundColor: palette.onSelectedSurface,
                  textStyle: titleStyle,
                  shape: shape,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ),
      );
    },
  );
  return confirmed ?? false;
}

/// A caregiver screen: clamped text scaling, a large title, a centered,
/// width-limited list that scrolls, and an optional [status] fixed below
/// it. The status is always on screen, so it is seen and announced however
/// far the list is scrolled, and it appearing never moves the list.
class CaregiverScaffold extends StatelessWidget {
  const CaregiverScaffold({
    required this.title,
    required this.children,
    this.listKey,
    this.status,
    super.key,
  });
  final String title;
  final List<Widget> children;
  final Key? listKey;
  final Widget? status;

  @override
  Widget build(BuildContext context) {
    final palette = CareBridgePalette.of(context);
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    // Text here starts at 18 to 28 logical pixels, so the system text size
    // is honored up to twice that, as in settings.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 2,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            toolbarHeight: 72,
            backgroundColor: palette.background,
            foregroundColor: palette.ink,
            title: Text(title, style: caregiverTitleStyle(context)),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  key: listKey,
                  padding: EdgeInsets.all(isTablet ? 24 : 16),
                  children: children,
                ),
              ),
            ),
          ),
          bottomNavigationBar: switch (status) {
            final status? => DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surface,
                border: Border(
                  top: BorderSide(
                    color: palette.outline,
                    width: palette.isHighContrast ? 3 : 2,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding: EdgeInsets.all(isTablet ? 24 : 16),
                      child: status,
                    ),
                  ),
                ),
              ),
            ),
            null => null,
          },
        ),
      ),
    );
  }
}

/// Leaves every caregiver screen and shows the board again.
void goBackToBoard(BuildContext context) =>
    Navigator.of(context).popUntil((route) => route.isFirst);
