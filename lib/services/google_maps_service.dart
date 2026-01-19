import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/playhq_models.dart';
import 'app_logger.dart';

/// Service for generating Google Maps Static API URLs
class GoogleMapsService {
  /// Get the Google Maps API key from environment variables
  static String get _apiKey {
    final key = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    AppLogger.info(
      'API Key loaded: ${key.isNotEmpty ? "YES (${key.length} chars)" : "NO"}',
      component: 'GoogleMapsService',
    );
    return key;
  }

  /// Generate a static map image URL for the given address
  ///
  /// Parameters:
  /// - [address]: The address to show on the map
  /// - [width]: Image width in pixels (default: 600)
  /// - [height]: Image height in pixels (default: 300)
  /// - [zoom]: Map zoom level 1-21 (default: 15)
  /// - [scale]: Image scale factor 1 or 2 for retina displays (default: 2)
  /// - [mapType]: Map type - roadmap, satellite, hybrid, terrain (default: roadmap)
  static String getStaticMapUrl(
    Address address, {
    int width = 600,
    int height = 300,
    int zoom = 15,
    int scale = 2,
    String mapType = 'roadmap',
  }) {
    if (_apiKey.isEmpty) {
      AppLogger.error('Google Maps API key is EMPTY!', component: 'GoogleMapsService');
      throw Exception('Google Maps API key not found. Please check your .env file.');
    }

    // Use the googleMapsAddress property for better geocoding
    final location = Uri.encodeComponent(address.googleMapsAddress);
    AppLogger.info('Generating map URL for: ${address.googleMapsAddress}', component: 'GoogleMapsService');
    AppLogger.info('Encoded location: $location', component: 'GoogleMapsService');

    // Build the Static Maps API URL
    final url =
        'https://maps.googleapis.com/maps/api/staticmap?'
        'center=$location'
        '&zoom=$zoom'
        '&size=${width}x$height'
        '&scale=$scale'
        '&maptype=$mapType'
        '&markers=color:red%7C$location'
        '&key=$_apiKey';

    AppLogger.info('Generated Static Map URL: $url', component: 'GoogleMapsService');
    return url;
  }

  /// Check if the API key is configured
  static bool get isConfigured => _apiKey.isNotEmpty;
}
