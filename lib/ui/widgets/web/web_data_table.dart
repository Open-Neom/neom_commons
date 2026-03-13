import 'package:flutter/material.dart';

import 'web_hover_card.dart';

class WebTableColumn<T> {
  final String label;
  final double? width;
  final Widget Function(T item) cellBuilder;
  final Comparable Function(T item)? sortKey;

  const WebTableColumn({
    required this.label,
    this.width,
    required this.cellBuilder,
    this.sortKey,
  });
}

class WebDataTable<T> extends StatefulWidget {

  final List<T> items;
  final List<WebTableColumn<T>> columns;
  final void Function(T item)? onRowTap;
  final void Function(T item, TapDownDetails details)? onRowSecondaryTap;
  final String? Function(T item)? onSort;

  const WebDataTable({
    super.key,
    required this.items,
    required this.columns,
    this.onRowTap,
    this.onRowSecondaryTap,
    this.onSort,
  });

  @override
  State<WebDataTable<T>> createState() => _WebDataTableState<T>();
}

class _WebDataTableState<T> extends State<WebDataTable<T>> {

  int? _sortColumnIndex;
  bool _sortAscending = true;

  List<T> get _sortedItems {
    if (_sortColumnIndex == null) return widget.items;
    final col = widget.columns[_sortColumnIndex!];
    if (col.sortKey == null) return widget.items;
    final sorted = List<T>.from(widget.items)
      ..sort((a, b) {
        final aKey = col.sortKey!(a);
        final bKey = col.sortKey!(b);
        return _sortAscending
            ? Comparable.compare(aKey, bKey)
            : Comparable.compare(bKey, aKey);
      });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final items = _sortedItems;

    return Column(
      children: [
        _buildHeader(),
        const Divider(height: 1, color: Color(0x26FFFFFF)),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) => _buildRow(items[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: widget.columns.asMap().entries.map((entry) {
          final i = entry.key;
          final col = entry.value;
          final isSorted = _sortColumnIndex == i;

          Widget header = Text(
            col.label,
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          );

          if (col.sortKey != null) {
            header = GestureDetector(
              onTap: () => setState(() {
                if (_sortColumnIndex == i) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortColumnIndex = i;
                  _sortAscending = true;
                }
              }),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    header,
                    if (isSorted)
                      Icon(
                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: Colors.white.withAlpha(180),
                      ),
                  ],
                ),
              ),
            );
          }

          return col.width != null
              ? SizedBox(width: col.width, child: header)
              : Expanded(child: header);
        }).toList(),
      ),
    );
  }

  Widget _buildRow(T item) {
    return WebHoverCard(
      borderRadius: BorderRadius.circular(6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: widget.onRowTap != null ? () => widget.onRowTap!(item) : null,
      onSecondaryTapDown: widget.onRowSecondaryTap != null
          ? (details) => widget.onRowSecondaryTap!(item, details)
          : null,
      child: Row(
        children: widget.columns.map((col) {
          final cell = col.cellBuilder(item);
          return col.width != null
              ? SizedBox(width: col.width, child: cell)
              : Expanded(child: cell);
        }).toList(),
      ),
    );
  }
}
