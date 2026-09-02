import 'package:flutter/material.dart';

import '../utils/adaptive_layout.dart';

/// Purpose: Build one row of a multi-column list, filled left to right.
/// Inputs: `rowIndex` — the zero-based row; `columns` — tiles per row;
/// `itemCount` — total tiles in the list; `itemBuilder` — builds one tile by
/// its index in the flat list; `gap` — spacing between columns.
/// Returns: A `Row` of equally wide tiles.
/// Side effects: None.
/// Notes: Deliberately a `Row` of `Expanded` children rather than a `GridView`,
/// so the caller keeps `ListView.builder` virtualization: feed this from a
/// builder over [listRowCount] rows and the order stays left-to-right,
/// top-to-bottom. Short final rows are padded with empty cells so the
/// remaining tiles keep their width instead of stretching across the row.
Widget adaptiveTileRow({
  required int rowIndex,
  required int columns,
  required int itemCount,
  required Widget Function(int index) itemBuilder,
  double gap = listTileGap,
}) {
  final children = <Widget>[];
  for (var column = 0; column < columns; column++) {
    if (column > 0) children.add(SizedBox(width: gap));
    final index = rowIndex * columns + column;
    children.add(
      Expanded(
        child: index < itemCount ? itemBuilder(index) : const SizedBox.shrink(),
      ),
    );
  }
  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
}

/// Purpose: Build a list's children as rows, single column or multi-column.
/// Inputs: `columns`, `itemCount`, `itemBuilder`, `gap`.
/// Returns: A list of widgets ready to spread into a `ListView` or `Column`.
/// Side effects: None.
/// Notes: At one column this returns the tiles untouched, so a caller that
/// wraps its single-column tile in something else keeps its widget tree.
List<Widget> adaptiveTileRows({
  required int columns,
  required int itemCount,
  required Widget Function(int index) itemBuilder,
  double gap = listTileGap,
}) {
  if (columns <= 1) {
    return List.generate(itemCount, itemBuilder);
  }
  return List.generate(
    listRowCount(itemCount, columns),
    (rowIndex) => adaptiveTileRow(
      rowIndex: rowIndex,
      columns: columns,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      gap: gap,
    ),
  );
}
