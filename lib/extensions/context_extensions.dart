// buildcontext navigation extension methods

import 'dart:async';

import 'package:flutter/material.dart';

/// navigation helper methods
extension NavigationExtension on BuildContext {
  /// pops or navigates home when back is pressed
  void handleBackPress() {
    if (Navigator.of(this).canPop()) {
      Navigator.of(this).pop();
    } else {
      // Navigate to the root route (typically the Scoring tab)
      unawaited(
        Navigator.of(this).pushNamedAndRemoveUntil('/', (route) => false),
      );
    }
  }

  /// pops if context is still mounted
  void popIfMounted() {
    if (mounted && Navigator.of(this).canPop()) {
      Navigator.of(this).pop();
    }
  }

  /// pops with result if context is still mounted
  void popWithResultIfMounted<T>(T result) {
    if (mounted && Navigator.of(this).canPop()) {
      Navigator.of(this).pop(result);
    }
  }
}
