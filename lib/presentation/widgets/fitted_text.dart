import 'package:flutter/widgets.dart';

/// Shows [text] at the user's scaled [style] size when it fits, otherwise at
/// the largest size that fits the available box without splitting a word.
///
/// Board labels and phrases are already large, so keeping them whole matters
/// more than growing them past the space they have. Text is only truncated
/// if it cannot fit even at [minFontSize].
class FittedText extends StatelessWidget {
  const FittedText(
    this.text, {
    required this.style,
    this.maxLines = 2,
    this.minFontSize = 14,
    this.textAlign = TextAlign.center,
    super.key,
  });
  final String text;
  final TextStyle style;
  final int maxLines;
  final double minFontSize;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
    final textDirection = Directionality.of(context);
    final preferredSize = MediaQuery.textScalerOf(context)
        .scale(effectiveStyle.fontSize ?? 14);
    return LayoutBuilder(
      builder: (context, constraints) {
        final fontSize = fitFontSize(
          text: text,
          style: effectiveStyle,
          preferredSize: preferredSize,
          minFontSize: minFontSize,
          maxLines: maxLines,
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
          textAlign: textAlign,
          textDirection: textDirection,
        );
        return Text(
          text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          textScaler: TextScaler.noScaling,
          style: effectiveStyle.copyWith(fontSize: fontSize),
        );
      },
    );
  }
}

@visibleForTesting
double fitFontSize({
  required String text,
  required TextStyle style,
  required double preferredSize,
  required double minFontSize,
  required int maxLines,
  required double maxWidth,
  required double maxHeight,
  TextAlign textAlign = TextAlign.center,
  TextDirection textDirection = TextDirection.ltr,
}) {
  final words = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
  bool fits(double fontSize) {
    final sized = style.copyWith(fontSize: fontSize);
    final paragraph = TextPainter(
      text: TextSpan(text: text, style: sized),
      maxLines: maxLines,
      textAlign: textAlign,
      textDirection: textDirection,
    )..layout(maxWidth: maxWidth);
    final fitsBox =
        !paragraph.didExceedMaxLines && paragraph.height <= maxHeight;
    paragraph.dispose();
    if (!fitsBox) return false;
    for (final word in words) {
      final painter = TextPainter(
        text: TextSpan(text: word, style: sized),
        maxLines: 1,
        textDirection: textDirection,
      )..layout();
      final wordFits = painter.width <= maxWidth;
      painter.dispose();
      if (!wordFits) return false;
    }
    return true;
  }

  for (var size = preferredSize; size > minFontSize; size -= 1) {
    if (fits(size)) return size;
  }
  return minFontSize;
}
