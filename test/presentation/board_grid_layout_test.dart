import 'package:carebridge/presentation/board_grid_layout.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BoardGridLayout resolve(Size area, {int itemCount = 6}) =>
      BoardGridLayout.resolve(
        itemCount: itemCount,
        area: area,
        spacing: 12,
        minCellExtent: 120,
      );

  test('tall areas use two columns of three rows', () {
    final layout = resolve(const Size(358, 620));
    expect((layout.columns, layout.rows, layout.scrolls), (2, 3, false));
  });

  test('wide areas use three columns of two rows', () {
    final layout = resolve(const Size(620, 330));
    expect((layout.columns, layout.rows, layout.scrolls), (3, 2, false));
  });

  test('cells exactly fill the area when everything fits', () {
    const area = Size(358, 620);
    final layout = resolve(area);
    expect(
      layout.cellSize.width * layout.columns + 12 * (layout.columns - 1),
      moreOrLessEquals(area.width),
    );
    expect(
      layout.cellSize.height * layout.rows + 12 * (layout.rows - 1),
      moreOrLessEquals(area.height),
    );
  });

  test('only scrolls, at the minimum size, when choices cannot fit', () {
    final layout = resolve(const Size(300, 200));
    expect(layout.scrolls, isTrue);
    expect(layout.cellSize.height, 120);
    expect(layout.cellSize.width, greaterThanOrEqualTo(120));
  });

  test('an empty board has no rows', () {
    expect(resolve(const Size(400, 400), itemCount: 0).rows, 0);
  });
}
