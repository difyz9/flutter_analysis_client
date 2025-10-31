import 'dart:async';

import '../lib/src/dart_client.dart';

void main() async {
  print('Flutter Analytics Client Example (Pure Dart)');
  print('==============================================');
  
  // Create analytics client
  final client = AnalyticsClient.create(
    serverUrl: 'http://localhost:8080',
    productName: 'DartApp',
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