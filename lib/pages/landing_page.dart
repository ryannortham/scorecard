import 'package:flutter/material.dart';
import 'game_setup.dart';
import 'scoring.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  Widget build(BuildContext context) {
    final primaryButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 0,
    );

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
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              child: ElevatedButton(
                style: primaryButtonStyle,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const GameSetup(title: 'Game Setup'),
                    ),
                  );
                },
                child: const Text("Score Keeping"),
              ),
            ),
            const Spacer(flex: 1),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              child: ElevatedButton(
                style: primaryButtonStyle,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const Scoring(title: 'Scoring'),
                    ),
                  );
                },
                child: const Text("View Game Results"),
              ),
            ),
            const Spacer(flex: 8),
          ],
        ),
      ),
    );
  }
}
