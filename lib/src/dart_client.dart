import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'models.dart';
import 'errors.dart';
import 'encryption.dart';

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

  /// Initialize device information with basic data
  void _initializeDeviceInfo() {
    if (_deviceInfo != null) return;
    
    try {
      String deviceId = _config.deviceId ?? const Uuid().v4();
      String platform = 'Dart';
      
      _deviceInfo = DeviceInfo(
        deviceId: deviceId,
        platform: platform,
        osVersion: null,
        deviceModel: null,
        appVersion: '1.0.0',
        buildNumber: '1',
        language: 'en',
        timezone: 'UTC',
      );
      
      _log('Device info initialized: $platform, ID: $deviceId');
    } catch (e) {
      _log('Failed to initialize device info: $e');
      _deviceInfo = DeviceInfo(
        deviceId: _config.deviceId ?? const Uuid().v4(),
        platform: 'Unknown',
      );
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

      // Check buffer overflow
      if (_eventBuffer.length >= _config.bufferSize) {
        return Failure(AnalyticsErrors.bufferOverflow(
          AnalyticsErrors.bufferFull,
          operation: 'track',
        ));
      }

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
            'User-Agent': 'dart-analytics-client/1.0.0',
          })
          .timeout(_config.timeout);

      _log(response.toString());
      
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
    } catch (e) {
      return Failure(AnalyticsErrors.network(
        'Unexpected error: $e',
        operation: 'checkProductStatus',
      ));
    }
  }

  /// Check if the product can be launched (status is 'active')
  /// 
  /// Returns true if:
  /// - Product status is 'active'
  /// - Network connection fails (graceful degradation)
  /// - Timeout occurs (graceful degradation)
  /// 
  /// Returns false only if:
  /// - Server responds but product status is not 'active'
  /// - Server returns an error response
  Future<Result<bool>> canLaunchApp([String? productName]) async {
    final result = await checkProductStatus(productName);
    
    if (result.isFailure) {
      final error = result.error;
      
      // Check if it's a network-related error (timeout, connection failure, etc.)
      // In these cases, allow the app to launch (graceful degradation)
      if (error is NetworkException) {
        final isNetworkError = error.message.contains('timeout') ||
                              error.message.contains('Network error') ||
                              error.message.contains('Unexpected error') ||
                              error.statusCode == null; // No status code means connection failed
        
        if (isNetworkError) {
          _log('Network error during status check, allowing app launch (graceful degradation): ${error.message}');
          return const Success(true);
        }
      }
      
      // For other types of errors or server errors with status codes, deny launch
      _log('Status check failed, denying app launch: ${error.message}');
      return Failure(result.error);
    }
    
    return Success(result.value.canLaunch);
  }

  /// Report app installation
  Future<Result<void>> reportInstall() async {
    try {
      _initializeDeviceInfo();
      
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
        'user_agent': 'dart-analytics-client/1.0.0',
      };

      // Serialize payload
      final jsonData = jsonEncode(installPayload);
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'User-Agent': 'dart-analytics-client/1.0.0',
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
    _initializeDeviceInfo();
    
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
    _log('User ID set: $userId');
    // Track user identification
    track(name: 'user_identify', properties: {'user_id': userId});
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

    _initializeDeviceInfo();

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
      if (events.isEmpty) {
        return const Success(null);
      }

      late Map<String, dynamic> payload;
      late String endpoint;

      // Use appropriate endpoint and format based on number of events
      if (events.length == 1) {
        // Single event - use /api/events endpoint with direct event format
        final event = events.first;
        payload = {
          'name': event.name,
          'product': _config.productName,
          'device_id': _deviceInfo?.deviceId ?? 'unknown',
          'timestamp': event.timestamp ~/ 1000, // Convert from milliseconds to seconds
          if (event.category != null) 'category': event.category,
          if (event.action != null) 'action': event.action,
          if (event.label != null) 'label': event.label,
          if (event.value != null) 'value': event.value,
          'properties': {
            ...?event.properties,
            'user_id': _config.userId,
            'session_id': _sessionId,
            'device_info': _deviceInfo?.toJson(),
          },
        };
        endpoint = '/api/events';
      } else {
        // Multiple events - use /api/events/batch endpoint
        final eventsData = events.map((event) => {
          'name': event.name,
          'product': _config.productName,
          'device_id': _deviceInfo?.deviceId ?? 'unknown',
          'timestamp': event.timestamp ~/ 1000, // Convert from milliseconds to seconds
          if (event.category != null) 'category': event.category,
          if (event.action != null) 'action': event.action,
          if (event.label != null) 'label': event.label,
          if (event.value != null) 'value': event.value,
          'properties': {
            ...?event.properties,
            'user_id': _config.userId,
            'session_id': _sessionId,
            'device_info': _deviceInfo?.toJson(),
          },
        }).toList();
        
        payload = {'events': eventsData};
        endpoint = '/api/events/batch';
      }

      // Serialize payload
      final jsonData = jsonEncode(payload);
      late Uint8List requestBody;
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'User-Agent': 'dart-analytics-client/1.0.0',
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
      final uri = Uri.parse('${_config.serverUrl}$endpoint');
      final response = await _httpClient
          .post(uri, headers: headers, body: requestBody)
          .timeout(_config.timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (_config.debug) {
          _log('Successfully sent ${events.length} event(s) to $endpoint');
        }
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
    } catch (e) {
      return Failure(AnalyticsErrors.network(
        'Network error: $e',
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
      } else {
        print(logMessage);
      }
    }
  }
}