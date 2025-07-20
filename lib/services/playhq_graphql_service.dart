import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/playhq_models.dart';
import 'app_logger.dart';

class PlayHQGraphQLService {
  static const String _searchUrl = 'https://search.playhq.com/graphql';
  static const String _apiUrl = 'https://api.playhq.com/graphql';

  static const Map<String, String> _searchHeaders = {
    'Content-Type': 'application/json',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0',
    'Accept': '*/*',
    'Accept-Language': 'en-US,en;q=0.5',
    'Accept-Encoding': 'gzip, deflate, br',
    'Origin': 'https://www.playhq.com',
    'DNT': '1',
    'Connection': 'keep-alive',
    'Sec-Fetch-Dest': 'empty',
    'Sec-Fetch-Mode': 'cors',
    'Sec-Fetch-Site': 'same-site',
  };

  static const Map<String, String> _apiHeaders = {
    'Content-Type': 'application/json',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0',
    'Accept': '*/*',
    'Accept-Language': 'en-US,en;q=0.5',
    'Accept-Encoding': 'gzip, deflate, br',
    'Origin': 'https://www.playhq.com',
    'DNT': '1',
    'Connection': 'keep-alive',
    'Sec-Fetch-Dest': 'empty',
    'Sec-Fetch-Mode': 'cors',
    'Sec-Fetch-Site': 'same-site',
    'tenant': 'afl',
  };

  /// Search for AFL clubs using GraphQL
  static Future<PlayHQSearchResponse> searchAFLClubs(String searchTerm) async {
    const query = '''
      query search(\$filter: SearchFilter!) {
        search(filter: \$filter) {
          meta {
            page
            totalPages
            totalRecords
          }
          results {
            ... on Organisation {
              id
              routingCode
              name
              type
              logo {
                sizes {
                  url
                  dimensions {
                    width
                    height
                  }
                }
              }
              tenant {
                id
                name
                slug
              }
            }
          }
        }
      }
    ''';

    final variables = {
      'filter': {
        'meta': {'limit': 10, 'page': 1},
        'organisation': {
          'query': searchTerm,
          'types': ['ASSOCIATION', 'CLUB'],
          'sports': ['AFL'],
        },
      },
    };

    final body = {'query': query, 'variables': variables};

    AppLogger.debug('PlayHQ Search Request', component: 'PlayHQGraphQLService');
    AppLogger.debug('URL: $_searchUrl', component: 'PlayHQGraphQLService');
    AppLogger.debug(
      'Headers: $_searchHeaders',
      component: 'PlayHQGraphQLService',
    );
    AppLogger.debug(
      'Body: ${json.encode(body)}',
      component: 'PlayHQGraphQLService',
    );

    try {
      final response = await http.post(
        Uri.parse(_searchUrl),
        headers: _searchHeaders,
        body: json.encode(body),
      );

      AppLogger.debug(
        'Search Response Status: ${response.statusCode}',
        component: 'PlayHQGraphQLService',
      );
      AppLogger.debug(
        'Search Response Body: ${response.body}',
        component: 'PlayHQGraphQLService',
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return PlayHQSearchResponse.fromJson(jsonData);
      } else {
        throw Exception(
          'Failed to search clubs: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Search Error: $e',
        component: 'PlayHQGraphQLService',
        error: e,
      );
      throw Exception('Error searching clubs: $e');
    }
  }

  /// Get organisation details including address using discoverOrganisation query
  static Future<OrganisationDetailsResponse> getOrganisationDetails(
    String organisationCode,
  ) async {
    const query = '''
      query discoverOrganisation(\$organisationCode: String!) {
        discoverOrganisation(code: \$organisationCode) {
          id
          type
          name
          email
          contactNumber
          websiteUrl
          address {
            id
            line1
            suburb
            postcode
            state
            country
          }
          logo {
            sizes {
              url
              dimensions {
                width
                height
              }
            }
          }
          contacts {
            id
            firstName
            lastName
            position
            email
            phone
          }
          shopVisible
        }
      }
    ''';

    final variables = {'organisationCode': organisationCode};

    final body = {'query': query, 'variables': variables};

    AppLogger.debug(
      'PlayHQ Org Details Request',
      component: 'PlayHQGraphQLService',
    );
    AppLogger.debug('URL: $_apiUrl', component: 'PlayHQGraphQLService');
    AppLogger.debug('Headers: $_apiHeaders', component: 'PlayHQGraphQLService');
    AppLogger.debug(
      'Body: ${json.encode(body)}',
      component: 'PlayHQGraphQLService',
    );

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: _apiHeaders,
        body: json.encode(body),
      );

      AppLogger.debug(
        'Org Details Response Status: ${response.statusCode}',
        component: 'PlayHQGraphQLService',
      );
      AppLogger.debug(
        'Org Details Response Body: ${response.body}',
        component: 'PlayHQGraphQLService',
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return OrganisationDetailsResponse.fromJson(jsonData);
      } else {
        throw Exception(
          'Failed to get organisation details: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Org Details Error: $e',
        component: 'PlayHQGraphQLService',
        error: e,
      );
      throw Exception('Error getting organisation details: $e');
    }
  }
}
