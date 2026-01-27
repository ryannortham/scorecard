// tally mark and football icon asset paths

/// provides asset paths for tally marks and app icons
class AssetService {
  static const int _maxTallyValue = 5;

  /// returns tally icon paths for a given value, empty list for zero/negative
  static List<String> getTallyIconPaths(int value) {
    if (value <= 0) return [];

    final icons = <String>[];
    var remaining = value;

    while (remaining >= _maxTallyValue) {
      icons.add('assets/tally/tally$_maxTallyValue.ico');
      remaining -= _maxTallyValue;
    }

    if (remaining > 0) {
      icons.add('assets/tally/tally$remaining.ico');
    }

    return icons;
  }

  static const String footballIconPath = 'assets/icon/football.png';
}
