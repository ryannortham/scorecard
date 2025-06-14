import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/widgets/game_details/game_details_widget.dart';

/// Service for capturing screenshots of widgets by rendering them briefly
class ScreenshotService {
  static final ScreenshotService _instance = ScreenshotService._internal();
  factory ScreenshotService() => _instance;
  ScreenshotService._internal();

  OverlayEntry? _overlayEntry;
  GlobalKey? _screenshotKey;

  /// Captures a screenshot by briefly rendering a widget in an overlay
  Future<Uint8List?> _captureWidgetScreenshot({
    required Widget widget,
    required ThemeData themeData,
    Size? size,
  }) async {
    final Completer<Uint8List?> completer = Completer<Uint8List?>();

    // Use a reasonable default size if none provided
    size ??= const Size(400, 800);

    _screenshotKey = GlobalKey();

    // Create overlay with the widget to capture
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        // Position off-screen to the right and down
        left: MediaQuery.of(context).size.width + 1000,
        top: MediaQuery.of(context).size.height + 1000,
        child: Material(
          child: Theme(
            data: themeData,
            child: SizedBox(
              width: size!.width,
              height: size.height,
              child: RepaintBoundary(
                key: _screenshotKey,
                child: widget,
              ),
            ),
          ),
        ),
      ),
    );

    // Get overlay and insert our widget
    final overlay = Overlay.of(navigatorKey.currentContext ??
        WidgetsBinding.instance.focusManager.primaryFocus?.context ??
        WidgetsBinding.instance.rootElement!);

    overlay.insert(_overlayEntry!);

    // Wait a moment for the widget to render
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // Capture the screenshot
      final RenderRepaintBoundary boundary = _screenshotKey!.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        completer.complete(byteData.buffer.asUint8List());
      } else {
        completer.complete(null);
      }
    } catch (e) {
      debugPrint('Error capturing screenshot: $e');
      completer.complete(null);
    } finally {
      // Clean up overlay
      _overlayEntry?.remove();
      _overlayEntry = null;
      _screenshotKey = null;
    }

    return completer.future;
  }

  /// Captures a screenshot of the game details widget and shares it
  Future<void> shareGameDetails({
    required GameRecord game,
    required String shareText,
    required ThemeData themeData,
  }) async {
    try {
      final widget = GameDetailsWidget.fromStaticData(game: game);

      final imageBytes = await _captureWidgetScreenshot(
        widget: widget,
        themeData: themeData,
        size: const Size(400, 800),
      );

      if (imageBytes != null) {
        // Save to temporary file for sharing
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${tempDir.path}/game_details_$timestamp.png');
        await file.writeAsBytes(imageBytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: shareText,
        );
      } else {
        // Fallback to text-only sharing
        await Share.share(shareText);
      }
    } catch (e) {
      debugPrint('Error sharing game details: $e');
      // Fallback to text-only sharing
      await Share.share(shareText);
    }
  }

  /// Captures a screenshot of the game details widget and saves it to gallery
  Future<void> saveGameDetailsToGallery({
    required GameRecord game,
    required ThemeData themeData,
  }) async {
    try {
      final widget = GameDetailsWidget.fromStaticData(game: game);

      final imageBytes = await _captureWidgetScreenshot(
        widget: widget,
        themeData: themeData,
        size: const Size(400, 800),
      );

      if (imageBytes != null) {
        // Save to temporary file first
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${tempDir.path}/game_details_$timestamp.png');
        await file.writeAsBytes(imageBytes);

        // Save to gallery
        await Gal.putImage(file.path);
      } else {
        throw Exception('Failed to capture screenshot');
      }
    } catch (e) {
      debugPrint('Error saving game details: $e');
      rethrow;
    }
  }

  /// Captures a live game screenshot using current provider data
  Future<void> shareLiveGameDetails({
    required String homeTeam,
    required String awayTeam,
    required DateTime gameDate,
    required int quarterMinutes,
    required bool isCountdownTimer,
    required List<GameEvent> events,
    required int homeGoals,
    required int homeBehinds,
    required int awayGoals,
    required int awayBehinds,
    required String shareText,
    required ThemeData themeData,
  }) async {
    try {
      // Create a GameRecord from the live data for screenshot
      final liveGame = GameRecord(
        id: 'temp_live_game',
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        date: gameDate,
        homeGoals: homeGoals,
        homeBehinds: homeBehinds,
        awayGoals: awayGoals,
        awayBehinds: awayBehinds,
        events: events,
        quarterMinutes: quarterMinutes,
        isCountdownTimer: isCountdownTimer,
      );

      final widget = GameDetailsWidget.fromStaticData(game: liveGame);

      final imageBytes = await _captureWidgetScreenshot(
        widget: widget,
        themeData: themeData,
        size: const Size(400, 800),
      );

      if (imageBytes != null) {
        // Save to temporary file for sharing
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${tempDir.path}/live_game_$timestamp.png');
        await file.writeAsBytes(imageBytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: shareText,
        );
      } else {
        // Fallback to text-only sharing
        await Share.share(shareText);
      }
    } catch (e) {
      debugPrint('Error sharing live game details: $e');
      // Fallback to text-only sharing
      await Share.share(shareText);
    }
  }

  /// Saves a live game screenshot to gallery using current provider data
  Future<void> saveLiveGameToGallery({
    required String homeTeam,
    required String awayTeam,
    required DateTime gameDate,
    required int quarterMinutes,
    required bool isCountdownTimer,
    required List<GameEvent> events,
    required int homeGoals,
    required int homeBehinds,
    required int awayGoals,
    required int awayBehinds,
    required ThemeData themeData,
  }) async {
    try {
      // Create a GameRecord from the live data for screenshot
      final liveGame = GameRecord(
        id: 'temp_live_game',
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        date: gameDate,
        homeGoals: homeGoals,
        homeBehinds: homeBehinds,
        awayGoals: awayGoals,
        awayBehinds: awayBehinds,
        events: events,
        quarterMinutes: quarterMinutes,
        isCountdownTimer: isCountdownTimer,
      );

      final widget = GameDetailsWidget.fromStaticData(game: liveGame);

      final imageBytes = await _captureWidgetScreenshot(
        widget: widget,
        themeData: themeData,
        size: const Size(400, 800),
      );

      if (imageBytes != null) {
        // Save to temporary file first
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${tempDir.path}/live_game_$timestamp.png');
        await file.writeAsBytes(imageBytes);

        // Save to gallery
        await Gal.putImage(file.path);
      } else {
        throw Exception('Failed to capture screenshot');
      }
    } catch (e) {
      debugPrint('Error saving live game details: $e');
      rethrow;
    }
  }
}

// Global navigator key for accessing overlay
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
