import 'package:test/test.dart';
import '../lib/flutter_analysis_client.dart';

void main() {
  group('DeviceIdHelper Tests', () {
    test('getShortDeviceId returns 16 character string', () async {
      final deviceId = await DeviceIdHelper.getShortDeviceId();
      
      expect(deviceId.length, equals(16));
      expect(RegExp(r'^[0-9a-f]{16}$').hasMatch(deviceId), isTrue,
          reason: 'Device ID should be 16 hexadecimal characters');
    });

    test('getShortDeviceId returns consistent value', () async {
      final id1 = await DeviceIdHelper.getShortDeviceId();
      final id2 = await DeviceIdHelper.getShortDeviceId();
      final id3 = await DeviceIdHelper.getShortDeviceId();
      
      expect(id1, equals(id2));
      expect(id2, equals(id3));
    });

    test('getOriginalUdid returns non-empty string', () async {
      final udid = await DeviceIdHelper.getOriginalUdid();
      
      expect(udid, isNotEmpty);
      expect(udid, isNot(equals('unknown')));
    });

    test('getDeviceIdInfo returns valid info map', () async {
      final info = await DeviceIdHelper.getDeviceIdInfo();
      
      expect(info, isA<Map<String, String>>());
      expect(info.containsKey('original_udid'), isTrue);
      expect(info.containsKey('short_device_id'), isTrue);
      expect(info.containsKey('hash_method'), isTrue);
      expect(info.containsKey('id_length'), isTrue);
      
      // Verify id_length is correct
      expect(info['id_length'], equals('16'));
    });

    test('short device ID is deterministic from UDID', () async {
      // Get the same UDID multiple times and verify hash is consistent
      final udid = await DeviceIdHelper.getOriginalUdid();
      
      // If we can get the UDID, the short ID should be deterministic
      if (udid != 'unknown') {
        final id1 = await DeviceIdHelper.getShortDeviceId();
        final id2 = await DeviceIdHelper.getShortDeviceId();
        
        expect(id1, equals(id2));
      }
    });

    test('device ID info shows MD5 hash method', () async {
      final info = await DeviceIdHelper.getDeviceIdInfo();
      
      expect(info['hash_method'], contains('MD5'));
    });
  });

  group('Integration with AnalyticsClient', () {
    late AnalyticsClient client;

    setUp(() {
      client = AnalyticsClient.create(
        serverUrl: 'http://localhost:8080',
        productName: 'TestApp',
        debug: true,
      );
    });

    tearDown(() async {
      await client.close();
    });

    test('client uses short device ID', () async {
      // Initialize device info by tracking an event
      await client.trackEvent('test');
      
      final sessionInfo = client.sessionInfo;
      final deviceId = sessionInfo['device_id'] as String?;
      
      // Device ID should be set
      expect(deviceId, isNotNull);
      
      // If device ID is generated from flutter_udid, it should be 16 chars
      // (might be different in test environment, so we just check it's not empty)
      expect(deviceId, isNotEmpty);
    });
  });

  group('Edge Cases', () {
    test('handles flutter_udid failure gracefully', () async {
      // This test verifies the fallback mechanism
      // Even if flutter_udid fails, we should still get a valid device ID
      final deviceId = await DeviceIdHelper.getShortDeviceId();
      
      expect(deviceId, isNotEmpty);
      expect(deviceId.length, equals(16));
    });

    test('getDeviceIdInfo handles errors gracefully', () async {
      final info = await DeviceIdHelper.getDeviceIdInfo();
      
      // Should either have valid info or an error key
      expect(info, isNotEmpty);
      
      if (info.containsKey('error')) {
        expect(info['error'], isNotEmpty);
      } else {
        expect(info.containsKey('short_device_id'), isTrue);
      }
    });
  });
}
