import 'package:flutter/material.dart';
import 'package:goalkeeper/widgets/score_table.dart';

class DebugPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Page'),
      ),
      body: ScoreTable(),
    );
  }
}
