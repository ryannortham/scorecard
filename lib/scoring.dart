import 'package:flutter/material.dart';
import 'package:customizable_counter/customizable_counter.dart';

class Scoring extends StatefulWidget {
  const Scoring({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _ScoringState createState() => _ScoringState();
}

class ProgressBar extends StatelessWidget {
  final double value;

  const ProgressBar({Key? key, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: value,
      backgroundColor: Colors.grey[300],
      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
    );
  }
}

class _ScoringState extends State<Scoring> {
  int _selectedIndex = 1;
  int _homeGoals = 0;
  int _homeBehinds = 0;
  int _homePoints = 0;
  int _awayGoals = 0;
  int _awayBehinds = 0;
  int _awayPoints = 0;

  final double _progressValue = 0.5;
  final GlobalKey _formKey = GlobalKey<FormState>();
  final List<bool> _isQuarterSelected = [true, false, false, false];

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onCountTapped() {
    setState(() {
      _homePoints = _homeGoals * 6 + _homeBehinds;
      _awayPoints = _awayGoals * 6 + _awayBehinds;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.center,
              width: double.infinity,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Text(
                'Home Team',
                style: Theme.of(context).textTheme.headlineSmall,
                overflow: null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _homePoints.toString(),
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
            Container(
              transformAlignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 1),
                  Text(
                    'Goals',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  CustomizableCounter(
                    backgroundColor:
                        Theme.of(context).inputDecorationTheme.fillColor,
                    borderWidth: 2,
                    borderRadius: 100,
                    textSize: 22,
                    count: _homeGoals.toDouble(),
                    step: 1,
                    minCount: 0,
                    maxCount: 100,
                    incrementIcon: const Icon(
                      Icons.add,
                    ),
                    decrementIcon: const Icon(
                      Icons.remove,
                    ),
                    showButtonText: false,
                    onCountChange: (count) {
                      _homeGoals = count.toInt();
                      _onCountTapped();
                    },
                    onIncrement: (count) {},
                    onDecrement: (count) {},
                  ),
                  const Spacer(flex: 1),
                  Text(
                    'Behinds',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  CustomizableCounter(
                    backgroundColor:
                        Theme.of(context).inputDecorationTheme.fillColor,
                    borderWidth: 2,
                    borderRadius: 100,
                    textSize: 22,
                    count: _homeBehinds.toDouble(),
                    step: 1,
                    minCount: 0,
                    maxCount: 100,
                    incrementIcon: const Icon(
                      Icons.add,
                    ),
                    decrementIcon: const Icon(
                      Icons.remove,
                    ),
                    showButtonText: false,
                    onCountChange: (count) {
                      _homeBehinds = count.toInt();
                      _onCountTapped();
                    },
                    onIncrement: (count) {},
                    onDecrement: (count) {},
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Container(
              alignment: Alignment.center,
              width: double.infinity,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Text(
                'Away Team',
                style: Theme.of(context).textTheme.headlineSmall,
                overflow: null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _awayPoints.toString(),
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
            Container(
              transformAlignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 1),
                  Text(
                    'Goals',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  CustomizableCounter(
                    backgroundColor:
                        Theme.of(context).inputDecorationTheme.fillColor,
                    borderWidth: 2,
                    borderRadius: 100,
                    textSize: 22,
                    count: _awayGoals.toDouble(),
                    step: 1,
                    minCount: 0,
                    maxCount: 100,
                    incrementIcon: const Icon(
                      Icons.add,
                    ),
                    decrementIcon: const Icon(
                      Icons.remove,
                    ),
                    showButtonText: false,
                    onCountChange: (count) {
                      _awayGoals = count.toInt();
                      _onCountTapped();
                    },
                    onIncrement: (count) {},
                    onDecrement: (count) {},
                  ),
                  const Spacer(flex: 1),
                  Text(
                    'Behinds',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  CustomizableCounter(
                    backgroundColor:
                        Theme.of(context).inputDecorationTheme.fillColor,
                    borderWidth: 2,
                    borderRadius: 100,
                    textSize: 22,
                    count: _awayBehinds.toDouble(),
                    step: 1,
                    minCount: 0,
                    maxCount: 100,
                    incrementIcon: const Icon(
                      Icons.add,
                    ),
                    decrementIcon: const Icon(
                      Icons.remove,
                    ),
                    showButtonText: false,
                    onCountChange: (count) {
                      _awayBehinds = count.toInt();
                      _onCountTapped();
                    },
                    onIncrement: (count) {},
                    onDecrement: (count) {},
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            SizedBox(
              width: double.infinity,
              child: LinearProgressIndicator(
                value: _progressValue,
                minHeight: 8,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ToggleButtons(
                  isSelected: _isQuarterSelected,
                  selectedColor: Colors.white,
                  fillColor: Theme.of(context).primaryColor,
                  onPressed: (int index) {
                    setState(() {
                      for (int i = 0; i < _isQuarterSelected.length; i++) {
                        _isQuarterSelected[i] = (i == index);
                      }
                    });
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Quarter 1'),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Quarter 2'),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Quarter 3'),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Quarter 4'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Game Setup',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag_outlined),
            label: 'Scoring',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Results',
          ),
        ],
      ),
    );
  }
}
