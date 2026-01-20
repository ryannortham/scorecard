import 'package:flutter/material.dart';

import 'package:scorecard/widgets/scoring/progressive_number.dart';

/// Displays a sequence of progressive numbers for goals or behinds in a quarter.
///
/// Shows numbers with appropriate decorations:
/// - Previous numbers: diagonal strikethrough
/// - Last number in completed quarter: underlined
/// - Last number in active quarter: plain
///
/// Handles overflow by showing first number, ellipsis, then last number (e.g., "1 … 10").
class ProgressiveDisplay extends StatelessWidget {
  /// Number of goals/behinds scored in this quarter
  final int count;

  /// Cumulative total before this quarter (determines starting number)
  final int startingNumber;

  /// Whether this quarter is complete (last number gets underline)
  final bool isQuarterComplete;

  final TextStyle? textStyle;

  /// Max numbers to show for single digits (1-9)
  static const int _singleDigitThreshold = 9;

  /// Max numbers to show for double digits (10-99)
  static const int _doubleDigitThreshold = 5;

  const ProgressiveDisplay({
    super.key,
    required this.count,
    required this.startingNumber,
    required this.isQuarterComplete,
    this.textStyle,
  });

  /// Returns the appropriate threshold based on the last number's digit count
  int _getThreshold(int lastNumber) {
    if (lastNumber < 10) return _singleDigitThreshold;
    return _doubleDigitThreshold;
  }

  /// Whether the display should use ellipsis format for the given count
  bool _shouldUseEllipsis(int lastNumber) {
    return count > _getThreshold(lastNumber);
  }

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    final firstNumber = startingNumber + 1;
    final lastNumber = startingNumber + count;

    // single number - no strikethrough needed
    if (count == 1) {
      return ProgressiveNumber(
        number: lastNumber,
        decoration:
            isQuarterComplete
                ? NumberDecoration.underline
                : NumberDecoration.none,
        textStyle: textStyle,
      );
    }

    // check if we should use ellipsis format
    if (_shouldUseEllipsis(lastNumber)) {
      return _buildEllipsisFormat(firstNumber, lastNumber);
    }

    // show all numbers
    return _buildAllNumbers();
  }

  /// Builds display showing all numbers: 1 2 3 4
  Widget _buildAllNumbers() {
    final numbers = List.generate(count, (i) => startingNumber + i + 1);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children:
          numbers.asMap().entries.map((entry) {
            final index = entry.key;
            final number = entry.value;
            final isLast = index == numbers.length - 1;

            NumberDecoration decoration;
            if (isLast) {
              decoration =
                  isQuarterComplete
                      ? NumberDecoration.underline
                      : NumberDecoration.none;
            } else {
              decoration = NumberDecoration.strikethrough;
            }

            return Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 4),
              child: ProgressiveNumber(
                number: number,
                decoration: decoration,
                textStyle: textStyle,
              ),
            );
          }).toList(),
    );
  }

  /// Builds display with ellipsis: 1 … 10
  Widget _buildEllipsisFormat(int firstNumber, int lastNumber) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProgressiveNumber(
          number: firstNumber,
          decoration: NumberDecoration.strikethrough,
          textStyle: textStyle,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('…', style: textStyle),
        ),
        ProgressiveNumber(
          number: lastNumber,
          decoration:
              isQuarterComplete
                  ? NumberDecoration.underline
                  : NumberDecoration.none,
          textStyle: textStyle,
        ),
      ],
    );
  }
}
