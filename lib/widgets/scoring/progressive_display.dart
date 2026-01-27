// displays progressive number sequences for goals or behinds in a quarter

import 'package:flutter/material.dart';

import 'package:scorecard/widgets/scoring/progressive_number.dart';

/// displays a sequence of progressive numbers for goals or behinds
///
/// shows numbers with appropriate decorations:
/// - previous numbers: diagonal strikethrough
/// - last number in completed quarter: underlined
/// - last number in active quarter: plain
///
/// handles overflow by showing first number, ellipsis, then last number
class ProgressiveDisplay extends StatelessWidget {
  const ProgressiveDisplay({
    required this.count,
    required this.startingNumber,
    required this.isQuarterComplete,
    super.key,
    this.textStyle,
  });

  /// number of goals/behinds scored in this quarter
  final int count;

  /// cumulative total before this quarter (determines starting number)
  final int startingNumber;

  /// whether this quarter is complete (last number gets underline)
  final bool isQuarterComplete;

  final TextStyle? textStyle;

  /// Max numbers to show for single digits (1-9)
  static const int _singleDigitThreshold = 9;

  /// Max numbers to show for double digits (10-99)
  static const int _doubleDigitThreshold = 5;

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
