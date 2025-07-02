/// Service for handling tally icon assets
class TallyIconService {
  /// Maximum value for a single tally icon
  static const int _maxTallyValue = 5;

  /// Gets tally icon paths for a given number
  /// Returns empty list for zero/negative values
  static List<String> getTallyIcons(int value) {
    if (value <= 0) return [];

    final List<String> icons = [];
    int remaining = value;

    // Add tally5 icons for groups of 5
    while (remaining >= _maxTallyValue) {
      icons.add('assets/tally/tally$_maxTallyValue.ico');
      remaining -= _maxTallyValue;
    }

    // Add remainder
    if (remaining > 0) {
      icons.add('assets/tally/tally$remaining.ico');
    }

    return icons;
  }

  /// Gets total number of tally icons needed
  static int getTallyIconCount(int value) {
    if (value <= 0) return 0;
    return (value / _maxTallyValue).ceil();
  }

  /// Gets all available tally icon paths
  static List<String> getAllTallyIconPaths() {
    return List.generate(
      _maxTallyValue,
      (index) => 'assets/tally/tally${index + 1}.ico',
    );
  }
}
