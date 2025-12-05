import 'dart:async';

import '../lib/src/dart_client.dart';

void main() async {
  print('Flutter Analytics Client Example (Pure Dart)');
  print('==============================================');
  
  // Create analytics client
  final client = AnalyticsClient.create(
    serverUrl: 'http://124.222.202.16:8080',
    productName: 'vid_fetcher',
    debug: true,
    logger: (message) => print('[LOG] $message'),
  );
  
  try {
    print('\n1. Basic Event Tracking');
    print('-----------------------');
    
    // Report app launch
    final launchResult = await client.reportLaunch();
    if (launchResult.isSuccess) {
      print('✓ App launch reported successfully');
    } else {
      print('✗ Failed to report launch: ${launchResult.error}');
    }

  final canLaunch = await client.canLaunchApp();

    print("\n检查应用启动权限:${canLaunch.isSuccess && canLaunch.value}");
      if (canLaunch.isSuccess && canLaunch.value) {
        print('✅ 应用启动权限检查通过');

        // 尝试获取详细状态信息
        final statusResult = await client.checkProductStatus();
        if (statusResult.isSuccess) {
          final status = statusResult.value.data;
          print('📊 产品状态: ${status?.status}');

        } else {
          print('ℹ️  无法获取详细状态（可能是离线模式）');
        }
      }    
    // Track simple events
    await client.trackEvent('button_click', {
      'button_name': 'login',
      'screen': 'home',
    });
    
    await client.trackEvent('page_view', {
      'page': 'dashboard',
      'user_type': 'premium',
    });
    
    // Track user action
    await client.trackAction(
      category: 'user',
      action: 'signup',
      label: 'email',
      value: 1.0,
      properties: {'source': 'organic'},
    );
    
    // Set user ID
    client.setUserId('user123');
    
    // Check session info
    print('Session info: ${client.sessionInfo}');
    print('Buffer size: ${client.bufferSize} events');
    
    // Manually flush events (will fail without real server, but demonstrates API)
    print('\n2. Flushing Events');
    print('------------------');
    final flushResult = await client.flush();
    if (flushResult.isSuccess) {
      print('✓ Events flushed successfully');
    } else {
      print('✗ Failed to flush (expected without server): ${flushResult.error}');
    }
    
    print('\n3. Event Stream Example');
    print('-----------------------');
    
    // Listen to event stream
    var eventCount = 0;
    final subscription = client.eventStream.listen((event) {
      eventCount++;
      print('Event $eventCount: ${event.name} at ${DateTime.fromMillisecondsSinceEpoch(event.timestamp)}');
    });
    
    // Track a few more events
    await client.trackEvent('feature_used', {'feature': 'search'});
    await client.trackEvent('error_occurred', {'error_type': 'network'});
    await client.trackEvent('user_interaction', {'type': 'scroll', 'element': 'main_content'});
    
    // Wait a bit for events to be processed
    await Future.delayed(Duration(milliseconds: 100));
    
    // Clean up
    await subscription.cancel();
    
    print('\n✓ Example completed successfully!');
    print('  Total events tracked: $eventCount');
    print('  Buffer size: ${client.bufferSize} events');
    
  } catch (e) {
    print('✗ Error: $e');
  } finally {
    // Always close the client
    await client.close();
    print('✓ Client closed');
  }
}