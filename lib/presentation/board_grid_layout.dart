import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Grid geometry that shows every choice at once, as large as the space
/// allows, so targets stay put instead of scrolling under a finger.
@immutable
class BoardGridLayout {
  const BoardGridLayout._({
    required this.columns,
    required this.rows,
    required this.cellSize,
    required this.scrolls,
  });

  /// Picks the column count that gives the largest cells for [itemCount]
  /// choices in [area]. Only when even the best cells would be smaller than
  /// [minCellExtent] does the grid keep that minimum size and scroll.
  factory BoardGridLayout.resolve({
    required int itemCount,
    required Size area,
    required double spacing,
    required double minCellExtent,
  }) {
    if (itemCount <= 0) {
      return BoardGridLayout._(
        columns: 1,
        rows: 0,
        cellSize: Size.zero,
        scrolls: false,
      );
    }
    var bestColumns = 1;
    var bestSize = Size.zero;
    for (var columns = 1; columns <= itemCount; columns++) {
      final rows = (itemCount / columns).ceil();
      final size = Size(
        (area.width - spacing * (columns - 1)) / columns,
        (area.height - spacing * (rows - 1)) / rows,
      );
      // Strictly larger only: among equals, fewer columns leave fewer gaps.
      if (size.shortestSide > bestSize.shortestSide + 0.5) {
        bestColumns = columns;
        bestSize = size;
      }
    }
    if (bestSize.shortestSide >= minCellExtent) {
      return BoardGridLayout._(
        columns: bestColumns,
        rows: (itemCount / bestColumns).ceil(),
        cellSize: bestSize,
        scrolls: false,
      );
    }
    final columns = math.max(
      1,
      math.min(
        bestColumns,
        ((area.width + spacing) / (minCellExtent + spacing)).floor(),
      ),
    );
    final width = (area.width - spacing * (columns - 1)) / columns;
    return BoardGridLayout._(
      columns: columns,
      rows: (itemCount / columns).ceil(),
      cellSize: Size(width, minCellExtent),
      scrolls: true,
    );
  }

  final int columns;
  final int rows;
  final Size cellSize;
  final bool scrolls;
}
