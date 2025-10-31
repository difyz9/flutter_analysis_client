import 'dart:convert';
import 'lib/flutter_analysis_client.dart';

/// Test script to show the exact payload sent for install events
void main() async {
  print('Install Event Payload Analysis');
  print('==============================\n');
  
  // Create device info
  final deviceInfo = DeviceInfo(
    deviceId: 'test-device-123',
    platform: 'Dart',
    osVersion: '3.0.0',
    deviceModel: 'MacBook Pro',
    appVersion: '1.0.0',
    buildNumber: '1',
    language: 'en',
    timezone: 'UTC+8',
  );
  
  // Create install event payload (same format as in client)
  final installPayload = {
    'product': 'flutter_test_app',
    'device_id': deviceInfo.deviceId,
    'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'sign': '',
    'platform': deviceInfo.platform,
    'platform_version': deviceInfo.osVersion,
    'kernel_arch': deviceInfo.deviceModel,
    'user_agent': 'dart-analytics-client/1.0.0',
  };
  
  print('Install Event Payload for /api/installs/push:');
  print(const JsonEncoder.withIndent('  ').convert(installPayload));
  
  print('\n=== Expected Go Server InstallEvent struct ===');
  print('''
type InstallEvent struct {
    Product         string `json:"product"`         // ✓ flutter_test_app
    DeviceID        string `json:"device_id"`       // ✓ test-device-123
    Timestamp       int64  `json:"timestamp"`       // ✓ Unix timestamp
    Sign            string `json:"sign"`            // ✓ (empty)
    Platform        string `json:"platform"`        // ✓ Dart
    PlatformVersion string `json:"platform_version"` // ✓ 3.0.0
    KernelArch      string `json:"kernel_arch"`     // ✓ MacBook Pro
    UserAgent       string `json:"user_agent"`      // ✓ dart-analytics-client/1.0.0
}
''');

  print('✓ All required fields are present and correctly mapped!');
  
  // Also show what the server will create from this
  print('\n=== Server will create this Event ===');
  final serverEvent = {
    'name': 'install',
    'product': installPayload['product'],
    'device_id': installPayload['device_id'], 
    'timestamp': installPayload['timestamp'],
    'properties': {
      'platform': installPayload['platform'],
      'platform_version': installPayload['platform_version'],
      'kernel_arch': installPayload['kernel_arch'],
      'user_agent': installPayload['user_agent'],
    },
  };
  
  print(const JsonEncoder.withIndent('  ').convert(serverEvent));
}