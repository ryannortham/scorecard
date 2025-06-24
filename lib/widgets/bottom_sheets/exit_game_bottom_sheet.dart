import 'package:flutter/material.dart';

/// A Material 3 compliant bottom sheet for game exit confirmation
/// Using the Material BottomSheet class directly
class ExitGameBottomSheet extends StatefulWidget {
  const ExitGameBottomSheet({super.key});

  /// Show the exit game confirmation bottom sheet
  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExitGameBottomSheet(),
    );
    return result ?? false;
  }

  @override
  State<ExitGameBottomSheet> createState() => _ExitGameBottomSheetState();
}

class _ExitGameBottomSheetState extends State<ExitGameBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = BottomSheet.createAnimationController(this);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      animationController: _animationController,
      onClosing: () {
        Navigator.of(context).pop(false);
      },
      showDragHandle: true,
      enableDrag: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      builder:
          (context) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Exit button with leading icon
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    overlayColor: Colors.transparent,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.exit_to_app_outlined),
                  label: const Text('Exit Game'),
                ),
              ],
            ),
          ),
    );
  }
}
