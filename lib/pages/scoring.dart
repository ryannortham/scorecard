import 'package:flutter/material.dart';
import 'package:goalkeeper/providers/game_setup_state.dart';
import 'package:provider/provider.dart';
import '../providers/score_panel_state.dart';
import '../widgets/score_panel.dart';

class Scoring extends StatefulWidget {
  const Scoring({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _ScoringState createState() => _ScoringState();
}

class _ScoringState extends State<Scoring> {
  int _selectedIndex = 1;

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    String homeTeamName = Provider.of<GameSetupState>(context).homeTeam;
    String awayTeamName = Provider.of<GameSetupState>(context).awayTeam;

    return Consumer<ScorePanelState>(
      builder: (context, scorePanelState, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
          ),
          body: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ScorePanel(
                  teamName: homeTeamName,
                  isHomeTeam: true,
                ),
                const SizedBox(height: 16),
                ScorePanel(
                  teamName: awayTeamName,
                  isHomeTeam: false,
                ),
                const SizedBox(height: 16),
                const SizedBox(
                  width: double.infinity,
                  child: LinearProgressIndicator(
                    value: 0.5,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 16),
                ToggleButtons(
                  isSelected: const [true, false, false, false],
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
      },
    );
  }
}
