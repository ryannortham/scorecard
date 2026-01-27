# PlayHQ GraphQL API Documentation

## Endpoint

```http
POST https://search.playhq.com/graphql
```

## Headers

```http
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0
Accept: */*
Accept-Language: en-US,en;q=0.5
Accept-Encoding: gzip, deflate, br, zstd
Content-Type: application/json
Origin: https://www.playhq.com
DNT: 1
Sec-GPC: 1
Connection: keep-alive
Sec-Fetch-Dest: empty
Sec-Fetch-Mode: cors
Sec-Fetch-Site: same-site
Priority: u=4
TE: trailers
```

## GraphQL Query

### Operation: `search`

```graphql
query search($filter: SearchFilter!) {
  search(filter: $filter) {
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
```

### Variables Example

```json
{
  "filter": {
    "meta": {
      "limit": 8,
      "page": 1
    },
    "organisation": {
      "query": "chelsea",
      "types": ["ASSOCIATION", "CLUB"],
      "sports": ["AFL"]
    }
  }
}
```

## Response Schema

```json
{
  "data": {
    "search": {
      "meta": {
        "page": 1,
        "totalPages": 1,
        "totalRecords": 3
      },
      "results": [
        {
          "id": "ORG123",
          "routingCode": "ROUTE123",
          "name": "Chelsea Football Club",
          "type": "CLUB",
          "logo": {
            "sizes": [
              {
                "url": "https://example.com/logo-32.png",
                "dimensions": {
                  "width": 32,
                  "height": 32
                }
              }
            ]
          },
          "tenant": {
            "id": "TENANT123",
            "name": "Local AFL League",
            "logo": {
              "sizes": [...]
            },
            "slug": "local-afl-league"
          }
        }
      ]
    }
  }
}
```

## Usage in Flutter App

The GraphQL service is implemented in:

- **Models**: `lib/models/playhq_models.dart`
- **Service**: `lib/services/playhq_graphql_service.dart`  
- **UI**: `lib/screens/add_team.dart`

### Example Usage

```dart
final response = await PlayHQGraphQLService.searchAFLClubs(
  query: 'chelsea',
  limit: 20,
);

if (response != null) {
  for (final team in response.results) {
    print('${team.name} - ${team.type}');
    if (team.logoUrl32 != null) {
      print('Logo: ${team.logoUrl32}');
    }
  }
}
```
