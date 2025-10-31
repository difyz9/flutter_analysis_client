import 'package:test/test.dart';
import '../lib/src/models.dart';

void main() {
  group('AnalyticsEvent', () {
    test('should create event with current timestamp', () {
      final event = AnalyticsEvent.now(
        name: 'test_event',
        properties: {'key': 'value'},
      );
      
      expect(event.name, equals('test_event'));
      expect(event.properties, equals({'key': 'value'}));
      expect(event.timestamp, isA<int>());
      expect(event.timestamp, greaterThan(0));
    });

    test('should serialize to JSON correctly', () {
      final event = AnalyticsEvent(
        name: 'test_event',
        timestamp: 1234567890,
        properties: {'key': 'value'},
        category: 'test',
        action: 'click',
        label: 'button',
        value: 1.0,
      );

      final json = event.toJson();
      
      expect(json['name'], equals('test_event'));
      expect(json['timestamp'], equals(1234567890));
      expect(json['properties'], equals({'key': 'value'}));
      expect(json['category'], equals('test'));
      expect(json['action'], equals('click'));
      expect(json['label'], equals('button'));
      expect(json['value'], equals(1.0));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'name': 'test_event',
        'timestamp': 1234567890,
        'properties': {'key': 'value'},
        'category': 'test',
        'action': 'click',
        'label': 'button',
        'value': 1.0,
      };

      final event = AnalyticsEvent.fromJson(json);
      
      expect(event.name, equals('test_event'));
      expect(event.timestamp, equals(1234567890));
      expect(event.properties, equals({'key': 'value'}));
      expect(event.category, equals('test'));
      expect(event.action, equals('click'));
      expect(event.label, equals('button'));
      expect(event.value, equals(1.0));
    });

    test('should handle optional fields correctly', () {
      final event = AnalyticsEvent(
        name: 'simple_event',
        timestamp: 1234567890,
      );

      final json = event.toJson();
      
      expect(json['name'], equals('simple_event'));
      expect(json['timestamp'], equals(1234567890));
      expect(json.containsKey('properties'), isFalse);
      expect(json.containsKey('category'), isFalse);
      expect(json.containsKey('action'), isFalse);
      expect(json.containsKey('label'), isFalse);
      expect(json.containsKey('value'), isFalse);
    });
  });

  group('DeviceInfo', () {
    test('should create device info correctly', () {
      final deviceInfo = DeviceInfo(
        deviceId: 'device-123',
        platform: 'Android',
        osVersion: '12',
        deviceModel: 'Pixel 6',
      );

      expect(deviceInfo.deviceId, equals('device-123'));
      expect(deviceInfo.platform, equals('Android'));
      expect(deviceInfo.osVersion, equals('12'));
      expect(deviceInfo.deviceModel, equals('Pixel 6'));
    });

    test('should serialize to JSON correctly', () {
      final deviceInfo = DeviceInfo(
        deviceId: 'device-123',
        platform: 'iOS',
        osVersion: '15.0',
        deviceModel: 'iPhone 13',
        appVersion: '1.0.0',
        buildNumber: '1',
        language: 'en',
        timezone: 'UTC',
      );

      final json = deviceInfo.toJson();
      
      expect(json['device_id'], equals('device-123'));
      expect(json['platform'], equals('iOS'));
      expect(json['os_version'], equals('15.0'));
      expect(json['device_model'], equals('iPhone 13'));
      expect(json['app_version'], equals('1.0.0'));
      expect(json['build_number'], equals('1'));
      expect(json['language'], equals('en'));
      expect(json['timezone'], equals('UTC'));
    });
  });

  group('AnalyticsConfig', () {
    test('should create config with default values', () {
      final config = AnalyticsConfig(
        serverUrl: 'http://localhost:8080',
        productName: 'TestApp',
      );

      expect(config.serverUrl, equals('http://localhost:8080'));
      expect(config.productName, equals('TestApp'));
      expect(config.timeout, equals(Duration(seconds: 10)));
      expect(config.batchSize, equals(20));
      expect(config.flushInterval, equals(Duration(seconds: 5)));
      expect(config.bufferSize, equals(1000));
      expect(config.debug, isFalse);
      expect(config.encryption.enabled, isFalse);
    });

    test('should copy with updated values', () {
      final config = AnalyticsConfig(
        serverUrl: 'http://localhost:8080',
        productName: 'TestApp',
      );

      final updatedConfig = config.copyWith(
        debug: true,
        batchSize: 50,
      );

      expect(updatedConfig.serverUrl, equals('http://localhost:8080'));
      expect(updatedConfig.productName, equals('TestApp'));
      expect(updatedConfig.debug, isTrue);
      expect(updatedConfig.batchSize, equals(50));
      expect(updatedConfig.flushInterval, equals(Duration(seconds: 5))); // unchanged
    });
  });

  group('EncryptionConfig', () {
    test('should create disabled config', () {
      final config = EncryptionConfig.disabled();
      
      expect(config.enabled, isFalse);
      expect(config.secretKey, isEmpty);
    });

    test('should create enabled config', () {
      final config = EncryptionConfig.enabled('secret-key');
      
      expect(config.enabled, isTrue);
      expect(config.secretKey, equals('secret-key'));
    });
  });
}