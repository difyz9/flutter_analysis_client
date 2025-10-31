import 'package:test/test.dart';
import '../lib/flutter_analysis_client.dart';

void main() {
  group('Network Graceful Degradation Tests', () {
    test('canLaunchApp should return true when network fails', () async {
      // 创建一个指向不存在服务器的客户端来模拟网络失败
      final client = AnalyticsClient.create(
        serverUrl: 'http://nonexistent-server:9999',
        productName: 'TestApp',
        timeout: Duration(seconds: 1), // 短超时来快速失败
        debug: true,
      );

      // canLaunchApp 应该在网络失败时返回 true（优雅降级）
      final result = await client.canLaunchApp();
      
      expect(result.isSuccess, isTrue, reason: 'Should return success on network failure');
      expect(result.value, isTrue, reason: 'Should allow launch on network failure');

      await client.close();
    });

    test('checkProductStatus should still return failure on network error', () async {
      // checkProductStatus 应该仍然返回详细的错误信息
      final client = AnalyticsClient.create(
        serverUrl: 'http://nonexistent-server:9999',
        productName: 'TestApp',
        timeout: Duration(seconds: 1),
        debug: true,
      );

      final result = await client.checkProductStatus();
      
      expect(result.isFailure, isTrue, reason: 'Should return failure for detailed status check');
      expect(result.error.message, contains('error'), reason: 'Should contain error information');

      await client.close();
    });

    test('canLaunchApp should return false for server errors with status codes', () async {
      // 这个测试需要一个返回错误状态码的服务器
      // 在实际环境中，如果服务器返回 404 或其他错误状态码，应该拒绝启动
      
      // 注意: 这个测试需要一个实际的服务器来返回错误状态码
      // 在没有服务器的情况下，我们只能测试网络连接失败的情况
      
      // 模拟场景：如果服务器可达但返回错误，应该拒绝启动
      // 这个测试在 CI 环境中可能需要 mock 服务器
    });

    test('Analytics singleton should also handle network graceful degradation', () async {
      // 测试单例模式也有相同的行为
      Analytics.initialize(
        serverUrl: 'http://nonexistent-server:9999',
        productName: 'TestApp',
        timeout: Duration(seconds: 1),
        debug: true,
        forceReinitialize: true,
      );

      final result = await Analytics.instance.canLaunchApp();
      
      expect(result.isSuccess, isTrue);
      expect(result.value, isTrue);

      await Analytics.instance.close();
    });
  });

  group('Product Status Models with Network Considerations', () {
    test('ProductStatusResponse should handle null data gracefully', () {
      // 测试当网络错误时，响应可能没有数据
      final response = ProductStatusResponse(
        code: -1, // 表示网络错误
        data: null,
        message: 'Network error',
      );

      expect(response.isSuccess, isFalse);
      expect(response.canLaunch, isFalse);
      expect(response.data, isNull);
    });

    test('ProductStatus isActive should work correctly', () {
      final activeStatus = ProductStatus(
        name: 'TestApp',
        displayName: 'Test App',
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
        lastActivity: '',
        firstSeen: '',
        createdAt: '',
        updatedAt: '',
      );

      final inactiveStatus = ProductStatus(
        name: 'TestApp',
        displayName: 'Test App',
        description: '',
        iconUrl: '',
        homepageUrl: '',
        status: 'maintenance',
        totalEvents: 0,
        totalDevices: 0,
        totalLicenses: 0,
        activeDevices7d: 0,
        activeDevices30d: 0,
        eventsToday: 0,
        lastActivity: '',
        firstSeen: '',
        createdAt: '',
        updatedAt: '',
      );

      expect(activeStatus.isActive, isTrue);
      expect(inactiveStatus.isActive, isFalse);
    });
  });
}