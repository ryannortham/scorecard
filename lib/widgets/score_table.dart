import 'package:flutter/material.dart';

class ScoreTable extends StatelessWidget {
  final TextStyle boldStyle = const TextStyle(fontWeight: FontWeight.bold);

  const ScoreTable({super.key});

  Widget borderedText(BuildContext context, String text,
      {bool right = false,
      bool left = false,
      bool top = false,
      bool bottom = false,
      bool isBold = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? BorderSide(width: 2, color: Theme.of(context).dividerColor)
              : BorderSide.none,
          bottom: bottom
              ? BorderSide(width: 2, color: Theme.of(context).dividerColor)
              : BorderSide.none,
          right: right
              ? BorderSide(width: 2, color: Theme.of(context).dividerColor)
              : BorderSide.none,
          left: left
              ? BorderSide(width: 2, color: Theme.of(context).dividerColor)
              : BorderSide.none,
        ),
      ),
      child: Center(child: Text(text, style: isBold ? boldStyle : null)),
    );
  }

  TableRow createRow(BuildContext context, List<String> values,
      {bool isBold = false}) {
    return TableRow(
      children: values
          .map((value) => borderedText(context, value, isBold: isBold))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columnWidth =
          constraints.maxWidth / 7; // Divide by the number of columns
      final borderInside =
          BorderSide(width: 1, color: Theme.of(context).dividerColor);
      final borderOutside =
          BorderSide(width: 2, color: Theme.of(context).dividerColor);

      return Table(
        columnWidths: {
          for (var index in List.generate(7, (index) => index))
            index: FixedColumnWidth(columnWidth)
        },
        border: TableBorder(
          verticalInside: borderInside,
          horizontalInside: borderInside,
          top: borderOutside,
          bottom: borderOutside,
          left: borderOutside,
          right: borderOutside,
        ),
        children: [
          createRow(
              context,
              [
                'Qtr',
                'Goals',
                'Behinds',
                'Points',
                'Goals',
                'Behinds',
                'Points'
              ],
              isBold: true),
          createRow(context, ['1st', '0', '0', '0', '0', '0', '0']),
          createRow(context, ['2nd', '0', '0', '0', '0', '0', '0']),
          createRow(context, ['3rd', '0', '0', '0', '0', '0', '0']),
          createRow(context, ['4th', '0', '0', '0', '0', '0', '0']),
          createRow(context, ['Totals', '0', '0', '0', '0', '0', '0'],
              isBold: true),
        ],
      );
    });
  }
}
