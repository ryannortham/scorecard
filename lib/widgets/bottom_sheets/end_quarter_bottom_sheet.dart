import 'package:flutter/material.dart';

/// A Material 3 compliant bottom sheet for end quarter/game confirmation
/// Using the Material BottomSheet class directly
class EndQuarterBottomSheet extends StatefulWidget {
  final int currentQuarter;
  final bool isLastQuarter;
  final VoidCallback onConfirm;

  const EndQuarterBottomSheet({
    super.key,
    required this.currentQuarter,
    required this.isLastQuarter,
    required this.onConfirm,
  });

  /// Show the end quarter/game confirmation bottom sheet
  static Future<bool> show({
    required BuildContext context,
    required int currentQuarter,
    required bool isLastQuarter,
    required VoidCallback onConfirm,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => EndQuarterBottomSheet(
            currentQuarter: currentQuarter,
            isLastQuarter: isLastQuarter,
            onConfirm: onConfirm,
          ),
    );
    return result ?? false;
  }

  @override
  State<EndQuarterBottomSheet> createState() => _EndQuarterBottomSheetState();
}

class _EndQuarterBottomSheetState extends State<EndQuarterBottomSheet>
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
    final actionText = widget.isLastQuarter ? 'End Game' : 'Next Quarter';
    final icon =
        widget.isLastQuarter ? Icons.outlined_flag : Icons.arrow_forward;

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: Icon(icon),
                  label: Text(actionText),
                ),
              ],
            ),
          ),
    );
  }
}
