import 'lib/flutter_analysis_client.dart';

/// Complete end-to-end test of all analytics features
void main() async {
  print('🧪 Complete Analytics Client Test');
  print('==================================\n');
  
  // Create client
  final client = AnalyticsClient.create(
    serverUrl: 'http://localhost:8080',
    productName: 'flutter_e2e_test',
    debug: true,
    logger: (message) => print('[LOG] $message'),
  );
  
  try {
    int testsPassed = 0;
    int testsTotal = 0;
    
    // Test 1: Install Event
    testsTotal++;
    print('🔍 Test 1: Install Event');
    final installResult = await client.reportInstall();
    if (installResult.isSuccess) {
      print('✅ Install event sent successfully');
      testsPassed++;
    } else {
      print('❌ Install event failed: ${installResult.error}');
    }
    
    // Test 2: Launch Event
    testsTotal++;
    print('\n🔍 Test 2: Launch Event');
    final launchResult = await client.reportLaunch();
    if (launchResult.isSuccess) {
      print('✅ Launch event sent successfully');
      testsPassed++;
    } else {
      print('❌ Launch event failed: ${launchResult.error}');
    }
    
    // Test 3: Basic Tracking
    testsTotal++;
    print('\n🔍 Test 3: Basic Event Tracking');
    await client.track(name: 'test_basic_event', properties: {'test': 'value'});
    print('✅ Basic event tracked');
    testsPassed++;
    
    // Test 4: User Actions
    testsTotal++;
    print('\n🔍 Test 4: User Action Tracking');
    await client.trackAction(
      category: 'user',
      action: 'click',
      label: 'test_button',
      value: 1.0,
      properties: {'screen': 'test'},
    );
    print('✅ User action tracked');
    testsPassed++;
    
    // Test 5: User Management
    testsTotal++;
    print('\n🔍 Test 5: User Management');
    client.setUserId('test-user-123');
    await client.track(name: 'user_identified', properties: {'user_type': 'test'});
    print('✅ User identification set and tracked');
    testsPassed++;
    
    // Test 6: Batch Flush
    testsTotal++;
    print('\n🔍 Test 6: Event Flushing');
    final flushResult = await client.flush();
    if (flushResult.isSuccess) {
      print('✅ Events flushed successfully');
      testsPassed++;
    } else {
      print('❌ Flush failed: ${flushResult.error}');
    }
    
    // Test 7: Session Info
    testsTotal++;
    print('\n🔍 Test 7: Session Information');
    final sessionInfo = client.sessionInfo;
    if (sessionInfo['session_id'] != null && sessionInfo['device_id'] != null) {
      print('✅ Session info available: ${sessionInfo['session_id']}');
      print('   Device ID: ${sessionInfo['device_id']}');
      testsPassed++;
    } else {
      print('❌ Session info missing');
    }
    
    // Results
    print('\n📊 Test Results');
    print('===============');
    print('Tests passed: $testsPassed/$testsTotal');
    if (testsPassed == testsTotal) {
      print('🎉 All tests passed! Flutter client is working correctly with Go server.');
    } else {
      print('⚠️  Some tests failed. Please check the server connection and configuration.');
    }
    
  } finally {
    await client.close();
    print('\n✨ Test completed');
  }
}