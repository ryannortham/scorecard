// tests for playhq api response models

import 'package:flutter_test/flutter_test.dart';
import 'package:scorecard/models/playhq_models.dart';

void main() {
  group('Address', () {
    group('fromJson', () {
      test('should parse complete JSON', () {
        final json = {
          'id': 'addr-123',
          'line1': '123 Main Street',
          'suburb': 'Richmond',
          'postcode': '3121',
          'state': 'VIC',
          'country': 'Australia',
        };

        final address = Address.fromJson(json);

        expect(address.id, equals('addr-123'));
        expect(address.line1, equals('123 Main Street'));
        expect(address.suburb, equals('Richmond'));
        expect(address.postcode, equals('3121'));
        expect(address.state, equals('VIC'));
        expect(address.country, equals('Australia'));
      });

      test('should default to empty strings for missing fields', () {
        final json = <String, dynamic>{};

        final address = Address.fromJson(json);

        expect(address.id, equals(''));
        expect(address.line1, equals(''));
        expect(address.suburb, equals(''));
        expect(address.postcode, equals(''));
        expect(address.state, equals(''));
        expect(address.country, equals(''));
      });

      test('should handle null values', () {
        final json = {
          'id': null,
          'line1': null,
          'suburb': null,
          'postcode': null,
          'state': null,
          'country': null,
        };

        final address = Address.fromJson(json);

        expect(address.id, equals(''));
        expect(address.line1, equals(''));
      });
    });

    group('toJson', () {
      test('should serialise to JSON correctly', () {
        final address = Address(
          id: 'addr-456',
          line1: '456 Test Road',
          suburb: 'Carlton',
          postcode: '3053',
          state: 'VIC',
          country: 'Australia',
        );

        final json = address.toJson();

        expect(json['id'], equals('addr-456'));
        expect(json['line1'], equals('456 Test Road'));
        expect(json['suburb'], equals('Carlton'));
        expect(json['postcode'], equals('3053'));
        expect(json['state'], equals('VIC'));
        expect(json['country'], equals('Australia'));
      });
    });

    group('round-trip serialisation', () {
      test('should preserve all data through JSON round-trip', () {
        final original = Address(
          id: 'addr-roundtrip',
          line1: '789 Circle Ave',
          suburb: 'Collingwood',
          postcode: '3066',
          state: 'VIC',
          country: 'Australia',
        );

        final json = original.toJson();
        final restored = Address.fromJson(json);

        expect(restored, equals(original));
      });
    });

    group('displayAddress', () {
      test('should format complete address', () {
        final address = Address(
          id: '1',
          line1: '123 Main Street',
          suburb: 'Richmond',
          postcode: '3121',
          state: 'VIC',
          country: 'Australia',
        );

        expect(
          address.displayAddress,
          equals('123 Main Street, Richmond, VIC 3121'),
        );
      });

      test('should exclude Australia from display', () {
        final address = Address(
          id: '1',
          line1: '123 Main Street',
          suburb: 'Richmond',
          postcode: '3121',
          state: 'VIC',
          country: 'Australia',
        );

        expect(address.displayAddress, isNot(contains('Australia')));
      });

      test('should include non-Australia countries', () {
        final address = Address(
          id: '1',
          line1: '123 Main Street',
          suburb: 'Auckland',
          postcode: '1010',
          state: '',
          country: 'New Zealand',
        );

        expect(address.displayAddress, contains('New Zealand'));
      });

      test('should handle missing line1', () {
        final address = Address(
          id: '1',
          line1: '',
          suburb: 'Richmond',
          postcode: '3121',
          state: 'VIC',
          country: 'Australia',
        );

        expect(address.displayAddress, equals('Richmond, VIC 3121'));
      });

      test('should handle missing suburb', () {
        final address = Address(
          id: '1',
          line1: '123 Main Street',
          suburb: '',
          postcode: '3121',
          state: 'VIC',
          country: 'Australia',
        );

        expect(address.displayAddress, equals('123 Main Street, VIC 3121'));
      });

      test('should handle only state (no postcode)', () {
        final address = Address(
          id: '1',
          line1: '123 Main Street',
          suburb: 'Richmond',
          postcode: '',
          state: 'VIC',
          country: 'Australia',
        );

        expect(
          address.displayAddress,
          equals('123 Main Street, Richmond, VIC'),
        );
      });

      test('should handle only postcode (no state)', () {
        final address = Address(
          id: '1',
          line1: '123 Main Street',
          suburb: 'Richmond',
          postcode: '3121',
          state: '',
          country: 'Australia',
        );

        expect(
          address.displayAddress,
          equals('123 Main Street, Richmond, 3121'),
        );
      });

      test('should handle empty address', () {
        final address = Address(
          id: '1',
          line1: '',
          suburb: '',
          postcode: '',
          state: '',
          country: '',
        );

        expect(address.displayAddress, equals(''));
      });
    });

    group('googleMapsAddress', () {
      test('should include all fields including country', () {
        final address = Address(
          id: '1',
          line1: '123 Main Street',
          suburb: 'Richmond',
          postcode: '3121',
          state: 'VIC',
          country: 'Australia',
        );

        expect(
          address.googleMapsAddress,
          equals('123 Main Street, Richmond, VIC, 3121, Australia'),
        );
      });

      test('should skip empty fields', () {
        final address = Address(
          id: '1',
          line1: '',
          suburb: 'Richmond',
          postcode: '',
          state: 'VIC',
          country: 'Australia',
        );

        expect(address.googleMapsAddress, equals('Richmond, VIC, Australia'));
      });
    });

    group('isValidForDirections', () {
      test('should return true when line1 is present', () {
        final address = Address(
          id: '1',
          line1: '123 Main Street',
          suburb: '',
          postcode: '',
          state: '',
          country: '',
        );

        expect(address.isValidForDirections, isTrue);
      });

      test('should return false when line1 is empty', () {
        final address = Address(
          id: '1',
          line1: '',
          suburb: 'Richmond',
          postcode: '3121',
          state: 'VIC',
          country: 'Australia',
        );

        expect(address.isValidForDirections, isFalse);
      });
    });

    group('getSearchQueryWithVenue', () {
      test('should prepend venue name to address', () {
        final address = Address(
          id: '1',
          line1: '123 Main Street',
          suburb: 'Richmond',
          postcode: '3121',
          state: 'VIC',
          country: 'Australia',
        );

        final query = address.getSearchQueryWithVenue('MCG');

        expect(query, startsWith('MCG'));
        expect(query, contains('123 Main Street'));
      });

      test('should work without venue name', () {
        final address = Address(
          id: '1',
          line1: '123 Main Street',
          suburb: 'Richmond',
          postcode: '3121',
          state: 'VIC',
          country: 'Australia',
        );

        final query = address.getSearchQueryWithVenue('');

        expect(query, isNot(startsWith(',')));
        expect(query, startsWith('123 Main Street'));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final address1 = Address(
          id: '1',
          line1: '123 Main',
          suburb: 'Richmond',
          postcode: '3121',
          state: 'VIC',
          country: 'Australia',
        );
        final address2 = Address(
          id: '1',
          line1: '123 Main',
          suburb: 'Richmond',
          postcode: '3121',
          state: 'VIC',
          country: 'Australia',
        );

        expect(address1, equals(address2));
      });

      test('should not be equal when any field differs', () {
        final address1 = Address(
          id: '1',
          line1: '123 Main',
          suburb: 'Richmond',
          postcode: '3121',
          state: 'VIC',
          country: 'Australia',
        );
        final address2 = Address(
          id: '1',
          line1: '456 Main',
          suburb: 'Richmond',
          postcode: '3121',
          state: 'VIC',
          country: 'Australia',
        );

        expect(address1, isNot(equals(address2)));
      });

      test('should have same hashCode for equal addresses', () {
        final address1 = Address(
          id: '1',
          line1: '123 Main',
          suburb: 'Richmond',
          postcode: '3121',
          state: 'VIC',
          country: 'Australia',
        );
        final address2 = Address(
          id: '1',
          line1: '123 Main',
          suburb: 'Richmond',
          postcode: '3121',
          state: 'VIC',
          country: 'Australia',
        );

        expect(address1.hashCode, equals(address2.hashCode));
      });
    });
  });

  group('Dimensions', () {
    test('should parse from JSON', () {
      final json = {'width': 100, 'height': 200};

      final dimensions = Dimensions.fromJson(json);

      expect(dimensions.width, equals(100));
      expect(dimensions.height, equals(200));
    });

    test('should default to 0 for missing dimensions', () {
      final json = <String, dynamic>{};

      final dimensions = Dimensions.fromJson(json);

      expect(dimensions.width, equals(0));
      expect(dimensions.height, equals(0));
    });

    test('should serialise to JSON', () {
      final dimensions = Dimensions(width: 150, height: 250);

      final json = dimensions.toJson();

      expect(json['width'], equals(150));
      expect(json['height'], equals(250));
    });
  });

  group('LogoSize', () {
    test('should parse from JSON', () {
      final json = {
        'url': 'https://example.com/logo.png',
        'dimensions': {'width': 64, 'height': 64},
      };

      final logoSize = LogoSize.fromJson(json);

      expect(logoSize.url, equals('https://example.com/logo.png'));
      expect(logoSize.dimensions.width, equals(64));
      expect(logoSize.dimensions.height, equals(64));
    });

    test('should default url to empty string', () {
      final json = {
        'dimensions': {'width': 64, 'height': 64},
      };

      final logoSize = LogoSize.fromJson(json);

      expect(logoSize.url, equals(''));
    });

    test('should serialise to JSON', () {
      final logoSize = LogoSize(
        url: 'https://example.com/logo.png',
        dimensions: Dimensions(width: 128, height: 128),
      );

      final json = logoSize.toJson();

      expect(json['url'], equals('https://example.com/logo.png'));
      expect(json['dimensions']['width'], equals(128));
    });
  });

  group('Logo', () {
    test('should parse from JSON with sizes', () {
      final json = {
        'sizes': [
          {
            'url': 'https://example.com/small.png',
            'dimensions': {'width': 32, 'height': 32},
          },
          {
            'url': 'https://example.com/large.png',
            'dimensions': {'width': 256, 'height': 256},
          },
        ],
      };

      final logo = Logo.fromJson(json);

      expect(logo.sizes.length, equals(2));
      expect(logo.sizes[0].dimensions.width, equals(32));
      expect(logo.sizes[1].dimensions.width, equals(256));
    });

    test('should handle empty sizes list', () {
      final json = {'sizes': <Map<String, dynamic>>[]};

      final logo = Logo.fromJson(json);

      expect(logo.sizes, isEmpty);
    });

    test('should handle missing sizes', () {
      final json = <String, dynamic>{};

      final logo = Logo.fromJson(json);

      expect(logo.sizes, isEmpty);
    });

    test('should serialise to JSON', () {
      final logo = Logo(
        sizes: [
          LogoSize(
            url: 'https://example.com/logo.png',
            dimensions: Dimensions(width: 64, height: 64),
          ),
        ],
      );

      final json = logo.toJson();

      expect((json['sizes'] as List).length, equals(1));
    });
  });

  group('SearchMeta', () {
    test('should parse from JSON', () {
      final json = {'page': 1, 'totalPages': 5, 'totalRecords': 50};

      final meta = SearchMeta.fromJson(json);

      expect(meta.page, equals(1));
      expect(meta.totalPages, equals(5));
      expect(meta.totalRecords, equals(50));
    });

    test('should default to 0 for missing values', () {
      final json = <String, dynamic>{};

      final meta = SearchMeta.fromJson(json);

      expect(meta.page, equals(0));
      expect(meta.totalPages, equals(0));
      expect(meta.totalRecords, equals(0));
    });
  });

  group('Tenant', () {
    /// helper to create a tenant with specified logo sizes
    Tenant createTenantWithLogos(List<Map<String, int>> sizes) {
      return Tenant(
        id: 'tenant-1',
        name: 'AFL Victoria',
        slug: 'afl-vic',
        logo: Logo(
          sizes:
              sizes
                  .map(
                    (s) => LogoSize(
                      url:
                          'https://example.com/${s['width']}x${s['height']}.png',
                      dimensions: Dimensions(
                        width: s['width']!,
                        height: s['height']!,
                      ),
                    ),
                  )
                  .toList(),
        ),
      );
    }

    group('logo selection', () {
      test('should return null when no logo', () {
        final tenant = Tenant(
          id: 'tenant-1',
          name: 'AFL Victoria',
          slug: 'afl-vic',
        );

        expect(tenant.logoUrl32, isNull);
        expect(tenant.logoUrl48, isNull);
        expect(tenant.logoUrl128, isNull);
        expect(tenant.logoUrl256, isNull);
        expect(tenant.logoUrlLarge, isNull);
      });

      test('should return null when logo has empty sizes', () {
        final tenant = Tenant(
          id: 'tenant-1',
          name: 'AFL Victoria',
          slug: 'afl-vic',
          logo: Logo(sizes: []),
        );

        expect(tenant.logoUrl32, isNull);
        expect(tenant.logoUrl48, isNull);
      });

      test('logoUrl32 should return smallest logo >= 32x32', () {
        final tenant = createTenantWithLogos([
          {'width': 16, 'height': 16},
          {'width': 32, 'height': 32},
          {'width': 64, 'height': 64},
        ]);

        expect(tenant.logoUrl32, contains('32x32'));
      });

      test('logoUrl48 should return smallest logo >= 48x48', () {
        final tenant = createTenantWithLogos([
          {'width': 32, 'height': 32},
          {'width': 48, 'height': 48},
          {'width': 64, 'height': 64},
        ]);

        expect(tenant.logoUrl48, contains('48x48'));
      });

      test('logoUrl128 should return smallest logo >= 128x128', () {
        final tenant = createTenantWithLogos([
          {'width': 64, 'height': 64},
          {'width': 128, 'height': 128},
          {'width': 256, 'height': 256},
        ]);

        expect(tenant.logoUrl128, contains('128x128'));
      });

      test('logoUrl256 should return smallest logo >= 256x256', () {
        final tenant = createTenantWithLogos([
          {'width': 128, 'height': 128},
          {'width': 256, 'height': 256},
          {'width': 512, 'height': 512},
        ]);

        expect(tenant.logoUrl256, contains('256x256'));
      });

      test('should return largest when none meet minimum size', () {
        final tenant = createTenantWithLogos([
          {'width': 16, 'height': 16},
          {'width': 24, 'height': 24},
        ]);

        // When requesting 32, should return largest available (24x24)
        expect(tenant.logoUrl32, contains('24x24'));
      });

      test('logoUrlLarge should return largest available', () {
        final tenant = createTenantWithLogos([
          {'width': 32, 'height': 32},
          {'width': 128, 'height': 128},
          {'width': 256, 'height': 256},
        ]);

        expect(tenant.logoUrlLarge, contains('256x256'));
      });
    });
  });

  group('Organisation', () {
    /// helper to create logo sizes
    Logo createLogo(List<Map<String, int>> sizes) {
      return Logo(
        sizes:
            sizes
                .map(
                  (s) => LogoSize(
                    url:
                        'https://example.com/org/${s['width']}x${s['height']}.png',
                    dimensions: Dimensions(
                      width: s['width']!,
                      height: s['height']!,
                    ),
                  ),
                )
                .toList(),
      );
    }

    Logo createTenantLogo(List<Map<String, int>> sizes) {
      return Logo(
        sizes:
            sizes
                .map(
                  (s) => LogoSize(
                    url:
                        'https://example.com/tenant/${s['width']}x${s['height']}.png',
                    dimensions: Dimensions(
                      width: s['width']!,
                      height: s['height']!,
                    ),
                  ),
                )
                .toList(),
      );
    }

    group('fromJson', () {
      test('should parse complete JSON', () {
        final json = {
          'id': 'org-123',
          'routingCode': 'VIC-001',
          'name': 'Richmond FC',
          'type': 'Club',
          'logo': {
            'sizes': [
              {
                'url': 'https://example.com/logo.png',
                'dimensions': {'width': 64, 'height': 64},
              },
            ],
          },
          'address': {
            'id': 'addr-1',
            'line1': '123 Punt Road',
            'suburb': 'Richmond',
            'postcode': '3121',
            'state': 'VIC',
            'country': 'Australia',
          },
        };

        final org = Organisation.fromJson(json);

        expect(org.id, equals('org-123'));
        expect(org.routingCode, equals('VIC-001'));
        expect(org.name, equals('Richmond FC'));
        expect(org.type, equals('Club'));
        expect(org.logo, isNotNull);
        expect(org.address, isNotNull);
        expect(org.address!.line1, equals('123 Punt Road'));
      });

      test('should handle missing optional fields', () {
        final json = {
          'id': 'org-123',
          'routingCode': 'VIC-001',
          'name': 'Richmond FC',
          'type': 'Club',
        };

        final org = Organisation.fromJson(json);

        expect(org.logo, isNull);
        expect(org.tenant, isNull);
        expect(org.address, isNull);
      });

      test('should default to empty strings for missing required fields', () {
        final json = <String, dynamic>{};

        final org = Organisation.fromJson(json);

        expect(org.id, equals(''));
        expect(org.routingCode, equals(''));
        expect(org.name, equals(''));
        expect(org.type, equals(''));
      });
    });

    group('logo selection', () {
      test('should use organisation logo when available', () {
        final org = Organisation(
          id: 'org-1',
          routingCode: 'VIC-001',
          name: 'Richmond FC',
          type: 'Club',
          logo: createLogo([
            {'width': 48, 'height': 48},
          ]),
          tenant: Tenant(
            id: 'tenant-1',
            name: 'AFL Victoria',
            slug: 'afl-vic',
            logo: createTenantLogo([
              {'width': 256, 'height': 256},
            ]),
          ),
        );

        expect(org.logoUrl48, contains('/org/'));
      });

      test('should fall back to tenant logo when org logo is null', () {
        final org = Organisation(
          id: 'org-1',
          routingCode: 'VIC-001',
          name: 'Richmond FC',
          type: 'Club',
          tenant: Tenant(
            id: 'tenant-1',
            name: 'AFL Victoria',
            slug: 'afl-vic',
            logo: createTenantLogo([
              {'width': 48, 'height': 48},
            ]),
          ),
        );

        expect(org.logoUrl48, contains('/tenant/'));
      });

      test('should fall back to tenant logo when org logo sizes is empty', () {
        final org = Organisation(
          id: 'org-1',
          routingCode: 'VIC-001',
          name: 'Richmond FC',
          type: 'Club',
          logo: Logo(sizes: []),
          tenant: Tenant(
            id: 'tenant-1',
            name: 'AFL Victoria',
            slug: 'afl-vic',
            logo: createTenantLogo([
              {'width': 48, 'height': 48},
            ]),
          ),
        );

        expect(org.logoUrl48, contains('/tenant/'));
      });

      test('logoUrl32 should select correct size', () {
        final org = Organisation(
          id: 'org-1',
          routingCode: 'VIC-001',
          name: 'Richmond FC',
          type: 'Club',
          logo: createLogo([
            {'width': 16, 'height': 16},
            {'width': 32, 'height': 32},
            {'width': 64, 'height': 64},
          ]),
        );

        expect(org.logoUrl32, contains('32x32'));
      });

      test('logoUrl48 should select correct size', () {
        final org = Organisation(
          id: 'org-1',
          routingCode: 'VIC-001',
          name: 'Richmond FC',
          type: 'Club',
          logo: createLogo([
            {'width': 32, 'height': 32},
            {'width': 48, 'height': 48},
            {'width': 128, 'height': 128},
          ]),
        );

        expect(org.logoUrl48, contains('48x48'));
      });

      test('logoUrl128 should select correct size', () {
        final org = Organisation(
          id: 'org-1',
          routingCode: 'VIC-001',
          name: 'Richmond FC',
          type: 'Club',
          logo: createLogo([
            {'width': 64, 'height': 64},
            {'width': 128, 'height': 128},
            {'width': 256, 'height': 256},
          ]),
        );

        expect(org.logoUrl128, contains('128x128'));
      });

      test('logoUrl256 should select correct size', () {
        final org = Organisation(
          id: 'org-1',
          routingCode: 'VIC-001',
          name: 'Richmond FC',
          type: 'Club',
          logo: createLogo([
            {'width': 128, 'height': 128},
            {'width': 256, 'height': 256},
            {'width': 512, 'height': 512},
          ]),
        );

        expect(org.logoUrl256, contains('256x256'));
      });

      test('logoUrlLarge should cascade through sizes', () {
        final org = Organisation(
          id: 'org-1',
          routingCode: 'VIC-001',
          name: 'Richmond FC',
          type: 'Club',
          logo: createLogo([
            {'width': 48, 'height': 48},
          ]),
        );

        // Should return the 48x48 as it's the largest available
        expect(org.logoUrlLarge, contains('48x48'));
      });
    });
  });

  group('OrganisationDetails', () {
    group('fromJson', () {
      test('should parse complete JSON', () {
        final json = {
          'id': 'org-details-123',
          'type': 'Club',
          'name': 'Richmond FC',
          'email': 'contact@richmond.com.au',
          'contactNumber': '03 9123 4567',
          'websiteUrl': 'https://richmond.com.au',
          'shopVisible': true,
          'address': {
            'id': 'addr-1',
            'line1': '123 Punt Road',
            'suburb': 'Richmond',
            'postcode': '3121',
            'state': 'VIC',
            'country': 'Australia',
          },
          'logo': {
            'sizes': [
              {
                'url': 'https://example.com/logo.png',
                'dimensions': {'width': 128, 'height': 128},
              },
            ],
          },
        };

        final details = OrganisationDetails.fromJson(json);

        expect(details.id, equals('org-details-123'));
        expect(details.type, equals('Club'));
        expect(details.name, equals('Richmond FC'));
        expect(details.email, equals('contact@richmond.com.au'));
        expect(details.contactNumber, equals('03 9123 4567'));
        expect(details.websiteUrl, equals('https://richmond.com.au'));
        expect(details.shopVisible, isTrue);
        expect(details.address, isNotNull);
        expect(details.logo, isNotNull);
      });

      test('should default shopVisible to false', () {
        final json = {
          'id': 'org-123',
          'type': 'Club',
          'name': 'Richmond FC',
          'email': '',
          'contactNumber': '',
          'websiteUrl': '',
        };

        final details = OrganisationDetails.fromJson(json);

        expect(details.shopVisible, isFalse);
      });
    });

    group('toJson', () {
      test('should serialise to JSON correctly', () {
        final details = OrganisationDetails(
          id: 'org-123',
          type: 'Club',
          name: 'Carlton FC',
          email: 'contact@carlton.com.au',
          contactNumber: '03 9876 5432',
          websiteUrl: 'https://carlton.com.au',
          shopVisible: true,
          address: Address(
            id: 'addr-1',
            line1: '123 Princes Park',
            suburb: 'Carlton',
            postcode: '3053',
            state: 'VIC',
            country: 'Australia',
          ),
        );

        final json = details.toJson();

        expect(json['id'], equals('org-123'));
        expect(json['name'], equals('Carlton FC'));
        expect(json['shopVisible'], isTrue);
        expect(json['address'], isNotNull);
      });
    });

    group('logo selection', () {
      test('logoUrl48 should select correct size', () {
        final details = OrganisationDetails(
          id: 'org-123',
          type: 'Club',
          name: 'Richmond FC',
          email: '',
          contactNumber: '',
          websiteUrl: '',
          shopVisible: false,
          logo: Logo(
            sizes: [
              LogoSize(
                url: 'https://example.com/32.png',
                dimensions: Dimensions(width: 32, height: 32),
              ),
              LogoSize(
                url: 'https://example.com/64.png',
                dimensions: Dimensions(width: 64, height: 64),
              ),
            ],
          ),
        );

        expect(details.logoUrl48, contains('64.png'));
      });

      test('logoUrlLarge should return largest available', () {
        final details = OrganisationDetails(
          id: 'org-123',
          type: 'Club',
          name: 'Richmond FC',
          email: '',
          contactNumber: '',
          websiteUrl: '',
          shopVisible: false,
          logo: Logo(
            sizes: [
              LogoSize(
                url: 'https://example.com/32.png',
                dimensions: Dimensions(width: 32, height: 32),
              ),
              LogoSize(
                url: 'https://example.com/256.png',
                dimensions: Dimensions(width: 256, height: 256),
              ),
              LogoSize(
                url: 'https://example.com/64.png',
                dimensions: Dimensions(width: 64, height: 64),
              ),
            ],
          ),
        );

        expect(details.logoUrlLarge, contains('256.png'));
      });

      test('should return null when no logo', () {
        final details = OrganisationDetails(
          id: 'org-123',
          type: 'Club',
          name: 'Richmond FC',
          email: '',
          contactNumber: '',
          websiteUrl: '',
          shopVisible: false,
        );

        expect(details.logoUrl48, isNull);
        expect(details.logoUrlLarge, isNull);
      });
    });
  });

  group('PlayHQSearchResponse', () {
    test('should parse complete search response', () {
      final json = {
        'data': {
          'search': {
            'meta': {'page': 1, 'totalPages': 3, 'totalRecords': 25},
            'results': [
              {
                'id': 'org-1',
                'routingCode': 'VIC-001',
                'name': 'Richmond FC',
                'type': 'Club',
              },
              {
                'id': 'org-2',
                'routingCode': 'VIC-002',
                'name': 'Carlton FC',
                'type': 'Club',
              },
            ],
          },
        },
      };

      final response = PlayHQSearchResponse.fromJson(json);

      expect(response.meta.page, equals(1));
      expect(response.meta.totalPages, equals(3));
      expect(response.meta.totalRecords, equals(25));
      expect(response.results.length, equals(2));
      expect(response.results[0].name, equals('Richmond FC'));
      expect(response.results[1].name, equals('Carlton FC'));
    });

    test('should handle empty results', () {
      final json = {
        'data': {
          'search': {
            'meta': {'page': 1, 'totalPages': 0, 'totalRecords': 0},
            'results': <Map<String, dynamic>>[],
          },
        },
      };

      final response = PlayHQSearchResponse.fromJson(json);

      expect(response.results, isEmpty);
      expect(response.meta.totalRecords, equals(0));
    });

    test('should handle empty search results', () {
      final json = {
        'data': {
          'search': {
            'meta': {'page': 0, 'totalPages': 0, 'totalRecords': 0},
            'results': <Map<String, dynamic>>[],
          },
        },
      };

      final response = PlayHQSearchResponse.fromJson(json);

      expect(response.results, isEmpty);
      expect(response.meta.page, equals(0));
    });
  });

  group('OrganisationDetailsResponse', () {
    test('should parse organisation details response', () {
      final json = {
        'data': {
          'discoverOrganisation': {
            'id': 'org-123',
            'type': 'Club',
            'name': 'Richmond FC',
            'email': 'contact@richmond.com.au',
            'contactNumber': '03 9123 4567',
            'websiteUrl': 'https://richmond.com.au',
            'shopVisible': true,
          },
        },
      };

      final response = OrganisationDetailsResponse.fromJson(json);

      expect(response.organisation, isNotNull);
      expect(response.organisation!.name, equals('Richmond FC'));
    });

    test('should handle null organisation', () {
      final json = {
        'data': {'discoverOrganisation': null},
      };

      final response = OrganisationDetailsResponse.fromJson(json);

      expect(response.organisation, isNull);
    });

    test('should handle missing data', () {
      final json = <String, dynamic>{};

      final response = OrganisationDetailsResponse.fromJson(json);

      expect(response.organisation, isNull);
    });
  });
}
