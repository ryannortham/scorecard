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
  final Address? address;

  Organisation({
    required this.id,
    required this.routingCode,
    required this.name,
    required this.type,
    this.logo,
    this.tenant,
    this.address,
  });

  factory Organisation.fromJson(Map<String, dynamic> json) {
    return Organisation(
      id: json['id'] ?? '',
      routingCode: json['routingCode'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      logo: json['logo'] != null ? Logo.fromJson(json['logo']) : null,
      tenant: json['tenant'] != null ? Tenant.fromJson(json['tenant']) : null,
      address:
          json['address'] != null ? Address.fromJson(json['address']) : null,
    );
  }

  /// Get the most appropriate logo URL for 48x48 display
  String? get logoUrl48 {
    final logoSizes = logo?.sizes;
    if (logoSizes?.isNotEmpty == true) {
      // Find the smallest logo that's at least 48x48, or the largest available
      final sortedSizes = List<LogoSize>.from(logoSizes!)..sort((a, b) {
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
    final logoSizes = logo?.sizes;
    if (logoSizes?.isNotEmpty == true) {
      // Find the smallest logo that's at least 32x32, or the largest available
      final sortedSizes = List<LogoSize>.from(logoSizes!)..sort((a, b) {
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

  /// Get the most appropriate logo URL for 128x128 display (watermarks)
  String? get logoUrl128 {
    final logoSizes = logo?.sizes;
    if (logoSizes?.isNotEmpty == true) {
      // Find the smallest logo that's at least 128x128, or the largest available
      final sortedSizes = List<LogoSize>.from(logoSizes!)..sort((a, b) {
        final aSize = a.dimensions.width * a.dimensions.height;
        final bSize = b.dimensions.width * b.dimensions.height;
        return aSize.compareTo(bSize);
      });

      // Find first size >= 128x128, or use the largest available
      final appropriateSize = sortedSizes.firstWhere(
        (size) => size.dimensions.width >= 128 && size.dimensions.height >= 128,
        orElse: () => sortedSizes.last,
      );

      return appropriateSize.url;
    }

    // Fallback to tenant logo if available
    return tenant?.logoUrl128;
  }

  /// Get the most appropriate logo URL for 256x256 display (large watermarks)
  String? get logoUrl256 {
    final logoSizes = logo?.sizes;
    if (logoSizes?.isNotEmpty == true) {
      // Find the smallest logo that's at least 256x256, or the largest available
      final sortedSizes = List<LogoSize>.from(logoSizes!)..sort((a, b) {
        final aSize = a.dimensions.width * a.dimensions.height;
        final bSize = b.dimensions.width * b.dimensions.height;
        return aSize.compareTo(bSize);
      });

      // Find first size >= 256x256, or use the largest available
      final appropriateSize = sortedSizes.firstWhere(
        (size) => size.dimensions.width >= 256 && size.dimensions.height >= 256,
        orElse: () => sortedSizes.last,
      );

      return appropriateSize.url;
    }

    // Fallback to tenant logo if available
    return tenant?.logoUrl256;
  }

  /// Get the largest available logo URL for watermarks (prefers 256, falls back to 128, then smaller)
  String? get logoUrlLarge {
    return logoUrl256 ?? logoUrl128 ?? logoUrl48 ?? logoUrl32;
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

  Map<String, dynamic> toJson() {
    return {'sizes': sizes.map((size) => size.toJson()).toList()};
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

  Map<String, dynamic> toJson() {
    return {'url': url, 'dimensions': dimensions.toJson()};
  }
}

class Dimensions {
  final int width;
  final int height;

  Dimensions({required this.width, required this.height});

  factory Dimensions.fromJson(Map<String, dynamic> json) {
    return Dimensions(width: json['width'] ?? 0, height: json['height'] ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'width': width, 'height': height};
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
    final logoSizes = logo?.sizes;
    if (logoSizes?.isNotEmpty == true) {
      final sortedSizes = List<LogoSize>.from(logoSizes!)..sort((a, b) {
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
    final logoSizes = logo?.sizes;
    if (logoSizes?.isNotEmpty == true) {
      final sortedSizes = List<LogoSize>.from(logoSizes!)..sort((a, b) {
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

  /// Get the most appropriate logo URL for 128x128 display (watermarks)
  String? get logoUrl128 {
    final logoSizes = logo?.sizes;
    if (logoSizes?.isNotEmpty == true) {
      final sortedSizes = List<LogoSize>.from(logoSizes!)..sort((a, b) {
        final aSize = a.dimensions.width * a.dimensions.height;
        final bSize = b.dimensions.width * b.dimensions.height;
        return aSize.compareTo(bSize);
      });

      final appropriateSize = sortedSizes.firstWhere(
        (size) => size.dimensions.width >= 128 && size.dimensions.height >= 128,
        orElse: () => sortedSizes.last,
      );

      return appropriateSize.url;
    }
    return null;
  }

  /// Get the most appropriate logo URL for 256x256 display (large watermarks)
  String? get logoUrl256 {
    final logoSizes = logo?.sizes;
    if (logoSizes?.isNotEmpty == true) {
      final sortedSizes = List<LogoSize>.from(logoSizes!)..sort((a, b) {
        final aSize = a.dimensions.width * a.dimensions.height;
        final bSize = b.dimensions.width * b.dimensions.height;
        return aSize.compareTo(bSize);
      });

      final appropriateSize = sortedSizes.firstWhere(
        (size) => size.dimensions.width >= 256 && size.dimensions.height >= 256,
        orElse: () => sortedSizes.last,
      );

      return appropriateSize.url;
    }
    return null;
  }

  /// Get the largest available logo URL for watermarks (prefers 256, falls back to 128, then smaller)
  String? get logoUrlLarge {
    return logoUrl256 ?? logoUrl128 ?? logoUrl48 ?? logoUrl32;
  }
}

/// Address model for organization/team location
class Address {
  final String id;
  final String line1;
  final String suburb;
  final String postcode;
  final String state;
  final String country;

  Address({
    required this.id,
    required this.line1,
    required this.suburb,
    required this.postcode,
    required this.state,
    required this.country,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? '',
      line1: json['line1'] ?? '',
      suburb: json['suburb'] ?? '',
      postcode: json['postcode'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'line1': line1,
      'suburb': suburb,
      'postcode': postcode,
      'state': state,
      'country': country,
    };
  }

  /// Get formatted address string for display
  String get displayAddress {
    final parts = <String>[];
    if (line1.isNotEmpty) parts.add(line1);
    if (suburb.isNotEmpty) parts.add(suburb);
    if (state.isNotEmpty && postcode.isNotEmpty) {
      parts.add('$state $postcode');
    } else if (state.isNotEmpty) {
      parts.add(state);
    } else if (postcode.isNotEmpty) {
      parts.add(postcode);
    }
    if (country.isNotEmpty && country != 'Australia') parts.add(country);
    return parts.join(', ');
  }

  /// Get formatted address for Google Maps search
  String get googleMapsAddress {
    final parts = <String>[];
    if (line1.isNotEmpty) parts.add(line1);
    if (suburb.isNotEmpty) parts.add(suburb);
    if (state.isNotEmpty) parts.add(state);
    if (postcode.isNotEmpty) parts.add(postcode);
    if (country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address &&
        other.id == id &&
        other.line1 == line1 &&
        other.suburb == suburb &&
        other.postcode == postcode &&
        other.state == state &&
        other.country == country;
  }

  @override
  int get hashCode => Object.hash(id, line1, suburb, postcode, state, country);

  @override
  String toString() => 'Address($displayAddress)';
}

/// Extended organisation details with address and contact information
class OrganisationDetails {
  final String id;
  final String type;
  final String name;
  final String email;
  final String contactNumber;
  final String websiteUrl;
  final Address? address;
  final Logo? logo;
  final bool shopVisible;

  OrganisationDetails({
    required this.id,
    required this.type,
    required this.name,
    required this.email,
    required this.contactNumber,
    required this.websiteUrl,
    this.address,
    this.logo,
    required this.shopVisible,
  });

  factory OrganisationDetails.fromJson(Map<String, dynamic> json) {
    return OrganisationDetails(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
      websiteUrl: json['websiteUrl'] ?? '',
      address:
          json['address'] != null ? Address.fromJson(json['address']) : null,
      logo: json['logo'] != null ? Logo.fromJson(json['logo']) : null,
      shopVisible: json['shopVisible'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'email': email,
      'contactNumber': contactNumber,
      'websiteUrl': websiteUrl,
      'address': address?.toJson(),
      'logo': logo?.toJson(),
      'shopVisible': shopVisible,
    };
  }

  /// Get the most appropriate logo URL for 48x48 display
  String? get logoUrl48 {
    final logoSizes = logo?.sizes;
    if (logoSizes?.isNotEmpty == true) {
      final sortedSizes = List<LogoSize>.from(logoSizes!)..sort((a, b) {
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

  /// Get the largest available logo URL
  String? get logoUrlLarge {
    final logoSizes = logo?.sizes;
    if (logoSizes?.isNotEmpty == true) {
      final sortedSizes = List<LogoSize>.from(logoSizes!)..sort((a, b) {
        final aSize = a.dimensions.width * a.dimensions.height;
        final bSize = b.dimensions.width * b.dimensions.height;
        return bSize.compareTo(aSize); // Descending order
      });

      return sortedSizes.first.url;
    }
    return null;
  }
}

/// Response wrapper for organization details query
class OrganisationDetailsResponse {
  final OrganisationDetails? organisation;

  OrganisationDetailsResponse({this.organisation});

  factory OrganisationDetailsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return OrganisationDetailsResponse(
      organisation:
          data?['discoverOrganisation'] != null
              ? OrganisationDetails.fromJson(data['discoverOrganisation'])
              : null,
    );
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
