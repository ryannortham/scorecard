import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/providers/score_panel_provider.dart';

class ScoreTable extends StatelessWidget {
  final TextStyle boldStyle = const TextStyle(fontWeight: FontWeight.bold);

  const ScoreTable({Key? key}) : super(key: key);

  Widget createCell(BuildContext context, String text, {bool isBold = false}) {
    return SizedBox(
      height: 24,
      child: Center(
        child: Text(text, style: isBold ? boldStyle : null),
      ),
    );
  }

  TableRow createRow(BuildContext context, int rowIndex, List<String> values) {
    final selectedQuarter = Provider.of<ScorePanelProvider>(context, listen: true).selectedQuarter;

    return TableRow(
      decoration: BoxDecoration(
        color: (rowIndex == selectedQuarter) ? Theme.of(context).colorScheme.secondaryContainer : Colors.transparent,
      ),
      children: [
        createCell(context, values[0]),
        createNestedCell(context, values.sublist(1, 3)),
        createNestedCell(context, values.sublist(3, 5)),
        createNestedCell(context, values.sublist(5, 7)),
      ],
    );
  }

  Widget createNestedCell(BuildContext context, List<String> values) {
    return Table(
      border: TableBorder(
        verticalInside: BorderSide(width: 1, color: Theme.of(context).dividerColor),
      ),
      columnWidths: const {
        0: FlexColumnWidth(0.7),
        1: FlexColumnWidth(0.3),
      },
      children: [
        TableRow(
          children: [
            createCell(context, values[0]),
            createCell(context, values[1], isBold: true),
          ],
        ),
      ],
    );
  }

  TableRow createSpecialRow(BuildContext context, List<String> values) {
    return TableRow(
      children: [
        createCell(context, values[0], isBold: true),
        TableCell(
          child: createCell(context, values[1], isBold: true),
        ),
        TableCell(
          child: createCell(context, values[2], isBold: true),
        ),
        createCell(context, values[3], isBold: true),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Table(
        border: TableBorder(
          verticalInside: BorderSide(width: 1, color: Theme.of(context).dividerColor),
          horizontalInside: BorderSide(width: 1, color: Theme.of(context).dividerColor),
          top: BorderSide(width: 2, color: Theme.of(context).dividerColor),
          bottom: BorderSide(width: 2, color: Theme.of(context).dividerColor),
          left: BorderSide(width: 2, color: Theme.of(context).dividerColor),
          right: BorderSide(width: 2, color: Theme.of(context).dividerColor),
        ),
        columnWidths: const {
          0: FlexColumnWidth(0.1),
          1: FlexColumnWidth(0.3),
          2: FlexColumnWidth(0.3),
          3: FlexColumnWidth(0.3),
        },
        children: [
          createSpecialRow(context, [
            'Qtr',
            'Goals',
            'Behinds',
            'Points',
          ]),
          createRow(context, 1, ['1st', '1', '1', '2', '2', '8', '8']),
          createRow(context, 2, ['2nd', '2', '3', '1', '3', '13', '21']),
          createRow(context, 3, ['3rd', '1', '4', '2', '5', '8', '29']),
          createRow(context, 4, ['4th', '0', '4', '1', '6', '1', '30']),
        ],
      ),
    );
  }
}
