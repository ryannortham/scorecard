// playhq graphql api response models

import 'package:flutter/foundation.dart';

/// playhq search response wrapper
class PlayHQSearchResponse {
  PlayHQSearchResponse({required this.meta, required this.results});

  factory PlayHQSearchResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final searchData = data?['search'] as Map<String, dynamic>?;
    return PlayHQSearchResponse(
      meta: SearchMeta.fromJson(
        searchData?['meta'] as Map<String, dynamic>? ?? {},
      ),
      results:
          (searchData?['results'] as List? ?? [])
              .map(
                (item) =>
                    Organisation.fromJson(item as Map<String, dynamic>? ?? {}),
              )
              .toList(),
    );
  }
  final SearchMeta meta;
  final List<Organisation> results;
}

class SearchMeta {
  SearchMeta({
    required this.page,
    required this.totalPages,
    required this.totalRecords,
  });

  factory SearchMeta.fromJson(Map<String, dynamic> json) {
    return SearchMeta(
      page: (json['page'] as int?) ?? 0,
      totalPages: (json['totalPages'] as int?) ?? 0,
      totalRecords: (json['totalRecords'] as int?) ?? 0,
    );
  }
  final int page;
  final int totalPages;
  final int totalRecords;
}

class Organisation {
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
      id: (json['id'] as String?) ?? '',
      routingCode: (json['routingCode'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      type: (json['type'] as String?) ?? '',
      logo:
          json['logo'] != null
              ? Logo.fromJson(json['logo'] as Map<String, dynamic>)
              : null,
      tenant:
          json['tenant'] != null
              ? Tenant.fromJson(json['tenant'] as Map<String, dynamic>)
              : null,
      address:
          json['address'] != null
              ? Address.fromJson(json['address'] as Map<String, dynamic>)
              : null,
    );
  }
  final String id;
  final String routingCode;
  final String name;
  final String type;
  final Logo? logo;
  final Tenant? tenant;
  final Address? address;

