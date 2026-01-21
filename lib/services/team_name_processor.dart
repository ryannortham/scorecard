/// Service for processing team names with standardised abbreviations
class TeamNameProcessor {
  // Single optimised regex pattern that captures all variations
  static final RegExp _teamNameRegex = RegExp(
    r'\([^)]*\)|' // Remove brackets and content
    r'(?:Junior\s+Football\s+Club|Junior\s+FC)\b|' // Junior variations
    r'Football\s+.*?Netball\s+Club\b|' // Football Netball variations
    r'Football\s+Club\b', // Football Club
    caseSensitive: false,
  );

  static final RegExp _whitespaceRegex = RegExp(r'\s+');

  /// Process a team name according to the specified rules:
  /// - Remove bracketed content e.g. "(Demons)"
  /// - Convert "Junior Football Club" / "Junior FC" to "JFC"
  /// - Convert "Football & Netball Club" variations to "FNC"
  /// - Convert "Football Club" to "FC"
  /// - Normalise whitespace
  static String processTeamName(String name) {
    // Single pass replacement with callback function
    String processed = name.replaceAllMapped(_teamNameRegex, (match) {
      final matchText = match.group(0)!.toLowerCase();

      // Remove bracketed content
      if (matchText.startsWith('(')) return '';

      // Convert Junior variations to JFC
      if (matchText.contains('junior')) return 'JFC';

      // Convert Football Netball variations to FNC
      if (matchText.contains('netball')) return 'FNC';

      // Convert Football Club to FC
      if (matchText.contains('football') && matchText.contains('club')) {
        return 'FC';
      }

      return match.group(0)!; // Fallback (shouldn't happen)
    });

    // Normalise whitespace and trim
    return processed.replaceAll(_whitespaceRegex, ' ').trim();
  }
}
