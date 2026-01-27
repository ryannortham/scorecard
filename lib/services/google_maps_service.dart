// google maps static api url generation

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:scorecard/models/playhq.dart';
import 'package:scorecard/services/logger_service.dart';

/// generates google maps static api urls for address display
class GoogleMapsService {
  static String get _apiKey {
    final key = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    AppLogger.info(
      'API Key loaded: ${key.isNotEmpty ? "YES (${key.length} chars)" : "NO"}',
      component: 'GoogleMapsService',
    );
    return key;
  }

  /// generates static map image url for the given address
  static String getStaticMapUrl(
    Address address, {
    String? venueName,
    int width = 600,
    int height = 300,
    int zoom = 15,
    int scale = 2,
    String mapType = 'roadmap',
  }) {
    if (_apiKey.isEmpty) {
      AppLogger.error(
        'Google Maps API key is EMPTY!',
        component: 'GoogleMapsService',
      );
      throw Exception(
        'Google Maps API key not found. Please check your .env file.',
      );
    }

    final query =
        venueName != null && venueName.isNotEmpty
            ? address.getSearchQueryWithVenue(venueName)
            : address.googleMapsAddress;

    final location = Uri.encodeComponent(query);
    AppLogger.info(
      'Generating map URL for: $query',
      component: 'GoogleMapsService',
    );
    AppLogger.info(
      'Encoded location: $location',
      component: 'GoogleMapsService',
    );

    final url =
        'https://maps.googleapis.com/maps/api/staticmap?'
        'center=$location'
        '&zoom=$zoom'
        '&size=${width}x$height'
        '&scale=$scale'
        '&maptype=$mapType'
        '&markers=color:red%7C$location'
        '&key=$_apiKey';

    AppLogger.info(
      'Generated Static Map URL: $url',
      component: 'GoogleMapsService',
    );
    return url;
  }

  static bool get isConfigured => _apiKey.isNotEmpty;
}
