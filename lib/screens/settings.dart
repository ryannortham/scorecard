import 'package:flutter/material.dart';

// DEPRECATED: Settings screen functionality has been moved to the drawer
// This file is kept for backward compatibility but should not be used
// All settings are now accessible through the app drawer

@Deprecated(
    'Settings screen has been deprecated. Use AppDrawer for settings access.')
class Settings extends StatelessWidget {
  const Settings({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64),
            SizedBox(height: 16),
            Text(
              'Settings Moved',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Settings are now available in the app drawer.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Tap the menu icon (☰) to access all settings.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
