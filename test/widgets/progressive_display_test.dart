// tests for progressive display widget - number sequences with overflow

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scorecard/widgets/scoring/progressive_display.dart';
import 'package:scorecard/widgets/scoring/progressive_number.dart';

void main() {
  Widget buildTestWidget(ProgressiveDisplay display) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: display),
      ),
    );
  }

  group('ProgressiveDisplay', () {
    group('empty and single number', () {
      testWidgets('should return empty widget for count=0', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            const ProgressiveDisplay(
              count: 0,
              startingNumber: 0,
              isQuarterComplete: false,
            ),
          ),
        );

        expect(find.byType(ProgressiveNumber), findsNothing);
        expect(find.byType(SizedBox), findsWidgets);
      });

      testWidgets('should show single number without strikethrough', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            const ProgressiveDisplay(
              count: 1,
              startingNumber: 0,
              isQuarterComplete: false,
            ),
          ),
        );

        expect(find.byType(ProgressiveNumber), findsOneWidget);
        expect(find.text('1'), findsOneWidget);

        final progressiveNumber = tester.widget<ProgressiveNumber>(
          find.byType(ProgressiveNumber),
        );
        expect(progressiveNumber.decoration, NumberDecoration.none);
      });

      testWidgets('should apply underline when quarter complete', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            const ProgressiveDisplay(
              count: 1,
              startingNumber: 0,
              isQuarterComplete: true,
            ),
          ),
        );

        final progressiveNumber = tester.widget<ProgressiveNumber>(
          find.byType(ProgressiveNumber),
        );
        expect(progressiveNumber.decoration, NumberDecoration.underline);
      });
    });

    group('multiple numbers without overflow', () {
      testWidgets('should show all numbers with strikethrough on previous', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            const ProgressiveDisplay(
              count: 3,
              startingNumber: 0,
              isQuarterComplete: false,
            ),
          ),
        );

        expect(find.byType(ProgressiveNumber), findsNWidgets(3));
        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);

        final numbers =
            tester
                .widgetList<ProgressiveNumber>(find.byType(ProgressiveNumber))
                .toList();

        // First two should have strikethrough
        expect(numbers[0].decoration, NumberDecoration.strikethrough);
        expect(numbers[1].decoration, NumberDecoration.strikethrough);
        // Last should have no decoration (quarter not complete)
        expect(numbers[2].decoration, NumberDecoration.none);
      });

      testWidgets('should underline last number when quarter complete', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            const ProgressiveDisplay(
              count: 3,
              startingNumber: 0,
              isQuarterComplete: true,
            ),
          ),
        );

        final numbers =
            tester
                .widgetList<ProgressiveNumber>(find.byType(ProgressiveNumber))
                .toList();

        expect(numbers[0].decoration, NumberDecoration.strikethrough);
        expect(numbers[1].decoration, NumberDecoration.strikethrough);
        expect(numbers[2].decoration, NumberDecoration.underline);
      });

      testWidgets('should respect starting number offset', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            const ProgressiveDisplay(
              count: 3,
              startingNumber: 5,
              isQuarterComplete: false,
            ),
          ),
        );

        expect(find.text('6'), findsOneWidget);
        expect(find.text('7'), findsOneWidget);
        expect(find.text('8'), findsOneWidget);
        expect(find.text('1'), findsNothing);
      });

      testWidgets('should show 8 single-digit numbers without ellipsis', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            const ProgressiveDisplay(
              count: 8,
              startingNumber: 0,
              isQuarterComplete: false,
            ),
          ),
        );

        // Should show all 8 numbers, no ellipsis
        expect(find.byType(ProgressiveNumber), findsNWidgets(8));
        expect(find.text('...'), findsNothing);
        expect(find.text('…'), findsNothing);
      });
    });

    group('ellipsis format (overflow)', () {
      testWidgets(
        'should show first...last for >8 single-digit numbers (the bug fix)',
        (tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              const ProgressiveDisplay(
                count: 9,
                startingNumber: 0,
                isQuarterComplete: false,
              ),
            ),
          );

          // Should show ellipsis format: "1 … 9"
          expect(find.byType(ProgressiveNumber), findsNWidgets(2));
          expect(find.text('1'), findsOneWidget);
          expect(find.text('9'), findsOneWidget);
          expect(find.text('…'), findsOneWidget);
        },
      );

      testWidgets('first number should have strikethrough in ellipsis format', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            const ProgressiveDisplay(
              count: 9,
              startingNumber: 0,
              isQuarterComplete: false,
            ),
          ),
        );

        final numbers =
            tester
                .widgetList<ProgressiveNumber>(find.byType(ProgressiveNumber))
                .toList();

        // First number (1) should have strikethrough
        expect(numbers[0].number, 1);
        expect(numbers[0].decoration, NumberDecoration.strikethrough);
      });

      testWidgets('last number should have correct decoration', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            const ProgressiveDisplay(
              count: 9,
              startingNumber: 0,
              isQuarterComplete: false,
            ),
          ),
        );

        final numbers =
            tester
                .widgetList<ProgressiveNumber>(find.byType(ProgressiveNumber))
                .toList();

        // Last number (9) should have no decoration when quarter not complete
        expect(numbers[1].number, 9);
        expect(numbers[1].decoration, NumberDecoration.none);
      });

      testWidgets('last number should be underlined when quarter complete', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            const ProgressiveDisplay(
              count: 9,
              startingNumber: 0,
              isQuarterComplete: true,
            ),
          ),
        );

        final numbers =
            tester
                .widgetList<ProgressiveNumber>(find.byType(ProgressiveNumber))
                .toList();

        expect(numbers[1].number, 9);
        expect(numbers[1].decoration, NumberDecoration.underline);
      });

      testWidgets('uses ellipsis for >5 when last number is double-digit', (
        tester,
      ) async {
        // count=6, startingNumber=5 means numbers 6,7,8,9,10,11
        // lastNumber=11 (double-digit), threshold=5, so 6 > 5 triggers ellipsis
        await tester.pumpWidget(
          buildTestWidget(
            const ProgressiveDisplay(
              count: 6,
              startingNumber: 5,
              isQuarterComplete: false,
            ),
          ),
        );

        expect(find.byType(ProgressiveNumber), findsNWidgets(2));
        expect(find.text('6'), findsOneWidget);
        expect(find.text('11'), findsOneWidget);
        expect(find.text('…'), findsOneWidget);
      });

      testWidgets('should show 5 double-digit numbers without ellipsis', (
        tester,
      ) async {
        // count=5, startingNumber=5 means numbers 6,7,8,9,10
        // lastNumber=10 (double-digit), threshold=5, so 5 <= 5 shows all
        await tester.pumpWidget(
          buildTestWidget(
            const ProgressiveDisplay(
              count: 5,
              startingNumber: 5,
              isQuarterComplete: false,
            ),
          ),
        );

        expect(find.byType(ProgressiveNumber), findsNWidgets(5));
        expect(find.text('…'), findsNothing);
      });

      testWidgets('ellipsis format with large starting number', (tester) async {
        // Simulating Q4 with many goals: startingNumber=20, count=10
        // Numbers would be 21-30
        await tester.pumpWidget(
          buildTestWidget(
            const ProgressiveDisplay(
              count: 10,
              startingNumber: 20,
              isQuarterComplete: true,
            ),
          ),
        );

        expect(find.byType(ProgressiveNumber), findsNWidgets(2));
        expect(find.text('21'), findsOneWidget);
        expect(find.text('30'), findsOneWidget);

        final numbers =
            tester
                .widgetList<ProgressiveNumber>(find.byType(ProgressiveNumber))
                .toList();

        expect(numbers[0].decoration, NumberDecoration.strikethrough);
        expect(numbers[1].decoration, NumberDecoration.underline);
      });
    });
  });
}
