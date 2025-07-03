/// Data models for PlayHQ GraphQL API responses
class PlayHQSearchResponse {
  final SearchMeta meta;
  final List<Organisation> results;

  PlayHQSearchResponse({required this.meta, required this.results});

  factory PlayHQSearchResponse.fromJson(Map<String, dynamic> json) {
    final searchData = json['data']['search'];
    return PlayHQSearchResponse(
      meta: SearchMeta.fromJson(searchData['meta']),
      results:
          (searchData['results'] as List)
              .map((item) => Organisation.fromJson(item))
              .toList(),
    );
  }
}

class SearchMeta {
  final int page;
  final int totalPages;
  final int totalRecords;

  SearchMeta({
    required this.page,
    required this.totalPages,
    required this.totalRecords,
  });

  factory SearchMeta.fromJson(Map<String, dynamic> json) {
    return SearchMeta(
      page: json['page'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      totalRecords: json['totalRecords'] ?? 0,
    );
  }
}

class Organisation {
  final String id;
  final String routingCode;
  final String name;
  final String type;
  final Logo? logo;
  final Tenant? tenant;

  Organisation({
    required this.id,
    required this.routingCode,
    required this.name,
    required this.type,
    this.logo,
    this.tenant,
  });

  factory Organisation.fromJson(Map<String, dynamic> json) {
    return Organisation(
      id: json['id'] ?? '',
      routingCode: json['routingCode'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      logo: json['logo'] != null ? Logo.fromJson(json['logo']) : null,
      tenant: json['tenant'] != null ? Tenant.fromJson(json['tenant']) : null,
    );
  }

  /// Get the most appropriate logo URL for 48x48 display
  String? get logoUrl48 {
    if (logo?.sizes.isNotEmpty == true) {
      // Find the smallest logo that's at least 48x48, or the largest available
      final sortedSizes =
          logo!.sizes..sort((a, b) {
            final aSize = a.dimensions.width * a.dimensions.height;
            final bSize = b.dimensions.width * b.dimensions.height;
            return aSize.compareTo(bSize);
          });

      // Find first size >= 48x48, or use the largest available
      final appropriateSize = sortedSizes.firstWhere(
        (size) => size.dimensions.width >= 48 && size.dimensions.height >= 48,
        orElse: () => sortedSizes.last,
      );

      return appropriateSize.url;
    }

    // Fallback to tenant logo if available
    return tenant?.logoUrl48;
  }

  /// Get the most appropriate logo URL for 32x32 display
  String? get logoUrl32 {
    if (logo?.sizes.isNotEmpty == true) {
      // Find the smallest logo that's at least 32x32, or the largest available
      final sortedSizes =
          logo!.sizes..sort((a, b) {
            final aSize = a.dimensions.width * a.dimensions.height;
            final bSize = b.dimensions.width * b.dimensions.height;
            return aSize.compareTo(bSize);
          });

      // Find first size >= 32x32, or use the largest available
      final appropriateSize = sortedSizes.firstWhere(
        (size) => size.dimensions.width >= 32 && size.dimensions.height >= 32,
        orElse: () => sortedSizes.last,
      );

      return appropriateSize.url;
    }

    // Fallback to tenant logo if available
    return tenant?.logoUrl32;
  }
}

class Logo {
  final List<LogoSize> sizes;

  Logo({required this.sizes});

  factory Logo.fromJson(Map<String, dynamic> json) {
    return Logo(
      sizes:
          (json['sizes'] as List? ?? [])
              .map((item) => LogoSize.fromJson(item))
              .toList(),
    );
  }
}

class LogoSize {
  final String url;
  final Dimensions dimensions;

  LogoSize({required this.url, required this.dimensions});

  factory LogoSize.fromJson(Map<String, dynamic> json) {
    return LogoSize(
      url: json['url'] ?? '',
      dimensions: Dimensions.fromJson(json['dimensions']),
    );
  }
}

class Dimensions {
  final int width;
  final int height;

  Dimensions({required this.width, required this.height});

  factory Dimensions.fromJson(Map<String, dynamic> json) {
    return Dimensions(width: json['width'] ?? 0, height: json['height'] ?? 0);
  }
}

class Tenant {
  final String id;
  final String name;
  final Logo? logo;
  final String slug;

  Tenant({required this.id, required this.name, this.logo, required this.slug});

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      logo: json['logo'] != null ? Logo.fromJson(json['logo']) : null,
      slug: json['slug'] ?? '',
    );
  }

  /// Get the most appropriate logo URL for 48x48 display
  String? get logoUrl48 {
    if (logo?.sizes.isNotEmpty == true) {
      final sortedSizes =
          logo!.sizes..sort((a, b) {
            final aSize = a.dimensions.width * a.dimensions.height;
            final bSize = b.dimensions.width * b.dimensions.height;
            return aSize.compareTo(bSize);
          });

      final appropriateSize = sortedSizes.firstWhere(
        (size) => size.dimensions.width >= 48 && size.dimensions.height >= 48,
        orElse: () => sortedSizes.last,
      );

      return appropriateSize.url;
    }
    return null;
  }

  /// Get the most appropriate logo URL for 32x32 display
  String? get logoUrl32 {
    if (logo?.sizes.isNotEmpty == true) {
      final sortedSizes =
          logo!.sizes..sort((a, b) {
            final aSize = a.dimensions.width * a.dimensions.height;
            final bSize = b.dimensions.width * b.dimensions.height;
            return aSize.compareTo(bSize);
          });

      final appropriateSize = sortedSizes.firstWhere(
        (size) => size.dimensions.width >= 32 && size.dimensions.height >= 32,
        orElse: () => sortedSizes.last,
      );

      return appropriateSize.url;
    }
    return null;
  }
}

/// Search filter for PlayHQ API
class SearchFilter {
  final SearchMeta meta;
  final OrganisationFilter organisation;

  SearchFilter({required this.meta, required this.organisation});

  Map<String, dynamic> toJson() {
    return {
      'meta': {
        'limit': meta.totalRecords > 0 ? meta.totalRecords : 8,
        'page': meta.page > 0 ? meta.page : 1,
      },
      'organisation': {
        'query': organisation.query,
        'types': organisation.types,
        'sports': organisation.sports,
      },
    };
  }
}

class OrganisationFilter {
  final String query;
  final List<String> types;
  final List<String> sports;

  OrganisationFilter({
    required this.query,
    required this.types,
    required this.sports,
  });
}
