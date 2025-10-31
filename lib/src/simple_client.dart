import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'models.dart';
import 'errors.dart';
import 'encryption.dart';

/// A simple HTTP client interface
abstract class HttpClient {
  Future<HttpResponse> post(String url, {
    Map<String, String>? headers,
    Uint8List? body,
  });
  void close();
}

/// HTTP response
class HttpResponse {
  final int statusCode;
  final String body;
  final Map<String, String> headers;

  HttpResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
  });
}

/// Simple analytics client for Flutter applications
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
  HttpClient? _httpClient;
  
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
  AnalyticsClient(this._config, {HttpClient? httpClient}) {
    _httpClient = httpClient;
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
    HttpClient? httpClient,
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
    
    final client = AnalyticsClient(config, httpClient: httpClient);
    if (logger != null) {
      client._logger = logger;
    }
    
    return client;
  }

  /// Initialize the client
  void _initializeClient() {
    _sessionId = _generateUuid();
    _sessionStartTime = DateTime.now();
    
    // Start auto-flush timer
    _flushTimer = Timer.periodic(_config.flushInterval, (_) => flush());
    
    _log('Analytics client initialized with session: $_sessionId');
  }

  /// Generate a simple UUID
  String _generateUuid() {
    final random = Random();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    
    // Set version and variant bits
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant
    
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  /// Initialize device information with minimal data
  void _initializeDeviceInfo() {
    if (_deviceInfo != null) return;
    
    try {
      String deviceId = _config.deviceId ?? _generateUuid();
      String platform = 'Unknown';
      
      // Try to detect platform from user agent or other means
      // This is a simplified version
      
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
      
      _log('Device info initialized: $platform');
    } catch (e) {
      _log('Failed to initialize device info: $e');
      _deviceInfo = DeviceInfo(
        deviceId: _config.deviceId ?? _generateUuid(),
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

  /// Report app installation
  Future<Result<void>> reportInstall() async {
    _initializeDeviceInfo();
    
    return track(
      name: 'app_install',
      category: 'lifecycle',
      action: 'install',
      properties: {
        'app_version': _deviceInfo?.appVersion,
        'platform': _deviceInfo?.platform,
        'device_model': _deviceInfo?.deviceModel,
        'os_version': _deviceInfo?.osVersion,
      },
    );
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
    // In a real implementation, you might want to track this as an event
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
    if (_httpClient == null) {
      _log('No HTTP client available, skipping send');
      return const Success(null);
    }

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
      late Uint8List requestBody;
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
      final url = '${_config.serverUrl}/api/events';
      final response = await _httpClient!.post(
        url,
        headers: headers,
        body: requestBody,
      );

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
    _httpClient?.close();

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