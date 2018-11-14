import 'package:flutter/material.dart';

/// The sort orders that can be applied to a sort property
enum SortOrder {
  none,
  ascending,
  descending,
}

/// A property of T that can be sorted
class SortProperty<T> {
  String name;
  Comparator<T> comparator;
  SortOrder order;

  /// Constructs this instance
  SortProperty(this.name, this.comparator, {this.order = SortOrder.none});

  /// Constructs this instance as a copy
  SortProperty.from(SortProperty<T> other)
      : name = other.name,
        comparator = other.comparator,
        order = other.order;

  /// Compares x and y according to the sort order
  int compare(T x, T y) {
    switch (order) {
      case SortOrder.ascending:
        return comparator(x, y);
      case SortOrder.descending:
        return comparator(y, x);
      default:
        return 0;
    }
  }
}

/// A property-based sorter of T
class Sort<T> {
  /// The properties of T that can be sorted
  List<SortProperty<T>> properties;

  /// Constructs this instance
  Sort(this.properties);

  /// Constructs this instance as a copy
  Sort.from(Sort<T> other)
      : properties = List<SortProperty<T>>.from(
            other.properties.map((x) => SortProperty<T>.from(x)));

  /// Generates a comparator that matches this sorting
  Comparator<T> comparator() => (x, y) {
        for (var p in properties) {
          final c = p.compare(x, y);
          if (c < 0 || c > 0) return c;
        }
        return 0;
      };
}

/// Widget for configuring a sort
/// This class is stateful because it must update as the user enters the sort
class SortDialog<T> extends StatefulWidget {
  /// Title of the dialog
  final String title;

  /// Initial sort to build on
  final Sort<T> initialSort;

  /// Sort to modify
  /// If unspecified, the initial sort is used
  final Sort<T> sort;

  /// Constructs this instance
  SortDialog({@required this.title, @required this.initialSort, this.sort});

  /// Creates the mutable state for this widget
  @override
  createState() => _SortDialogState<T>();
}

/// State for the sort dialog
class _SortDialogState<T> extends State<SortDialog<T>> {
  /// Mapping from sort order to name
  static final _sortOrders = <SortOrder, String>{
    SortOrder.none: 'None',
    SortOrder.ascending: 'Ascending',
    SortOrder.descending: 'Descending',
  };

  /// Sort being built
  Sort<T> _sort;

  /// Describes the part of the user interface represented by this widget
  @override
  Widget build(BuildContext context) => Scaffold(
      body: DropdownButtonHideUnderline(
        child: ReorderableListView(
          header: ListTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Property',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Order',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            trailing: const Icon(null),
          ),
          children: _sort.properties.map(_buildListTile).toList(),
          onReorder: _onReorder,
        ),
      ),
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => Navigator.pop(context, widget.initialSort),
          ),
          IconButton(
            icon: const Icon(Icons.done),
            onPressed: () => Navigator.pop(context, _sort),
          ),
        ],
      ));

  /// Called when this object is inserted into the tree
  @override
  void initState() {
    super.initState();

    _sort = Sort<T>.from(widget.sort ?? widget.initialSort);
  }

  /// Moves a sort property from one index to another
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _sort.properties.removeAt(oldIndex);
      _sort.properties.insert(newIndex, item);
    });
  }

  /// Builds a list tile for a sort property
  Widget _buildListTile(SortProperty property) => ListTile(
        key: Key(property.name),
        title: Row(
          children: [
            Expanded(child: Text(property.name)),
            Expanded(
              child: DropdownButton<SortOrder>(
                items: _sortOrders.entries
                    .map((e) => DropdownMenuItem<SortOrder>(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                value: property.order,
                onChanged: (value) => setState(() => property.order = value),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.drag_handle),
      );
}
