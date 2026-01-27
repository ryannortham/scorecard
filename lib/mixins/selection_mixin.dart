// selection mode functionality for list screens

import 'package:flutter/material.dart';

/// provides selection mode state and actions for list widgets
mixin SelectionMixin<T, W extends StatefulWidget> on State<W> {
  bool _isSelectionMode = false;
  final Set<T> _selectedItems = {};

  bool get isSelectionMode => _isSelectionMode;
  Set<T> get selectedItems => Set.unmodifiable(_selectedItems);
  int get selectedCount => _selectedItems.length;
  bool isSelected(T id) => _selectedItems.contains(id);
  bool get hasSelection => _selectedItems.isNotEmpty;

  /// enters selection mode with initial item
  void enterSelectionMode(T id) {
    setState(() {
      _isSelectionMode = true;
      _selectedItems.add(id);
    });
  }

  /// exits selection mode and clears selections
  void exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedItems.clear();
    });
  }

  /// toggles item selection, exits mode if none remain
  void toggleSelection(T id) {
    setState(() {
      if (_selectedItems.contains(id)) {
        _selectedItems.remove(id);
        if (_selectedItems.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedItems.add(id);
      }
    });
  }

  /// selects all items from the given identifiers
  void selectAll(Iterable<T> ids) {
    setState(() {
      _isSelectionMode = true;
      _selectedItems.addAll(ids);
    });
  }

  /// clears selections without exiting selection mode
  void clearSelection() {
    setState(_selectedItems.clear);
  }
}
