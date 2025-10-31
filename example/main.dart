import 'dart:async';

import '../lib/flutter_analysis_client.dart';

void main() async {
  print('Flutter Analytics Client Example');
  print('=================================');
  
  await basicUsageExample();
  await encryptedUsageExample();
  await flutterAppExample();
}

/// Basic usage example
Future<void> basicUsageExample() async {
  print('\n1. Basic Usage Example');
  print('----------------------');
  
  // Create analytics client
  final client = AnalyticsClient.create(
    serverUrl: 'http://localhost:8080',
    productName: 'flutter_test_app',
    debug: true,
    logger: (message) => print('[LOG] $message'),
  );
  
  try {
    // Report app launch
    final launchResult = await client.reportLaunch();
    if (launchResult.isSuccess) {
      print('✓ App launch reported successfully');
    } else {
      print('✗ Failed to report launch: ${launchResult.error}');
    }
    
    // Report app installation
    print('\n--- Testing Installation Event ---');
    final installResult = await client.reportInstall();
    if (installResult.isSuccess) {
      print('✓ App installation reported successfully');
    } else {
      print('✗ Failed to report installation: ${installResult.error}');
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
    
    // Manually flush events
    final flushResult = await client.flush();
    if (flushResult.isSuccess) {
      print('✓ Events flushed successfully');
    } else {
      print('✗ Failed to flush: ${flushResult.error}');
    }
    
    // Listen to event stream
    final subscription = client.eventStream.listen((event) {
      print('Event tracked: ${event.name}');
    });
    
    // Track a few more events
    await client.trackEvent('feature_used', {'feature': 'search'});
    await client.trackEvent('error_occurred', {'error_type': 'network'});
    
    // Clean up
    await subscription.cancel();
    
  } finally {
    // Always close the client
    await client.close();
    print('✓ Client closed');
  }
}

/// Encrypted usage example
Future<void> encryptedUsageExample() async {
  print('\n2. Encrypted Usage Example');
  print('---------------------------');
  
  // Create client with encryption
  final client = AnalyticsClient.create(
    serverUrl: 'https://analytics.example.com',
    productName: 'SecureApp',
    encryption: EncryptionConfig.enabled('my-secret-key-32-bytes-long!!!'),
    debug: true,
  );
  
  try {
    // Track encrypted events
    await client.trackEvent('sensitive_action', {
      'user_email': 'user@example.com',
      'payment_amount': 99.99,
    });
    
    await client.reportInstall();
    
    // Flush encrypted data
    await client.flush();
    
    print('✓ Encrypted events sent successfully');
    
  } finally {
    await client.close();
  }
}

/// Flutter app integration example
Future<void> flutterAppExample() async {
  print('\n3. Flutter App Integration Example');
  print('-----------------------------------');
  
  final analytics = AppAnalytics();
  await analytics.initialize();
  
  try {
    // Track app lifecycle events
    await analytics.trackAppLaunch();
    await analytics.trackScreenView('home');
    await analytics.trackUserAction('tap', 'navigation_button');
    
    // Track business events
    await analytics.trackPurchase(99.99, 'premium_subscription');
    await analytics.trackError('network_timeout', {'retry_count': 3});
    
    // Track user journey
    await analytics.trackUserJourney([
      'app_open',
      'view_products',
      'add_to_cart',
      'checkout',
      'payment_success',
    ]);
    
    print('✓ Flutter app analytics integration complete');
    
  } finally {
    await analytics.dispose();
  }
}

/// Example analytics wrapper for Flutter apps
class AppAnalytics {
  late AnalyticsClient _client;
  
  /// Initialize analytics
  Future<void> initialize() async {
    _client = AnalyticsClient.create(
      serverUrl: 'https://your-analytics-server.com',
      productName: 'YourFlutterApp',
      debug: true,
      batchSize: 10,
      flushInterval: const Duration(seconds: 3),
    );
    
    print('✓ Analytics initialized');
  }
  
  /// Track app launch
  Future<void> trackAppLaunch() async {
    await _client.reportLaunch();
  }
  
  /// Track screen view
  Future<void> trackScreenView(String screenName) async {
    await _client.trackEvent('screen_view', {
      'screen_name': screenName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track user action
  Future<void> trackUserAction(String action, String element) async {
    await _client.trackAction(
      category: 'ui',
      action: action,
      label: element,
      properties: {
        'session_id': _client.sessionInfo['session_id'],
      },
    );
  }
  
  /// Track purchase
  Future<void> trackPurchase(double amount, String product) async {
    await _client.trackEvent('purchase', {
      'amount': amount,
      'product': product,
      'currency': 'USD',
    });
  }
  
  /// Track error
  Future<void> trackError(String error, Map<String, dynamic>? context) async {
    await _client.trackEvent('error', {
      'error_type': error,
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track user journey
  Future<void> trackUserJourney(List<String> steps) async {
    for (int i = 0; i < steps.length; i++) {
      await _client.trackEvent('user_journey_step', {
        'step': steps[i],
        'step_number': i + 1,
        'total_steps': steps.length,
      });
    }
  }
  
  /// Set user ID
  void setUserId(String userId) {
    _client.setUserId(userId);
  }
  
  /// Dispose analytics
  Future<void> dispose() async {
    await _client.close();
    print('✓ Analytics disposed');
  }
}