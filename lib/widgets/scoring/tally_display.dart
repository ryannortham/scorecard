import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/assets/asset_icon_service.dart';
import '../../services/color_service.dart';
import '../../providers/user_preferences_provider.dart';

/// A widget that displays tally icons for a given numeric value
/// Can be forced to show text instead of tally icons
class TallyDisplay extends StatelessWidget {
  /// The threshold above which to display numbers as text instead of tally icons
  static const int _textDisplayThreshold = 10;

  final int value;
  final double? iconSize;
  final Color? color;
  final TextStyle? textStyle;
  final bool useTally;

  const TallyDisplay({
    super.key,
    required this.value,
    this.iconSize,
    this.color,
    this.textStyle,
    this.useTally = true,
  });

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

    // Show number as text if shouldUseTally is false or value is above threshold
    if (!shouldUseTally || value > _textDisplayThreshold) {
      return _buildCenteredContent(_buildTextDisplay(theme, effectiveColor));
    }

    return _buildCenteredContent(
      _buildTallyIconDisplay(theme, effectiveColor, effectiveIconSize),
    );
  }

  /// Wraps content with centered alignment for text display
  Widget _buildCenteredContent(Widget child) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Align(alignment: Alignment.center, child: child),
    );
  }

  /// Builds the text display for large values or when useTally is false
  Widget _buildTextDisplay(ThemeData theme, Color effectiveColor) {
    final effectiveTextStyle =
        textStyle ??
        theme.textTheme.bodyMedium?.copyWith(color: effectiveColor) ??
        TextStyle(color: effectiveColor);

    return Text(value.toString(), style: effectiveTextStyle);
  }

  /// Builds the tally icon display for smaller values
  Widget _buildTallyIconDisplay(
    ThemeData theme,
    Color effectiveColor,
    double effectiveIconSize,
  ) {
    final tallyIcons = AssetIconService.getTallyIconPaths(value);

    if (tallyIcons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 2.0, // Add small spacing between icons
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

  /// Builds a single tally icon
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
