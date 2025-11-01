import 'package:flutter_analysis_client/flutter_analysis_client.dart';

/// Example showing how to use the device ID with flutter_udid
void main() async {
  print('=== 设备 ID 示例 ===\n');

  // 获取设备 ID 信息
  await demonstrateDeviceId();
  
  // 在 Analytics 中使用
  await demonstrateWithAnalytics();
}

/// 演示设备 ID 功能
Future<void> demonstrateDeviceId() async {
  print('📱 获取设备 ID 信息:\n');

  try {
    // 获取设备 ID 详细信息
    final info = await DeviceIdHelper.getDeviceIdInfo();
    
    print('设备 ID 信息:');
    info.forEach((key, value) {
      print('  $key: $value');
    });
    
    print('\n特点:');
    print('  ✓ 基于 flutter_udid.consistentUdid');
    print('  ✓ 每次调用返回相同的值');
    print('  ✓ 使用 MD5 哈希转换为 16 位短 ID');
    print('  ✓ 无需使用 shared_preferences 缓存');
    print('  ✓ 跨应用重装保持一致');
    
    // 验证一致性
    print('\n🔄 验证一致性:');
    final id1 = await DeviceIdHelper.getShortDeviceId();
    final id2 = await DeviceIdHelper.getShortDeviceId();
    final id3 = await DeviceIdHelper.getShortDeviceId();
    
    print('  第1次调用: $id1');
    print('  第2次调用: $id2');
    print('  第3次调用: $id3');
    print('  一致性: ${id1 == id2 && id2 == id3 ? "✅ 通过" : "❌ 失败"}');
    
  } catch (e) {
    print('❌ 获取设备 ID 失败: $e');
  }
}

/// 在 Analytics 中使用设备 ID
Future<void> demonstrateWithAnalytics() async {
  print('\n\n📊 在 Analytics 中使用:\n');

  try {
    // 创建 Analytics 客户端 (会自动使用新的设备 ID)
    final client = AnalyticsClient.create(
      serverUrl: 'http://localhost:8080',
      productName: 'TestApp',
      debug: true,
    );

    // 上报安装事件 (会包含短设备 ID)
    print('📱 上报安装事件...');
    final installResult = await client.reportInstall();
    
    if (installResult.isSuccess) {
      print('✅ 安装事件上报成功');
    } else {
      print('❌ 安装事件上报失败: ${installResult.error}');
    }

    // 追踪事件
    print('\n📈 追踪测试事件...');
    await client.trackEvent('test_event', {
      'test': 'device_id_example',
      'timestamp': DateTime.now().toIso8601String(),
    });

    // 获取会话信息 (包含设备 ID)
    print('\n📋 会话信息:');
    final sessionInfo = client.sessionInfo;
    sessionInfo.forEach((key, value) {
      print('  $key: $value');
    });

    await client.close();
    
  } catch (e) {
    print('❌ Analytics 操作失败: $e');
  }
}

/// 对比示例：原始 UDID vs 短 ID
Future<void> compareUdidVsShortId() async {
  print('\n\n🔍 对比 UDID 和短 ID:\n');

  try {
    final originalUdid = await DeviceIdHelper.getOriginalUdid();
    final shortId = await DeviceIdHelper.getShortDeviceId();
    
    print('原始 UDID:');
    print('  长度: ${originalUdid.length} 字符');
    print('  内容: $originalUdid');
    
    print('\n短设备 ID:');
    print('  长度: ${shortId.length} 字符');
    print('  内容: $shortId');
    
    print('\n优势:');
    print('  ✓ 缩短 ${originalUdid.length - shortId.length} 个字符');
    print('  ✓ 更易于存储和传输');
    print('  ✓ 保持唯一性 (MD5 哈希)');
    print('  ✓ 减少网络传输大小');
    
  } catch (e) {
    print('❌ 对比失败: $e');
  }
}

/// 性能测试
Future<void> performanceTest() async {
  print('\n\n⚡ 性能测试:\n');

  try {
    final iterations = 100;
    final stopwatch = Stopwatch()..start();
    
    for (int i = 0; i < iterations; i++) {
      await DeviceIdHelper.getShortDeviceId();
    }
    
    stopwatch.stop();
    final avgTime = stopwatch.elapsedMicroseconds / iterations;
    
    print('测试次数: $iterations');
    print('总时间: ${stopwatch.elapsedMilliseconds}ms');
    print('平均时间: ${avgTime.toStringAsFixed(2)}μs');
    print('性能: ${avgTime < 1000 ? "✅ 优秀" : "⚠️ 需要优化"}');
    
  } catch (e) {
    print('❌ 性能测试失败: $e');
  }
}
