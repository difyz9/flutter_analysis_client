import 'package:test/test.dart';
import '../lib/flutter_analysis_client.dart';

void main() {
  group('Product Status Tests', () {
    late AnalyticsClient client;

    setUp(() {
      client = AnalyticsClient.create(
        serverUrl: 'http://localhost:8080',
        productName: 'HelloWorldApp',
        debug: true,
      );
    });

    tearDown(() async {
      await client.close();
    });

    test('ProductStatus model creation', () {
      final status = ProductStatus(
        name: 'HelloWorldApp',
        displayName: 'HelloWorldApp',
        description: '',
        iconUrl: '',
        homepageUrl: '',
        status: 'active',
        totalEvents: 0,
        totalDevices: 0,
        totalLicenses: 0,
        activeDevices7d: 0,
        activeDevices30d: 0,
        eventsToday: 0,
        lastActivity: '0001-01-01 00:00:00',
        firstSeen: '0001-01-01 00:00:00',
        createdAt: '0001-01-01 00:00:00',
        updatedAt: '0001-01-01 00:00:00',
      );

      expect(status.name, equals('HelloWorldApp'));
      expect(status.status, equals('active'));
      expect(status.isActive, isTrue);
    });

    test('ProductStatus from JSON', () {
      final json = {
        'name': 'HelloWorldApp',
        'display_name': 'HelloWorldApp',
        'description': '',
        'icon_url': '',
        'homepage_url': '',
        'status': 'active',
        'total_events': 0,
        'total_devices': 0,
        'total_licenses': 0,
        'active_devices_7d': 0,
        'active_devices_30d': 0,
        'events_today': 0,
        'last_activity': '0001-01-01 00:00:00',
        'first_seen': '0001-01-01 00:00:00',
        'created_at': '0001-01-01 00:00:00',
        'updated_at': '0001-01-01 00:00:00',
      };

      final status = ProductStatus.fromJson(json);
      expect(status.name, equals('HelloWorldApp'));
      expect(status.isActive, isTrue);
    });

    test('ProductStatusResponse model', () {
      final json = {
        'code': 0,
        'data': {
          'name': 'HelloWorldApp',
          'display_name': 'HelloWorldApp',
          'description': '',
          'icon_url': '',
          'homepage_url': '',
          'status': 'active',
          'total_events': 0,
          'total_devices': 0,
          'total_licenses': 0,
          'active_devices_7d': 0,
          'active_devices_30d': 0,
          'events_today': 0,
          'last_activity': '0001-01-01 00:00:00',
          'first_seen': '0001-01-01 00:00:00',
          'created_at': '0001-01-01 00:00:00',
          'updated_at': '0001-01-01 00:00:00',
        },
        'message': 'success',
      };

      final response = ProductStatusResponse.fromJson(json);
      expect(response.code, equals(0));
      expect(response.message, equals('success'));
      expect(response.isSuccess, isTrue);
      expect(response.canLaunch, isTrue);
      expect(response.data?.name, equals('HelloWorldApp'));
    });

    test('ProductStatusResponse with inactive status', () {
      final json = {
        'code': 0,
        'data': {
          'name': 'HelloWorldApp',
          'display_name': 'HelloWorldApp',
          'description': '',
          'icon_url': '',
          'homepage_url': '',
          'status': 'inactive',
          'total_events': 0,
          'total_devices': 0,
          'total_licenses': 0,
          'active_devices_7d': 0,
          'active_devices_30d': 0,
          'events_today': 0,
          'last_activity': '0001-01-01 00:00:00',
          'first_seen': '0001-01-01 00:00:00',
          'created_at': '0001-01-01 00:00:00',
          'updated_at': '0001-01-01 00:00:00',
        },
        'message': 'success',
      };

      final response = ProductStatusResponse.fromJson(json);
      expect(response.isSuccess, isTrue);
      expect(response.canLaunch, isFalse);
      expect(response.data?.isActive, isFalse);
    });

    test('ProductStatusResponse with error code', () {
      final json = {
        'code': 404,
        'data': null,
        'message': 'Product not found',
      };

      final response = ProductStatusResponse.fromJson(json);
      expect(response.isSuccess, isFalse);
      expect(response.canLaunch, isFalse);
      expect(response.data, isNull);
    });

    // Note: The following tests require a running server
    // They are commented out to avoid test failures in CI/offline environments
    
    /*
    test('checkProductStatus method exists', () {
      // This test just verifies the method exists and can be called
      expect(() => client.checkProductStatus(), returnsNormally);
    });

    test('canLaunchApp method exists', () {
      // This test just verifies the method exists and can be called
      expect(() => client.canLaunchApp(), returnsNormally);
    });
    */
  });
}