/// Example: Using Analytics Singleton
/// 
/// This example demonstrates how to use the Analytics singleton
/// for convenient access from anywhere in your application.

import 'package:flutter_analysis_client/flutter_analysis_client.dart';

void main() async {
  print('=== Analytics Singleton Example ===\n');

  // Step 1: Initialize Analytics once at app startup
  print('1. Initializing Analytics...');
  Analytics.initialize(
    serverUrl: 'http://localhost:8080',
    productName: 'singleton_demo',
    debug: true,
  );
  print('✓ Analytics initialized\n');

  // Step 2: Use from main function
  print('2. Reporting app launch from main()...');
  final launchResult = await Analytics.instance.reportLaunch();
  if (launchResult.isSuccess) {
    print('✓ Launch reported successfully\n');
  }

  // Step 3: Simulate using from different parts of the app
  await simulateHomeScreen();
  await simulateProfileScreen();
  await simulateSettingsScreen();

  // Step 4: Flush and close
  print('5. Flushing remaining events...');
  await Analytics.instance.flush();
  print('✓ Events flushed\n');

  print('6. Closing Analytics...');
  await Analytics.instance.close();
  print('✓ Analytics closed\n');

  print('=== Example Complete ===');
}

/// Simulate tracking from home screen
Future<void> simulateHomeScreen() async {
  print('3. Tracking events from HomeScreen...');
  
  // Track page view
  await Analytics.instance.track(
    name: 'page_view',
    properties: {
      'page': 'home',
      'timestamp': DateTime.now().toIso8601String(),
    },
  );
  
  // Track button click using static method
  await Analytics.trackStatic(
    'button_click',
    properties: {
      'button': 'get_started',
      'screen': 'home',
    },
  );
  
  print('✓ Home screen events tracked\n');
}

/// Simulate tracking from profile screen
Future<void> simulateProfileScreen() async {
  print('4. Tracking events from ProfileScreen...');
  
  // Set user ID
  Analytics.instance.setUserId('user_12345');
  
  // Track action
  await Analytics.instance.trackAction(
    category: 'profile',
    action: 'edit',
    label: 'avatar',
    properties: {
      'screen': 'profile',
    },
  );
  
  // Track event
  await Analytics.instance.trackEvent('profile_updated', {
    'fields_changed': ['avatar', 'name'],
    'timestamp': DateTime.now().toIso8601String(),
  });
  
  print('✓ Profile screen events tracked\n');
}

/// Simulate tracking from settings screen
Future<void> simulateSettingsScreen() async {
  print('5. Tracking events from SettingsScreen...');
  
  // Track multiple events
  await Analytics.trackActionStatic(
    category: 'settings',
    action: 'toggle',
    label: 'notifications',
    value: 1.0,
  );
  
  await Analytics.trackEventStatic('settings_changed', {
    'setting': 'theme',
    'value': 'dark',
  });
  
  print('✓ Settings screen events tracked\n');
}

/// Example: Using in a Flutter widget
/// 
/// ```dart
/// import 'package:flutter/material.dart';
/// import 'package:flutter_analysis_client/flutter_analysis_client.dart';
/// 
/// class MyButton extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return ElevatedButton(
///       onPressed: () {
///         // Track from anywhere - no need to pass client around!
///         Analytics.instance.track(
///           name: 'button_pressed',
///           properties: {'button': 'my_button'},
///         );
///       },
///       child: Text('Press Me'),
///     );
///   }
/// }
/// 
/// class AnotherWidget extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return GestureDetector(
///       onTap: () {
///         // Or use static method for even shorter syntax
///         Analytics.trackStatic('tap', properties: {'widget': 'another'});
///       },
///       child: Container(child: Text('Tap Me')),
///     );
///   }
/// }
/// ```
