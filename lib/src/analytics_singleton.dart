import 'dart:async';

import 'dart_client.dart';
import 'models.dart';
import 'errors.dart';

/// Singleton wrapper for AnalyticsClient
/// 
/// Provides a convenient way to access the analytics client from anywhere in your app.
/// 
/// Usage:
/// ```dart
/// // Initialize once in your app (e.g., in main())
/// Analytics.initialize(
///   serverUrl: 'http://localhost:8080',
///   productName: 'MyApp',
///   debug: true,
/// );
/// 
/// // Use anywhere in your app
/// Analytics.instance.track(name: 'button_click');
/// Analytics.instance.reportLaunch();
/// 
/// // Or use convenience methods
/// Analytics.track('page_view', properties: {'page': 'home'});
/// Analytics.trackAction(category: 'user', action: 'login');
/// ```
class Analytics {
  /// The singleton instance
  static Analytics? _instance;
  
  /// The underlying analytics client
  late final AnalyticsClient _client;
  
  /// Private constructor
  Analytics._(this._client);
  
  /// Initialize the analytics singleton
  /// 
  /// This should be called once at app startup, typically in your main() function.
  /// Subsequent calls will throw an error unless [forceReinitialize] is true.
  static void initialize({
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
    bool forceReinitialize = false,
  }) {
    if (_instance != null && !forceReinitialize) {
      throw StateError(
        'Analytics has already been initialized. '
        'Use Analytics.instance to access it, or pass forceReinitialize: true to reinitialize.'
      );
    }
    
    // Close existing instance if reinitializing
    if (_instance != null && forceReinitialize) {
      _instance!._client.close();
    }
    
    final client = AnalyticsClient.create(
      serverUrl: serverUrl,
      productName: productName,
      deviceId: deviceId,
      userId: userId,
      timeout: timeout,
      batchSize: batchSize,
      flushInterval: flushInterval,
      bufferSize: bufferSize,
      debug: debug,
      encryption: encryption,
      logger: logger,
    );
    
    _instance = Analytics._(client);
  }
  
  /// Get the singleton instance
  /// 
  /// Throws [StateError] if [initialize] has not been called yet.
  static Analytics get instance {
    if (_instance == null) {
      throw StateError(
        'Analytics has not been initialized. '
        'Call Analytics.initialize() before accessing the instance.'
      );
    }
    return _instance!;
  }
  
  /// Check if Analytics has been initialized
  static bool get isInitialized => _instance != null;
  
  /// Access the underlying client directly if needed
  AnalyticsClient get client => _client;
  
  // =================== Convenience Methods ===================
  // These methods delegate to the underlying client
  
  /// Track an event
  Future<Result<void>> track({
    required String name,
    Map<String, dynamic>? properties,
    String? category,
    String? action,
    String? label,
    double? value,
  }) {
    return _client.track(
      name: name,
      properties: properties,
      category: category,
      action: action,
      label: label,
      value: value,
    );
  }
  
  /// Track a simple event with properties
  Future<Result<void>> trackEvent(String name, [Map<String, dynamic>? properties]) {
    return _client.trackEvent(name, properties);
  }
  
  /// Track user action
  Future<Result<void>> trackAction({
    required String category,
    required String action,
    String? label,
    double? value,
    Map<String, dynamic>? properties,
  }) {
    return _client.trackAction(
      category: category,
      action: action,
      label: label,
      value: value,
      properties: properties,
    );
  }
  
  /// Report app installation
  Future<Result<void>> reportInstall() {
    return _client.reportInstall();
  }
  
  /// Report app launch
  Future<Result<void>> reportLaunch() {
    return _client.reportLaunch();
  }
  
  /// Set user ID
  void setUserId(String userId) {
    _client.setUserId(userId);
  }
  
  /// Flush events to server
  Future<Result<void>> flush() {
    return _client.flush();
  }
  
  /// Get current session information
  Map<String, dynamic> get sessionInfo => _client.sessionInfo;
  
  /// Stream of tracked events
  Stream<AnalyticsEvent> get eventStream => _client.eventStream;
  
  /// Number of events in buffer
  int get bufferSize => _client.bufferSize;
  
  /// Whether the client is closed
  bool get isClosed => _client.isClosed;
  
  /// Close the client and flush remaining events
  Future<void> close() async {
    await _client.close();
    _instance = null;
  }
  
  // =================== Static Convenience Methods ===================
  // These provide even shorter syntax for common operations
  
  /// Track an event (static convenience method)
  static Future<Result<void>> trackStatic(
    String name, {
    Map<String, dynamic>? properties,
    String? category,
    String? action,
    String? label,
    double? value,
  }) {
    return instance.track(
      name: name,
      properties: properties,
      category: category,
      action: action,
      label: label,
      value: value,
    );
  }
  
  /// Track a simple event (static convenience method)
  static Future<Result<void>> trackEventStatic(
    String name, [
    Map<String, dynamic>? properties,
  ]) {
    return instance.trackEvent(name, properties);
  }
  
  /// Track user action (static convenience method)
  static Future<Result<void>> trackActionStatic({
    required String category,
    required String action,
    String? label,
    double? value,
    Map<String, dynamic>? properties,
  }) {
    return instance.trackAction(
      category: category,
      action: action,
      label: label,
      value: value,
      properties: properties,
    );
  }
  
  /// Set user ID (static convenience method)
  static void setUserIdStatic(String userId) {
    instance.setUserId(userId);
  }
  
  /// Flush events (static convenience method)
  static Future<Result<void>> flushStatic() {
    return instance.flush();
  }
}
