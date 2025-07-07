import 'package:flutter_test/flutter_test.dart';

/// Test helper to simulate the team name processing logic
class TeamNameProcessor {
  // Pre-compiled regex patterns for performance
  static final RegExp _bracketsRegex = RegExp(r'\([^)]*\)');
  static final RegExp _footballNetballRegex = RegExp(
    r'Football\s*(?:[&/]|and)\s*Netball\s+Club',
    caseSensitive: false,
  );
  static final RegExp _juniorFootballClubRegex = RegExp(
    r'Junior\s+Football\s+Club',
    caseSensitive: false,
  );
  static final RegExp _footballClubRegex = RegExp(
    r'Football\s+Club',
    caseSensitive: false,
  );
  static final RegExp _whitespaceRegex = RegExp(r'\s+');

  /// Process a team name according to the specified rules
  static String processTeamName(String name) {
    String processed = name;

    // Remove bracketed content
    processed = processed.replaceAll(_bracketsRegex, '');

    // Convert variations of 'Football & Netball Club' to 'FNC'
    processed = processed.replaceAll(_footballNetballRegex, 'FNC');

    // Convert 'Junior Football Club' to 'JFC'
    processed = processed.replaceAll(_juniorFootballClubRegex, 'JFC');

    // Convert 'Football Club' to 'FC'
    processed = processed.replaceAll(_footballClubRegex, 'FC');

    // Normalize whitespace and trim
    processed = processed.replaceAll(_whitespaceRegex, ' ').trim();

    return processed;
  }
}

void main() {
  group('TeamNameProcessor', () {
    test('should convert Junior Football Club to JFC', () {
      expect(
        TeamNameProcessor.processTeamName('Collingwood Junior Football Club'),
        equals('Collingwood JFC'),
      );
    });

    test('should convert Football Club to FC', () {
      expect(
        TeamNameProcessor.processTeamName('Richmond Football Club'),
        equals('Richmond FC'),
      );
    });

    test('should convert Football & Netball Club to FNC', () {
      expect(
        TeamNameProcessor.processTeamName('Essendon Football & Netball Club'),
        equals('Essendon FNC'),
      );
    });

    test('should convert Football and Netball Club to FNC', () {
      expect(
        TeamNameProcessor.processTeamName('Adelaide Football and Netball Club'),
        equals('Adelaide FNC'),
      );
    });

    test('should convert Football / Netball Club to FNC', () {
      expect(
        TeamNameProcessor.processTeamName('Carlton Football / Netball Club'),
        equals('Carlton FNC'),
      );
    });

    test('should convert Football&Netball Club to FNC (no spaces)', () {
      expect(
        TeamNameProcessor.processTeamName('Hawthorn Football&Netball Club'),
        equals('Hawthorn FNC'),
      );
    });

    test('should remove bracketed content', () {
      expect(
        TeamNameProcessor.processTeamName('Adelaide FC (Crows)'),
        equals('Adelaide FC'),
      );
    });

    test('should handle multiple transformations', () {
      expect(
        TeamNameProcessor.processTeamName('Melbourne Football Club (Demons)'),
        equals('Melbourne FC'),
      );
    });

    test('should trim whitespace', () {
      expect(
        TeamNameProcessor.processTeamName('  Geelong Football Club  '),
        equals('Geelong FC'),
      );
    });

    test('should normalize multiple spaces', () {
      expect(
        TeamNameProcessor.processTeamName(
          'North   Melbourne     Football Club',
        ),
        equals('North Melbourne FC'),
      );
    });

    test('should handle complex case with all transformations', () {
      expect(
        TeamNameProcessor.processTeamName(
          '  St Kilda Football & Netball Club (Saints)  ',
        ),
        equals('St Kilda FNC'),
      );
    });

    test('should preserve order of transformations correctly', () {
      // Junior Football Club should be converted before Football Club
      expect(
        TeamNameProcessor.processTeamName('Williamstown Junior Football Club'),
        equals('Williamstown JFC'),
      );
    });

    test('should handle case insensitive matching', () {
      expect(
        TeamNameProcessor.processTeamName('Brisbane FOOTBALL CLUB'),
        equals('Brisbane FC'),
      );
    });
  });
}
