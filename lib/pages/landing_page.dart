import 'package:flutter/material.dart';
import 'game_setup.dart';
import 'scoring.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  LandingPageState createState() => LandingPageState();
}

class LandingPageState extends State<LandingPage> {
  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            const Spacer(flex: 8),
            Text(
              'Welcome to GoalKeeper',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Spacer(flex: 2),
            Text(
              'What would you like to do?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(flex: 1),
            _buildButton(
              "Score a Game",
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const GameSetup(title: 'Game Setup'),
                ),
              ),
            ),
            const Spacer(flex: 1),
            _buildButton(
              "View Game Results",
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const Scoring(title: 'Scoring'),
                ),
              ),
            ),
            const Spacer(flex: 8),
          ],
        ),
      ),
    );
  }
}
