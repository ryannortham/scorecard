// displays team address with static map preview and directions button

import 'dart:io' show Platform;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:scorecard/models/playhq.dart';
import 'package:scorecard/services/google_maps_service.dart';
import 'package:scorecard/services/logger_service.dart';
import 'package:scorecard/theme/colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// displays the team's address with a static map preview and directions button
class TeamAddressSection extends StatelessWidget {
  const TeamAddressSection({
    required this.address,
    required this.teamName,
    super.key,
  });

  final Address address;
  final String teamName;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: context.colors.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: context.colors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Address',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              address.displayAddress,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Google Maps Static Image
            if (GoogleMapsService.isConfigured) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: GoogleMapsService.getStaticMapUrl(
                    address,
                    venueName: teamName,
                    height: 250,
                  ),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        width: double.infinity,
                        height: 200,
                        color: context.colors.surfaceContainerHighest,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  errorWidget: (context, url, error) {
                    AppLogger.error(
                      'Map image failed to load: $error',
                      component: 'TeamAddressSection',
                    );
                    return Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 48,
                            color: context.colors.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Map preview unavailable',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            Center(
              child: FilledButton.icon(
                onPressed: () => _openDirections(context),
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Directions'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDirections(BuildContext context) async {
    try {
      Uri? uri;

      // Use enhanced query with venue name for better search accuracy
      final query = Uri.encodeComponent(
        address.getSearchQueryWithVenue(teamName),
      );

      if (Platform.isAndroid) {
        // Use geo: URI for Android - opens any maps app
        uri = Uri.parse('geo:0,0?q=$query');
      } else if (Platform.isIOS) {
        // Try Google Maps app first, fallback to Apple Maps
        final googleMapsUri = Uri.parse('comgooglemaps://?q=$query');

        if (await canLaunchUrl(googleMapsUri)) {
          uri = googleMapsUri;
        } else {
          // Fallback to Apple Maps
          uri = Uri.parse('http://maps.apple.com/?q=$query');
        }
      } else {
        // Web and other platforms - use HTTPS URL
        uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$query',
        );
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open maps for directions'),
            ),
          );
        }
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening directions: $e')));
      }
    }
  }
}
