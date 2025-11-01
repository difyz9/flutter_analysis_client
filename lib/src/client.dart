import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

import 'models.dart';
import 'errors.dart';
import 'encryption.dart';
import 'device_id_helper.dart';

/// Analytics client for tracking events and user behavior
class AnalyticsClient {
  /// Client configuration
  final AnalyticsConfig _config;
  
  /// Device information
  DeviceInfo? _deviceInfo;
  
  /// Current session ID
  late String _sessionId;
  
  /// Session start time
  late DateTime _sessionStartTime;
  
  /// Event buffer
  final List<AnalyticsEvent> _eventBuffer = [];
  
  /// HTTP client
  late http.Client _httpClient;
  
  /// Timer for auto-flush
  Timer? _flushTimer;
  
  /// Whether the client is closed
  bool _isClosed = false;
  
  /// Stream controller for events
  final StreamController<AnalyticsEvent> _eventController = 
      StreamController<AnalyticsEvent>.broadcast();
  
  /// Logger function
  void Function(String message)? _logger;

  /// Create a new analytics client
  AnalyticsClient(this._config) {
    _initializeClient();
  }

  /// Factory constructor with configuration builder
  factory AnalyticsClient.create({
    required String serverUrl,
    required String productName,
    String? deviceId,
    String? userId,
    Duration timeout = const Duration(seconds: 10),
    int batchSize = 20,
    Duration flushInterval = const Duration(seconds: 5),
    int bufferSize = 1000,
    bool debug = false,
    EncryptionConfig? encryption,
    void Function(String message)? logger,
  }) {
    final config = AnalyticsConfig(
      serverUrl: serverUrl,
      productName: productName,
      deviceId: deviceId,
      userId: userId,
      timeout: timeout,
      batchSize: batchSize,
      flushInterval: flushInterval,
      bufferSize: bufferSize,
      debug: debug,
      encryption: encryption ?? EncryptionConfig.disabled(),
    );
    
    final client = AnalyticsClient(config);
    if (logger != null) {
      client._logger = logger;
    }
    
    return client;
  }

  /// Initialize the client
  void _initializeClient() {
    _sessionId = const Uuid().v4();
    _sessionStartTime = DateTime.now();
    _httpClient = http.Client();
    
    // Start auto-flush timer
    _flushTimer = Timer.periodic(_config.flushInterval, (_) => flush());
    
    _log('Analytics client initialized with session: $_sessionId');
  }

  /// Initialize device information
  Future<void> _initializeDeviceInfo() async {
    if (_deviceInfo != null) return;
    
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      String deviceId = _config.deviceId ?? await _getOrCreateDeviceId();
      String platform;
      String? osVersion;
      String? deviceModel;
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        platform = 'Android';
        osVersion = androidInfo.version.release;
        deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        platform = 'iOS';
        osVersion = iosInfo.systemVersion;
        deviceModel = iosInfo.model;
      } else if (kIsWeb) {
        final webInfo = await deviceInfoPlugin.webBrowserInfo;
        platform = 'Web';
        osVersion = webInfo.platform;
        deviceModel = webInfo.browserName.name;
      } else {
        platform = Platform.operatingSystem;
        osVersion = Platform.operatingSystemVersion;
        deviceModel = null;
      }
      
      _deviceInfo = DeviceInfo(
        deviceId: deviceId,
        platform: platform,
        osVersion: osVersion,
        deviceModel: deviceModel,
        appVersion: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        language: Platform.localeName,
        timezone: DateTime.now().timeZoneName,
      );
      
