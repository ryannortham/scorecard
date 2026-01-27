// tests for team name processing string extension

import 'package:flutter_test/flutter_test.dart';
import 'package:scorecard/extensions/string_extensions.dart';

void main() {
  group('TeamNameExtension', () {
    test('should convert Junior Football Club to JFC', () {
      expect(
        'Collingwood Junior Football Club'.toProcessedTeamName(),
        equals('Collingwood JFC'),
      );
    });

    test('should convert Football Club to FC', () {
      expect(
        'Richmond Football Club'.toProcessedTeamName(),
        equals('Richmond FC'),
      );
    });

    test('should convert Football & Netball Club to FNC', () {
      expect(
        'Essendon Football & Netball Club'.toProcessedTeamName(),
        equals('Essendon FNC'),
      );
    });

    test('should convert Football and Netball Club to FNC', () {
      expect(
        'Adelaide Football and Netball Club'.toProcessedTeamName(),
        equals('Adelaide FNC'),
      );
    });

    test('should convert Football / Netball Club to FNC', () {
      expect(
        'Carlton Football / Netball Club'.toProcessedTeamName(),
        equals('Carlton FNC'),
      );
    });

    test('should convert Football Netball Club to FNC (space separator)', () {
      // The regex requires at least one space after "Football"
      expect(
        'Hawthorn Football Netball Club'.toProcessedTeamName(),
        equals('Hawthorn FNC'),
      );
    });

    test('should remove bracketed content', () {
      expect(
        'Adelaide FC (Crows)'.toProcessedTeamName(),
        equals('Adelaide FC'),
      );
    });

    test('should handle multiple transformations', () {
      expect(
        'Melbourne Football Club (Demons)'.toProcessedTeamName(),
        equals('Melbourne FC'),
      );
    });

    test('should trim whitespace', () {
      expect(
        '  Geelong Football Club  '.toProcessedTeamName(),
        equals('Geelong FC'),
      );
    });

    test('should normalize multiple spaces', () {
      expect(
        'North   Melbourne     Football Club'.toProcessedTeamName(),
        equals('North Melbourne FC'),
      );
    });

    test('should handle complex case with all transformations', () {
      expect(
        '  St Kilda Football & Netball Club (Saints)  '.toProcessedTeamName(),
        equals('St Kilda FNC'),
      );
    });

    test('should preserve order of transformations correctly', () {
      // Junior Football Club should be converted before Football Club
      expect(
        'Williamstown Junior Football Club'.toProcessedTeamName(),
        equals('Williamstown JFC'),
      );
    });

    test('should handle case insensitive matching', () {
      expect(
        'Brisbane FOOTBALL CLUB'.toProcessedTeamName(),
        equals('Brisbane FC'),
      );
    });
  });
}