  /// selects smallest logo at least targetSize, or largest available
  String? get logoUrl48 {
    final logoSizes = logo?.sizes;
    if (logoSizes?.isNotEmpty ?? false) {
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

    return tenant?.logoUrl48;
  }

  /// selects smallest logo at least 32x32
  String? get logoUrl32 {
    final logoSizes = logo?.sizes;
    if (logoSizes?.isNotEmpty ?? false) {
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

    return tenant?.logoUrl32;
  }

  /// selects smallest logo at least 128x128 for watermarks
  String? get logoUrl128 {
    final logoSizes = logo?.sizes;
    if (logoSizes?.isNotEmpty ?? false) {
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

    return tenant?.logoUrl128;
  }

  /// selects smallest logo at least 256x256 for large watermarks
  String? get logoUrl256 {
    final logoSizes = logo?.sizes;
    if (logoSizes?.isNotEmpty ?? false) {
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

    return tenant?.logoUrl256;
  }

  /// largest available logo, preferring 256 > 128 > 48 > 32
  String? get logoUrlLarge {
    return logoUrl256 ?? logoUrl128 ?? logoUrl48 ?? logoUrl32;
  }
}

class Logo {
  Logo({required this.sizes});

  factory Logo.fromJson(Map<String, dynamic> json) {
    return Logo(
      sizes:
          (json['sizes'] as List? ?? [])
              .map(
                (item) =>
                    LogoSize.fromJson(item as Map<String, dynamic>? ?? {}),
              )
              .toList(),
    );
  }
  final List<LogoSize> sizes;

  Map<String, dynamic> toJson() {
    return {'sizes': sizes.map((size) => size.toJson()).toList()};
  }
}

class LogoSize {
  LogoSize({required this.url, required this.dimensions});

  factory LogoSize.fromJson(Map<String, dynamic> json) {
    return LogoSize(
      url: (json['url'] as String?) ?? '',
      dimensions: Dimensions.fromJson(
        json['dimensions'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
  final String url;
  final Dimensions dimensions;

  Map<String, dynamic> toJson() {
    return {'url': url, 'dimensions': dimensions.toJson()};
  }
}

class Dimensions {
  Dimensions({required this.width, required this.height});

  factory Dimensions.fromJson(Map<String, dynamic> json) {
    return Dimensions(
      width: (json['width'] as int?) ?? 0,
      height: (json['height'] as int?) ?? 0,
    );
  }
  final int width;
  final int height;

  Map<String, dynamic> toJson() {
    return {'width': width, 'height': height};
  }
}

class Tenant {
  Tenant({required this.id, required this.name, required this.slug, this.logo});

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      logo:
          json['logo'] != null
              ? Logo.fromJson(json['logo'] as Map<String, dynamic>)
              : null,
      slug: (json['slug'] as String?) ?? '',
    );
  }
  final String id;
  final String name;
  final Logo? logo;
  final String slug;

  /// selects smallest logo at least 48x48
  String? get logoUrl48 {
    final logoSizes = logo?.sizes;
    if (logoSizes?.isNotEmpty ?? false) {
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

  /// selects smallest logo at least 32x32
  String? get logoUrl32 {
    final logoSizes = logo?.sizes;
    if (logoSizes?.isNotEmpty ?? false) {
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

  /// selects smallest logo at least 128x128
  String? get logoUrl128 {
    final logoSizes = logo?.sizes;
    if (logoSizes?.isNotEmpty ?? false) {
      final sortedSizes = List<LogoSize>.from(logoSizes!)..sort((a, b) {
        final aSize = a.dimensions.width * a.dimensions.height;
        final bSize = b.dimensions.width * b.dimensions.height;
        return aSize.compareTo(bSize);
      });

      final appropriateSize = sortedSizes.firstWhere(
        (size) {
          return size.dimensions.width >= 128 && size.dimensions.height >= 128;
        },
        orElse: () => sortedSizes.last,
      );

      return appropriateSize.url;
    }
    return null;
  }

  /// selects smallest logo at least 256x256
  String? get logoUrl256 {
    final logoSizes = logo?.sizes;
    if (logoSizes?.isNotEmpty ?? false) {
      final sortedSizes = List<LogoSize>.from(logoSizes!)..sort((a, b) {
        final aSize = a.dimensions.width * a.dimensions.height;
        final bSize = b.dimensions.width * b.dimensions.height;
        return aSize.compareTo(bSize);
      });

      final appropriateSize = sortedSizes.firstWhere(
        (size) {
          return size.dimensions.width >= 256 && size.dimensions.height >= 256;
        },
        orElse: () => sortedSizes.last,
      );

      return appropriateSize.url;
    }
    return null;
  }

  /// largest available logo, preferring 256 > 128 > 48 > 32
  String? get logoUrlLarge {
    return logoUrl256 ?? logoUrl128 ?? logoUrl48 ?? logoUrl32;
  }
}

/// organisation/team address details
@immutable
class Address {
  const Address({
    required this.id,
    required this.line1,
    required this.suburb,
    required this.postcode,
    required this.state,
    required this.country,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: (json['id'] as String?) ?? '',
      line1: (json['line1'] as String?) ?? '',
      suburb: (json['suburb'] as String?) ?? '',
      postcode: (json['postcode'] as String?) ?? '',
      state: (json['state'] as String?) ?? '',
      country: (json['country'] as String?) ?? '',
    );
  }
  final String id;
  final String line1;
  final String suburb;
  final String postcode;
  final String state;
  final String country;

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

  /// formatted address for display
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

  /// formatted address for google maps search
  String get googleMapsAddress {
    final parts = <String>[];
    if (line1.isNotEmpty) parts.add(line1);
    if (suburb.isNotEmpty) parts.add(suburb);
    if (state.isNotEmpty) parts.add(state);
    if (postcode.isNotEmpty) parts.add(postcode);
    if (country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }

  /// true if address has enough data for directions
  bool get isValidForDirections {
    return line1.isNotEmpty;
  }

  /// search query with venue name for better google maps accuracy
  String getSearchQueryWithVenue(String venueName) {
    final parts = <String>[];

    if (venueName.isNotEmpty) parts.add(venueName);
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

/// organisation details with address and contact information
class OrganisationDetails {
  OrganisationDetails({
    required this.id,
    required this.type,
    required this.name,
    required this.email,
    required this.contactNumber,
    required this.websiteUrl,
    required this.shopVisible,
    this.address,
    this.logo,
  });

  factory OrganisationDetails.fromJson(Map<String, dynamic> json) {
    return OrganisationDetails(
      id: (json['id'] as String?) ?? '',
      type: (json['type'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      contactNumber: (json['contactNumber'] as String?) ?? '',
      websiteUrl: (json['websiteUrl'] as String?) ?? '',
      address:
          json['address'] != null
              ? Address.fromJson(json['address'] as Map<String, dynamic>)
              : null,
      logo:
          json['logo'] != null
              ? Logo.fromJson(json['logo'] as Map<String, dynamic>)
              : null,
      shopVisible: (json['shopVisible'] as bool?) ?? false,
    );
  }
  final String id;
  final String type;
  final String name;
  final String email;
  final String contactNumber;
  final String websiteUrl;
  final Address? address;
  final Logo? logo;
  final bool shopVisible;

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

  /// selects smallest logo at least 48x48
  String? get logoUrl48 {
    final logoSizes = logo?.sizes;
    if (logoSizes?.isNotEmpty ?? false) {
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

  /// largest available logo
  String? get logoUrlLarge {
    final logoSizes = logo?.sizes;
    if (logoSizes?.isNotEmpty ?? false) {
      final sortedSizes = List<LogoSize>.from(logoSizes!)..sort((a, b) {
        final aSize = a.dimensions.width * a.dimensions.height;
        final bSize = b.dimensions.width * b.dimensions.height;
        return bSize.compareTo(aSize);
      });

      return sortedSizes.first.url;
    }
    return null;
  }
}

/// response wrapper for organisation details query
class OrganisationDetailsResponse {
  OrganisationDetailsResponse({this.organisation});

  factory OrganisationDetailsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return OrganisationDetailsResponse(
      organisation:
          data?['discoverOrganisation'] != null
              ? OrganisationDetails.fromJson(
                data!['discoverOrganisation'] as Map<String, dynamic>,
              )
              : null,
    );
  }
  final OrganisationDetails? organisation;
}
