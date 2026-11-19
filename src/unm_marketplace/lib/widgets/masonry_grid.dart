import 'package:flutter/material.dart';

/// Pinterest-style columns: each item goes into the currently shortest column.
/// [heightOf] estimates an item's relative height so columns stay balanced.
class MasonryGrid<T> extends StatelessWidget {
  const MasonryGrid({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.heightOf,
    this.spacing = 16,
  });

  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final double Function(T) heightOf;
  final double spacing;

  static int columnsFor(double width) => width < 560 ? 2 : width < 860 ? 3 : width < 1180 ? 4 : 5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final n = columnsFor(c.maxWidth);
      final cols = List.generate(n, (_) => <Widget>[]);
      final heights = List.filled(n, 0.0);
      for (final (i, item) in items.indexed) {
        var shortest = 0;
        for (var k = 1; k < n; k++) {
          if (heights[k] < heights[shortest]) shortest = k;
        }
        if (cols[shortest].isNotEmpty) cols[shortest].add(SizedBox(height: spacing));
        cols[shortest].add(itemBuilder(context, item, i));
        heights[shortest] += heightOf(item);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final (k, col) in cols.indexed) ...[
          if (k > 0) SizedBox(width: spacing),
          Expanded(child: Column(children: col)),
        ],
      ]);
    });
  }
}
