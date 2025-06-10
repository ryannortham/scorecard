import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/adapters/game_setup_adapter.dart';
import 'package:goalkeeper/providers/settings_provider.dart';
import 'package:goalkeeper/adapters/score_panel_adapter.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/screens/scoring.dart';
import 'package:goalkeeper/widgets/game_details/game_details_widget.dart';
import 'package:goalkeeper/services/scoring_state_manager.dart';
import 'package:widget_screenshot_plus/widget_screenshot_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'settings.dart';

class GameContainer extends StatefulWidget {
  const GameContainer({super.key});

  @override
  State<GameContainer> createState() => _GameContainerState();
}

class _GameContainerState extends State<GameContainer> {
  int _currentIndex = 0;
  late PageController _pageController;
  final GlobalKey<ScoringState> _scoringKey = GlobalKey<ScoringState>();
  final GlobalKey _gameDetailsKey = GlobalKey();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Exit Game?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Exit'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> _onWillPop() async {
    // Always show exit confirmation when leaving an active game
    return await _showExitConfirmation();
  }

  void _shareGameDetails(BuildContext context) async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final shareText = _buildShareText();

      // Use post-frame callback to ensure UI is fully rendered
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await _shareWithWidgetShotPlus(shareText);
        } catch (e) {
          debugPrint('Error in share post-frame callback: $e');
          // Show error if sharing failed
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to share: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isSharing = false;
            });
          }
        }
      });
    } catch (e) {
      debugPrint('Error preparing share: $e');
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  String _buildShareText() {
    final gameSetupAdapter =
        Provider.of<GameSetupAdapter>(context, listen: false);
    final scorePanelAdapter =
        Provider.of<ScorePanelAdapter>(context, listen: false);

    final homeScore =
        '${scorePanelAdapter.homeGoals}.${scorePanelAdapter.homeBehinds} (${scorePanelAdapter.homePoints})';
    final awayScore =
        '${scorePanelAdapter.awayGoals}.${scorePanelAdapter.awayBehinds} (${scorePanelAdapter.awayPoints})';

    return '''${gameSetupAdapter.homeTeam} vs ${gameSetupAdapter.awayTeam}
Score: $homeScore - $awayScore
Date: ${gameSetupAdapter.gameDate.day}/${gameSetupAdapter.gameDate.month}/${gameSetupAdapter.gameDate.year}''';
  }

  /// Capture and share using WidgetShotPlus
  Future<void> _shareWithWidgetShotPlus(String shareText) async {
    try {
      final boundary = _gameDetailsKey.currentContext?.findRenderObject()
          as WidgetShotPlusRenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Could not find WidgetShotPlus boundary');
      }

      // Capture the full widget content
      final imageBytes = await boundary.screenshot(
        format: ShotFormat.png,
        quality: 100,
        pixelRatio: 2.0,
      );

      if (imageBytes == null) {
        throw Exception('Failed to capture image');
      }

      // Create a temporary file for sharing
      final directory = await getTemporaryDirectory();
      final fileName = _generateFileName();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      // Share the image with text
      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
      );

      // No success feedback needed - user can see share dialog
    } catch (e) {
      debugPrint('Error sharing widget: $e');

      // Fallback to text-only sharing
      await Share.share(shareText);

      // No success feedback needed for fallback sharing
    }
  }

  /// Generate a descriptive filename for the image
  String _generateFileName() {
    final gameSetupAdapter =
        Provider.of<GameSetupAdapter>(context, listen: false);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanHome =
        gameSetupAdapter.homeTeam.replaceAll(RegExp(r'[^\w]'), '');
    final cleanAway =
        gameSetupAdapter.awayTeam.replaceAll(RegExp(r'[^\w]'), '');
    return '${cleanHome}_v_${cleanAway}_$timestamp.png';
  }

  Widget _buildGameDetailsContent() {
    return Consumer2<GameSetupAdapter, ScorePanelAdapter>(
      builder: (context, gameSetupProvider, scorePanelProvider, _) {
        // Get the current game events from the scoring state manager
        final ScoringStateManager scoringStateManager =
            ScoringStateManager.instance;
        final List<GameEvent> currentEvents = scoringStateManager.gameEvents;

        // Wrap in WidgetShotPlus for sharing capability
        return WidgetShotPlus(
          key: _gameDetailsKey,
          child: GameDetailsWidget.fromLiveData(events: currentEvents),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameSetupProvider = Provider.of<GameSetupAdapter>(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              '${gameSetupProvider.homeTeam} vs ${gameSetupProvider.awayTeam}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const Settings(title: 'Settings'),
                  ),
                );
                // Update game setup with current settings when returning
                if (context.mounted) {
                  final settingsProvider =
                      Provider.of<SettingsProvider>(context, listen: false);
                  final gameSetupProvider =
                      Provider.of<GameSetupAdapter>(context, listen: false);
                  gameSetupProvider.setQuarterMinutes(
                      settingsProvider.defaultQuarterMinutes);
                  gameSetupProvider.setIsCountdownTimer(
                      settingsProvider.defaultIsCountdownTimer);
                }
              },
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            Scoring(key: _scoringKey, title: 'Scoring'),
            _buildGameDetailsContent(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_score),
              label: 'Scoring',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.info_outline),
              label: 'Details',
            ),
          ],
        ),
        floatingActionButton: _currentIndex == 1 // Only show on Details tab
            ? FloatingActionButton(
                onPressed: _isSharing ? null : () => _shareGameDetails(context),
                tooltip: 'Share Game Details',
                child: _isSharing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share),
              )
            : null,
      ),
    );
  }
}
