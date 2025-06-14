import 'package:flutter/material.dart';

/// A Material 3 compliant bottom sheet for confirmation actions
/// Using the Material BottomSheet class directly
class ConfirmationBottomSheet extends StatefulWidget {
  final String actionText;
  final IconData actionIcon;
  final VoidCallback onConfirm;

  const ConfirmationBottomSheet({
    super.key,
    required this.actionText,
    required this.actionIcon,
    required this.onConfirm,
  });

  /// Show the confirmation bottom sheet
  static Future<bool> show({
    required BuildContext context,
    required String actionText,
    required IconData actionIcon,
    required VoidCallback onConfirm,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConfirmationBottomSheet(
        actionText: actionText,
        actionIcon: actionIcon,
        onConfirm: onConfirm,
      ),
    );
    return result ?? false;
  }

  @override
  State<ConfirmationBottomSheet> createState() =>
      _ConfirmationBottomSheetState();
}

class _ConfirmationBottomSheetState extends State<ConfirmationBottomSheet>
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Action button with leading icon
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop(true);
                widget.onConfirm();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                overlayColor: Colors.transparent,
                side: BorderSide.none,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: Icon(widget.actionIcon),
              label: Text(widget.actionText),
            ),
          ],
        ),
      ),
    );
  }
}