      _log('Device info initialized: $platform, $deviceModel');
    } catch (e) {
      _log('Failed to initialize device info: $e');
      // Create minimal device info
      _deviceInfo = DeviceInfo(
        deviceId: _config.deviceId ?? const Uuid().v4(),
        platform: kIsWeb ? 'Web' : Platform.operatingSystem,
      );
    }
  }

  /// Get or create a persistent device ID
  /// Uses flutter_udid to get a device-specific unique identifier
  /// and converts it to a short 16-character hash
  Future<String> _getOrCreateDeviceId() async {
    try {
      // Use the new DeviceIdHelper to get a short device ID
      String deviceId = await DeviceIdHelper.getShortDeviceId();
      
      if (_config.debug) {
        // Log device ID info in debug mode
        final info = await DeviceIdHelper.getDeviceIdInfo();
        _log('Device ID Info:');
        info.forEach((key, value) {
          _log('  $key: $value');
        });
      }
      
      return deviceId;
    } catch (e) {
      _log('Failed to get device ID from flutter_udid: $e');
      
      // Fallback to the old method
      try {
        final prefs = await SharedPreferences.getInstance();
        String? deviceId = prefs.getString('analytics_device_id');
        
        if (deviceId == null) {
          deviceId = const Uuid().v4();
          await prefs.setString('analytics_device_id', deviceId);
        }
        
        return deviceId;
      } catch (e2) {
        _log('Failed to get/create fallback device ID: $e2');
        return const Uuid().v4();
      }
    }
  }

  /// Track an event
  Future<Result<void>> track({
    required String name,
    Map<String, dynamic>? properties,
    String? category,
    String? action,
    String? label,
    double? value,
  }) async {
    if (_isClosed) {
      return Failure(AnalyticsErrors.clientState(
        AnalyticsErrors.clientClosed,
        operation: 'track',
      ));
    }

    try {
      final event = AnalyticsEvent.now(
        name: name,
        properties: properties,
        category: category,
        action: action,
        label: label,
        value: value,
      );

      // Add to buffer
      _eventBuffer.add(event);
      _eventController.add(event);

      _log('Event tracked: $name');

      // Flush if buffer is full
      if (_eventBuffer.length >= _config.batchSize) {
        await flush();
      }

      return const Success(null);
    } catch (e) {
      return Failure(AnalyticsErrors.serialization(
        'Failed to track event: $e',
        operation: 'track',
        context: {'event_name': name},
      ));
    }
  }

  /// Track a simple event with properties
  Future<Result<void>> trackEvent(String name, [Map<String, dynamic>? properties]) {
    return track(name: name, properties: properties);
  }

  /// Track user action
  Future<Result<void>> trackAction({
    required String category,
    required String action,
    String? label,
    double? value,
    Map<String, dynamic>? properties,
  }) {
    return track(
      name: '${category}_$action',
      category: category,
      action: action,
      label: label,
      value: value,
      properties: properties,
    );
  }

  /// Check product status by name
  Future<Result<ProductStatusResponse>> checkProductStatus([String? productName]) async {
    try {
      final name = productName ?? _config.productName;
      final uri = Uri.parse('${_config.serverUrl}/api/products/$name');
      
      final response = await _httpClient
          .get(uri, headers: {
            'accept': 'application/json',
            'User-Agent': 'flutter-analytics-client/1.0.0',
          })
          .timeout(_config.timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
          final statusResponse = ProductStatusResponse.fromJson(jsonData);
          
          _log('Product status checked: ${statusResponse.data?.status ?? 'unknown'}');
          return Success(statusResponse);
        } catch (e) {
          return Failure(AnalyticsErrors.serialization(
            'Failed to parse product status response: $e',
            operation: 'checkProductStatus',
            context: {'product_name': name, 'response_body': response.body},
          ));
        }
      } else {
        return Failure(AnalyticsErrors.network(
          'Server returned error: ${response.statusCode}',
          statusCode: response.statusCode,
          responseBody: response.body,
          operation: 'checkProductStatus',
        ));
      }
    } on TimeoutException {
      return Failure(AnalyticsErrors.network(
        AnalyticsErrors.networkTimeout,
        operation: 'checkProductStatus',
      ));
    } on SocketException catch (e) {
      return Failure(AnalyticsErrors.network(
        'Network error: $e',
        operation: 'checkProductStatus',
      ));
    } catch (e) {
      return Failure(AnalyticsErrors.network(
        'Unexpected error: $e',
        operation: 'checkProductStatus',
      ));
    }
  }

  /// Check if the product can be launched (status is 'active')
  Future<Result<bool>> canLaunchApp([String? productName]) async {
    final result = await checkProductStatus(productName);
    
    if (result.isFailure) {
      return Failure(result.error);
    }
    
    return Success(result.value.canLaunch);
  }

  /// Report app installation
  Future<Result<void>> reportInstall() async {
    try {
      await _initializeDeviceInfo();
      
      // Create install event payload for /api/installs/push
      final installPayload = {
        'product': _config.productName,
        'device_id': _deviceInfo?.deviceId ?? 'unknown',
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unix timestamp in seconds
        'sign': '', // Empty sign for now (可以后续添加签名逻辑)
        
        // Optional device information
        if (_deviceInfo?.platform != null) 'platform': _deviceInfo!.platform,
        if (_deviceInfo?.osVersion != null) 'platform_version': _deviceInfo!.osVersion,
        if (_deviceInfo?.deviceModel != null) 'kernel_arch': _deviceInfo!.deviceModel,
        'user_agent': 'flutter-analytics-client/1.0.0',
      };

      // Serialize payload
      final jsonData = jsonEncode(installPayload);
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'User-Agent': 'flutter-analytics-client/1.0.0',
      };

      // Send HTTP request to install endpoint
      final uri = Uri.parse('${_config.serverUrl}/api/installs/push');
      final response = await _httpClient
          .post(uri, headers: headers, body: utf8.encode(jsonData))
          .timeout(_config.timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (_config.debug) {
          _log('Successfully reported app installation');
        }
        return const Success(null);
      } else {
        return Failure(AnalyticsErrors.network(
          'Server returned error: ${response.statusCode}',
          statusCode: response.statusCode,
          responseBody: response.body,
          operation: 'reportInstall',
        ));
      }
    } on TimeoutException {
      return Failure(AnalyticsErrors.network(
        AnalyticsErrors.networkTimeout,
        operation: 'reportInstall',
      ));
    } catch (e) {
      return Failure(AnalyticsErrors.network(
        'Network error: $e',
        operation: 'reportInstall',
      ));
    }
  }

  /// Report app launch
  Future<Result<void>> reportLaunch() async {
    await _initializeDeviceInfo();
    
    return track(
      name: 'app_launch',
      category: 'lifecycle',
      action: 'launch',
      properties: {
        'session_id': _sessionId,
        'app_version': _deviceInfo?.appVersion,
        'platform': _deviceInfo?.platform,
      },
    );
  }

  /// Set user ID
  void setUserId(String userId) {
    // Update config with new user ID
    // Note: In a real implementation, you might want to make config mutable
    _log('User ID set: $userId');
  }

  /// Flush events to server
  Future<Result<void>> flush() async {
    if (_isClosed) {
      return Failure(AnalyticsErrors.clientState(
        AnalyticsErrors.clientClosed,
        operation: 'flush',
      ));
    }

    if (_eventBuffer.isEmpty) {
      return const Success(null);
    }

    await _initializeDeviceInfo();

    try {
      // Create a copy of events and clear buffer
      final events = List<AnalyticsEvent>.from(_eventBuffer);
      _eventBuffer.clear();

      _log('Flushing ${events.length} events');

      // Send events to server
      final result = await _sendEvents(events);
      
      if (result.isFailure) {
        // Re-add events to buffer if send failed
        _eventBuffer.insertAll(0, events);
        return Failure(result.error);
      }

      _log('Successfully flushed ${events.length} events');
      return const Success(null);
    } catch (e) {
      return Failure(AnalyticsErrors.network(
        'Failed to flush events: $e',
        operation: 'flush',
      ));
    }
  }

  /// Send events to server
  Future<Result<void>> _sendEvents(List<AnalyticsEvent> events) async {
    try {
      // Create payload
      final payload = {
        'product': _config.productName,
        'device_id': _deviceInfo?.deviceId ?? 'unknown',
        'user_id': _config.userId,
        'session_id': _sessionId,
        'events': events.map((e) => e.toJson()).toList(),
        'device_info': _deviceInfo?.toJson(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Serialize payload
      final jsonData = jsonEncode(payload);
      late List<int> requestBody;
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'User-Agent': 'flutter-analytics-client/1.0.0',
      };

      // Encrypt if enabled
      if (_config.encryption.enabled) {
        final encryptResult = AESEncryption.encrypt(
          _config.encryption.secretKey,
          utf8.encode(jsonData),
        );
        
        if (encryptResult.isFailure) {
          return Failure(encryptResult.error);
        }

        final encryptedPayload = {'data': encryptResult.value};
        requestBody = utf8.encode(jsonEncode(encryptedPayload));
      } else {
        requestBody = utf8.encode(jsonData);
      }

      // Send HTTP request
      final uri = Uri.parse('${_config.serverUrl}/api/events');
      final response = await _httpClient
          .post(uri, headers: headers, body: requestBody)
          .timeout(_config.timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Success(null);
      } else {
        return Failure(AnalyticsErrors.network(
          'Server returned error: ${response.statusCode}',
          statusCode: response.statusCode,
          responseBody: response.body,
          operation: 'sendEvents',
        ));
      }
    } on TimeoutException {
      return Failure(AnalyticsErrors.network(
        AnalyticsErrors.networkTimeout,
        operation: 'sendEvents',
      ));
    } on SocketException catch (e) {
      return Failure(AnalyticsErrors.network(
        'Network error: $e',
        operation: 'sendEvents',
      ));
    } catch (e) {
      return Failure(AnalyticsErrors.network(
        'Unexpected error: $e',
        operation: 'sendEvents',
      ));
    }
  }

  /// Get current session information
  Map<String, dynamic> get sessionInfo => {
    'session_id': _sessionId,
    'session_start': _sessionStartTime.millisecondsSinceEpoch,
    'device_id': _deviceInfo?.deviceId ?? 'unknown',
    'user_id': _config.userId,
  };

  /// Stream of tracked events
  Stream<AnalyticsEvent> get eventStream => _eventController.stream;

  /// Number of events in buffer
  int get bufferSize => _eventBuffer.length;

  /// Whether the client is closed
  bool get isClosed => _isClosed;

  /// Close the client and flush remaining events
  Future<void> close() async {
    if (_isClosed) return;

    _isClosed = true;
    _log('Closing analytics client');

    // Cancel timer
    _flushTimer?.cancel();

    // Flush remaining events
    if (_eventBuffer.isNotEmpty) {
      await flush();
    }

    // Close HTTP client
    _httpClient.close();

    // Close stream controller
    await _eventController.close();

    _log('Analytics client closed');
  }

  /// Log debug message
  void _log(String message) {
    if (_config.debug) {
      final timestamp = DateTime.now().toIso8601String();
      final logMessage = '[$timestamp] [Analytics] $message';
      
      if (_logger != null) {
        _logger!(logMessage);
      } else if (kDebugMode) {
        print(logMessage);
      }
    }
  }
}