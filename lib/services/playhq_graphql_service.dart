import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:scorecard/models/playhq_models.dart';
import 'package:scorecard/services/app_logger.dart';

/// Service for interacting with PlayHQ GraphQL API
class PlayHQGraphQLService {
  static const String _baseUrl = 'https://search.playhq.com/graphql';

  static const String _searchQuery = '''
    query search(\$filter: SearchFilter!) {
      search(filter: \$filter) {
        meta {
          page
          totalPages
          totalRecords
          __typename
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
                  __typename
                }
                __typename
              }
              __typename
            }
            tenant {
              id
              name
              logo {
                sizes {
                  url
                  dimensions {
                    width
                    height
                    __typename
                  }
                  __typename
                }
                __typename
              }
              slug
              __typename
            }
            __typename
          }
          __typename
        }
        __typename
      }
    }
  ''';

  static final Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0',
    'Accept': '*/*',
    'Accept-Language': 'en-US,en;q=0.5',
    'Accept-Encoding': 'gzip, deflate, br, zstd',
    'Content-Type': 'application/json',
    'Origin': 'https://www.playhq.com',
    'DNT': '1',
    'Sec-GPC': '1',
    'Connection': 'keep-alive',
    'Sec-Fetch-Dest': 'empty',
    'Sec-Fetch-Mode': 'cors',
    'Sec-Fetch-Site': 'same-site',
    'Priority': 'u=4',
    'TE': 'trailers',
  };

  /// Search for football clubs/associations
  static Future<PlayHQSearchResponse?> searchClubs({
    required String query,
    List<String> types = const ['ASSOCIATION', 'CLUB'],
    List<String> sports = const ['AFL'],
    int limit = 20,
    int page = 1,
  }) async {
    try {
      AppLogger.info(
        'Searching PlayHQ for: "$query"',
        component: 'PlayHQGraphQLService',
      );

      final searchFilter = SearchFilter(
        meta: SearchMeta(page: page, totalPages: 0, totalRecords: limit),
        organisation: OrganisationFilter(
          query: query,
          types: types,
          sports: sports,
        ),
      );

      final requestBody = {
        'operationName': 'search',
        'variables': {'filter': searchFilter.toJson()},
        'query': _searchQuery,
      };

      AppLogger.debug(
        'GraphQL request: ${jsonEncode(requestBody)}',
        component: 'PlayHQGraphQLService',
      );

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      AppLogger.debug(
        'Response status: ${response.statusCode}',
        component: 'PlayHQGraphQLService',
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        AppLogger.debug(
          'Response data: ${jsonEncode(jsonResponse)}',
          component: 'PlayHQGraphQLService',
        );

        // Check for GraphQL errors
        if (jsonResponse['errors'] != null) {
          AppLogger.error(
            'GraphQL errors: ${jsonResponse['errors']}',
            component: 'PlayHQGraphQLService',
          );
          return null;
        }

        final searchResponse = PlayHQSearchResponse.fromJson(jsonResponse);

        AppLogger.info(
          'Found ${searchResponse.results.length} clubs for query: "$query"',
          component: 'PlayHQGraphQLService',
        );

        return searchResponse;
      } else {
        AppLogger.error(
          'HTTP error: ${response.statusCode} - ${response.body}',
          component: 'PlayHQGraphQLService',
        );
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error searching clubs: $e',
        component: 'PlayHQGraphQLService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Search specifically for AFL clubs
  static Future<PlayHQSearchResponse?> searchAFLClubs({
    required String query,
    int limit = 20,
    int page = 1,
  }) {
    return searchClubs(
      query: query,
      types: ['CLUB'],
      sports: ['AFL'],
      limit: limit,
      page: page,
    );
  }
}
