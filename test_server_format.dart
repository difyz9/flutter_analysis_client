import 'dart:convert';
import 'lib/flutter_analysis_client.dart';

/// Test script to verify the data format sent to the server
void main() async {
  print('Testing Flutter client data format...\n');
  
  // Create a test client
  final client = AnalyticsClient.create(
    serverUrl: 'http://localhost:8080',
    productName: 'flutter_test_app',
    debug: true,
    logger: (message) => print('[LOG] $message'),
  );
  
  // Create test events
  final events = [
    AnalyticsEvent(
      name: 'test_event',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      properties: {'test': 'value'},
      category: 'user',
      action: 'click',
      label: 'button',
      value: 1.0,
    ),
  ];
  
  // Test single event format
  print('=== SINGLE EVENT FORMAT ===');
  final singlePayload = {
    'name': events.first.name,
    'product': 'flutter_test_app',
    'device_id': 'test-device-id',
    'timestamp': events.first.timestamp ~/ 1000, // Convert to seconds
    'category': events.first.category,
    'action': events.first.action,
    'label': events.first.label,
    'value': events.first.value,
    'properties': {
      ...?events.first.properties,
      'user_id': null,
      'session_id': 'test-session-id',
      'device_info': null,
    },
  };
  
  print('Single event payload for /api/events:');
  print(const JsonEncoder.withIndent('  ').convert(singlePayload));
  
  // Test batch events format
  print('\n=== BATCH EVENTS FORMAT ===');
  final batchPayload = {
    'events': events.map((event) => {
      'name': event.name,
      'product': 'flutter_test_app',
      'device_id': 'test-device-id',
      'timestamp': event.timestamp ~/ 1000, // Convert to seconds
      'category': event.category,
      'action': event.action,
      'label': event.label,
      'value': event.value,
      'properties': {
        ...?event.properties,
        'user_id': null,
        'session_id': 'test-session-id',
        'device_info': null,
      },
    }).toList(),
  };
  
  print('Batch events payload for /api/events/batch:');
  print(const JsonEncoder.withIndent('  ').convert(batchPayload));
  
  // Compare with Go client format (based on analytics.go)
  print('\n=== GO CLIENT FORMAT (for comparison) ===');
  final goClientPayload = {
    'product': 'flutter_test_app',
    'device_id': 'test-device-id',
    'user_id': null,
    'session_id': 'test-session-id',
    'events': events.map((event) => {
      'name': event.name,
      'timestamp': event.timestamp ~/ 1000, // Unix timestamp in seconds
      'properties': event.properties,
      'category': event.category,
      'action': event.action,
      'label': event.label,
      'value': event.value,
    }).toList(),
  };
  
  print('Go client payload format (what the server might expect):');
  print(const JsonEncoder.withIndent('  ').convert(goClientPayload));
  
  await client.close();
  print('\n✓ Format comparison complete');
}