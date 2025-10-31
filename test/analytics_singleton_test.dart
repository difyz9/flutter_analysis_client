import 'package:flutter_analysis_client/flutter_analysis_client.dart';
import 'package:test/test.dart';

void main() {
  group('Analytics Singleton', () {
    setUp(() async {
      // Reset singleton between tests
      if (Analytics.isInitialized) {
        await Analytics.instance.close();
      }
    });

    tearDown(() async {
      // Clean up after each test
      if (Analytics.isInitialized) {
        await Analytics.instance.close();
      }
    });

    test('should not be initialized before calling initialize()', () {
      expect(Analytics.isInitialized, isFalse);
      expect(() => Analytics.instance, throwsStateError);
    });

    test('should initialize successfully', () {
      Analytics.initialize(
        serverUrl: 'http://localhost:8080',
        productName: 'test_app',
      );

      expect(Analytics.isInitialized, isTrue);
      expect(Analytics.instance, isNotNull);
    });

    test('should throw error when initializing twice without forceReinitialize', () {
      Analytics.initialize(
        serverUrl: 'http://localhost:8080',
        productName: 'test_app',
      );

      expect(
        () => Analytics.initialize(
          serverUrl: 'http://localhost:8080',
          productName: 'test_app',
        ),
        throwsStateError,
      );
    });

    test('should allow reinitialization with forceReinitialize flag', () async {
      Analytics.initialize(
        serverUrl: 'http://localhost:8080',
        productName: 'test_app',
      );

      // ignore: unused_local_variable
      final firstInstance = Analytics.instance;

      // Give some time for initialization
      await Future.delayed(Duration(milliseconds: 100));

      Analytics.initialize(
        serverUrl: 'http://localhost:8081',
        productName: 'test_app_2',
        forceReinitialize: true,
      );

      final secondInstance = Analytics.instance;

      expect(secondInstance, isNotNull);
      // Note: Instances will be different objects
    });

    test('should access client methods through instance', () {
      Analytics.initialize(
        serverUrl: 'http://localhost:8080',
        productName: 'test_app',
      );

      expect(Analytics.instance.sessionInfo, isNotNull);
      expect(Analytics.instance.bufferSize, equals(0));
      expect(Analytics.instance.isClosed, isFalse);
    });

    test('should track events through instance', () async {
      Analytics.initialize(
        serverUrl: 'http://localhost:8080',
        productName: 'test_app',
      );

      final result = await Analytics.instance.track(
        name: 'test_event',
        properties: {'key': 'value'},
      );

      expect(result.isSuccess, isTrue);
      expect(Analytics.instance.bufferSize, equals(1));
    });

    test('should track events through static methods', () async {
      Analytics.initialize(
        serverUrl: 'http://localhost:8080',
        productName: 'test_app',
      );

      final result = await Analytics.trackStatic(
        'test_event',
        properties: {'key': 'value'},
      );

      expect(result.isSuccess, isTrue);
      expect(Analytics.instance.bufferSize, equals(1));
    });

    test('should set user ID through instance', () {
      Analytics.initialize(
        serverUrl: 'http://localhost:8080',
        productName: 'test_app',
      );

      Analytics.instance.setUserId('user_123');
      
      // Event should be tracked for user identification
      expect(Analytics.instance.bufferSize, greaterThan(0));
    });

    test('should set user ID through static method', () {
      Analytics.initialize(
        serverUrl: 'http://localhost:8080',
        productName: 'test_app',
      );

      Analytics.setUserIdStatic('user_456');
      
      // Event should be tracked for user identification
      expect(Analytics.instance.bufferSize, greaterThan(0));
    });

    test('should track actions through instance', () async {
      Analytics.initialize(
        serverUrl: 'http://localhost:8080',
        productName: 'test_app',
      );

      final result = await Analytics.instance.trackAction(
        category: 'user',
        action: 'login',
        label: 'email',
      );

      expect(result.isSuccess, isTrue);
      expect(Analytics.instance.bufferSize, equals(1));
    });

    test('should track actions through static method', () async {
      Analytics.initialize(
        serverUrl: 'http://localhost:8080',
        productName: 'test_app',
      );

      final result = await Analytics.trackActionStatic(
        category: 'user',
        action: 'logout',
      );

      expect(result.isSuccess, isTrue);
      expect(Analytics.instance.bufferSize, equals(1));
    });

    test('should close singleton and reset state', () async {
      Analytics.initialize(
        serverUrl: 'http://localhost:8080',
        productName: 'test_app',
      );

      expect(Analytics.isInitialized, isTrue);

      await Analytics.instance.close();

      expect(Analytics.isInitialized, isFalse);
      expect(() => Analytics.instance, throwsStateError);
    });

    test('should provide access to underlying client', () {
      Analytics.initialize(
        serverUrl: 'http://localhost:8080',
        productName: 'test_app',
      );

      final client = Analytics.instance.client;
      
      expect(client, isNotNull);
      expect(client, isA<AnalyticsClient>());
      expect(client.isClosed, isFalse);
    });

    test('should stream events', () async {
      Analytics.initialize(
        serverUrl: 'http://localhost:8080',
        productName: 'test_app',
      );

      final events = <AnalyticsEvent>[];
      final subscription = Analytics.instance.eventStream.listen((event) {
        events.add(event);
      });

      await Analytics.instance.track(name: 'event1');
      await Analytics.instance.track(name: 'event2');
      
      await Future.delayed(Duration(milliseconds: 100));

      expect(events.length, equals(2));
      expect(events[0].name, equals('event1'));
      expect(events[1].name, equals('event2'));

      await subscription.cancel();
    });
  });
}
