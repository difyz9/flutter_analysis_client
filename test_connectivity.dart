import 'dart:convert';
import 'package:http/http.dart' as http;

/// Test script to check server connectivity and send a test event
void main() async {
  print('Testing server connectivity...\n');
  
  const serverUrl = 'http://localhost:8080';
  
  // Test 1: Check health endpoint
  print('1. Testing health endpoint...');
  try {
    final healthResponse = await http.get(Uri.parse('$serverUrl/health'));
    print('Health check status: ${healthResponse.statusCode}');
    print('Health response: ${healthResponse.body}');
  } catch (e) {
    print('❌ Server not accessible: $e');
    print('Please start the server with: go run main.go');
    return;
  }
  
  // Test 2: Send a single event
  print('\n2. Testing single event endpoint...');
  final singleEventPayload = {
    'name': 'test_connection',
    'product': 'flutter_test_app',
    'device_id': 'test-device-id',
    'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'category': 'test',
    'action': 'connectivity',
    'label': 'flutter_client',
    'value': 1.0,
    'properties': {
      'test_type': 'connectivity_check',
      'client': 'flutter_dart_client',
    },
  };
  
  try {
    final response = await http.post(
      Uri.parse('$serverUrl/api/events'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(singleEventPayload),
    );
    
    print('Single event status: ${response.statusCode}');
    print('Single event response: ${response.body}');
  } catch (e) {
    print('❌ Single event failed: $e');
  }
  
  // Test 3: Send batch events
  print('\n3. Testing batch events endpoint...');
  final batchEventPayload = {
    'events': [
      {
        'name': 'batch_test_1',
        'product': 'flutter_test_app',
        'device_id': 'test-device-id',
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'category': 'test',
        'action': 'batch',
        'label': 'event_1',
        'value': 1.0,
        'properties': {'batch_index': 1},
      },
      {
        'name': 'batch_test_2',
        'product': 'flutter_test_app',
        'device_id': 'test-device-id',
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'category': 'test',
        'action': 'batch',
        'label': 'event_2',
        'value': 2.0,
        'properties': {'batch_index': 2},
      },
    ],
  };
  
  try {
    final response = await http.post(
      Uri.parse('$serverUrl/api/events/batch'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(batchEventPayload),
    );
    
    print('Batch events status: ${response.statusCode}');
    print('Batch events response: ${response.body}');
  } catch (e) {
    print('❌ Batch events failed: $e');
  }
  
  print('\n✓ Connectivity test complete');
}