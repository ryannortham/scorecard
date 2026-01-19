import 'package:flutter/material.dart';

import 'package:scorecard/widgets/atmospheric_background.dart';

/// Unified scaffold wrapper providing consistent background and structure
/// across all screens in the application.
///
/// This widget encapsulates the atmospheric background and scaffold
/// configuration to eliminate code duplication across screen files.
class AppScaffold extends StatelessWidget {
  /// The main content of the scaffold.
  final Widget body;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  /// Position of the floating action button.
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Whether the body should extend behind the bottom system UI.
  final bool extendBody;

  /// Whether the body should extend behind the app bar.
  final bool extendBodyBehindAppBar;

  const AppScaffold({
    super.key,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: Stack(children: [const AtmosphericBackground(), body]),
    );
  }
}
