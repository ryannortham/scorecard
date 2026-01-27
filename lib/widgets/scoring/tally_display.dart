// widget that displays tally icons for numeric values

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/providers/preferences_provider.dart';
import 'package:scorecard/services/asset_service.dart';
import 'package:scorecard/theme/colors.dart';

/// displays tally icons for a given numeric value, with optional text fallback
class TallyDisplay extends StatelessWidget {
  const TallyDisplay({
    required this.value,
    super.key,
    this.iconSize,
    this.color,
    this.textStyle,
    this.useTally = true,
  });

  /// threshold above which to display numbers as text instead of tally icons
  static const int _textDisplayThreshold = 10;

  final int value;
  final double? iconSize;
  final Color? color;
  final TextStyle? textStyle;
  final bool useTally;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = color ?? context.colors.onSurface;
    final effectiveColor = ColorService.semiTransparent(baseColor, 0.9);
    final effectiveIconSize = iconSize ?? 24.0;

    // Get the user preference for using tallys
    final userPreferences = Provider.of<UserPreferencesProvider>(context);
    final shouldUseTally = useTally && userPreferences.useTallys;

    // Handle zero or negative values - show nothing (blank)
    if (value <= 0) {
      return const SizedBox.shrink();
    }

    // Show number as text if shouldUseTally is false or value above threshold
    if (!shouldUseTally || value > _textDisplayThreshold) {
      return Align(
        child: _buildTextDisplay(theme, effectiveColor),
      );
    }

    // tally icons are left-aligned with padding
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _buildTallyIconDisplay(
          theme,
          effectiveColor,
          effectiveIconSize,
        ),
      ),
    );
  }

  /// builds the text display for large values or when useTally is false
  Widget _buildTextDisplay(ThemeData theme, Color effectiveColor) {
    final effectiveTextStyle =
        textStyle ??
        theme.textTheme.bodyMedium?.copyWith(color: effectiveColor) ??
        TextStyle(color: effectiveColor);

    return Text(value.toString(), style: effectiveTextStyle);
  }

  /// builds the tally icon display for smaller values
  Widget _buildTallyIconDisplay(
    ThemeData theme,
    Color effectiveColor,
    double effectiveIconSize,
  ) {
    final tallyIcons = AssetService.getTallyIconPaths(value);

    if (tallyIcons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 2, // Add small spacing between icons
      children:
          tallyIcons
              .map(
                (iconPath) => _buildTallyIcon(
                  iconPath,
                  effectiveColor,
                  effectiveIconSize,
                ),
              )
              .toList(),
    );
  }

  /// builds a single tally icon
  Widget _buildTallyIcon(
    String iconPath,
    Color effectiveColor,
    double effectiveIconSize,
  ) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
      child: Image.asset(
        iconPath,
        width: effectiveIconSize,
        height: effectiveIconSize,
      ),
    );
  }
}
