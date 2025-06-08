import 'package:flutter/material.dart';

/// A reusable button widget with consistent styling across the app
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;
  final IconData? icon;
  final bool isElevated;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
    this.icon,
    this.isElevated = true,
  });

  const CustomButton.outlined({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
    this.icon,
  }) : isElevated = false;

  @override
  Widget build(BuildContext context) {
    final button = icon != null
        ? (isElevated
            ? ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(text),
              )
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(text),
              ))
        : (isElevated
            ? ElevatedButton(
                onPressed: onPressed,
                child: Text(text),
              )
            : OutlinedButton(
                onPressed: onPressed,
                child: Text(text),
              ));

    return width != null
        ? SizedBox(
            width: width,
            child: button,
          )
        : button;
  }
}
