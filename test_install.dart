import 'lib/flutter_analysis_client.dart';

/// Test script to test install event reporting
void main() async {
  print('Testing install event reporting...\n');
  
  // Create a test client
  final client = AnalyticsClient.create(
    serverUrl: 'http://localhost:8080',
    productName: 'flutter_test_app',
    debug: true,
    logger: (message) => print('[LOG] $message'),
  );
  
  try {
    print('=== TESTING INSTALL EVENT ===');
    
    // Test install event
    final installResult = await client.reportInstall();
    
    if (installResult.isSuccess) {
      print('✅ Install event reported successfully!');
    } else {
      print('❌ Failed to report install event: ${installResult.error}');
    }
    
    // Wait a bit for processing
    await Future.delayed(const Duration(milliseconds: 500));
    
    print('\n=== TESTING REGULAR EVENTS ===');
    
    // Test regular events for comparison
    await client.track(name: 'test_event', properties: {'test': 'value'});
    await client.track(name: 'user_action', properties: {'action': 'click'});
    
    // Flush events
    final flushResult = await client.flush();
    if (flushResult.isSuccess) {
      print('✅ Regular events flushed successfully!');
    } else {
      print('❌ Failed to flush regular events: ${flushResult.error}');
    }
    
  } finally {
    await client.close();
    print('\n✓ Test completed');
  }
}