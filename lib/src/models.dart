/// Represents an analytics event
class AnalyticsEvent {
  /// Event name
  final String name;
  
  /// Event timestamp (Unix timestamp in milliseconds)
  final int timestamp;
  
  /// Event properties (key-value pairs)
  final Map<String, dynamic>? properties;
  
  /// Optional: Google Analytics style category
  final String? category;
  
  /// Optional: Google Analytics style action
  final String? action;
  
  /// Optional: Google Analytics style label
  final String? label;
  
  /// Optional: Google Analytics style value
  final double? value;

  const AnalyticsEvent({
    required this.name,
    required this.timestamp,
    this.properties,
    this.category,
    this.action,
    this.label,
    this.value,
  });

  /// Create an AnalyticsEvent from JSON
  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      name: json['name'] as String,
      timestamp: json['timestamp'] as int,
      properties: json['properties'] as Map<String, dynamic>?,
      category: json['category'] as String?,
      action: json['action'] as String?,
      label: json['label'] as String?,
      value: (json['value'] as num?)?.toDouble(),
    );
  }

  /// Convert AnalyticsEvent to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'timestamp': timestamp,
      if (properties != null) 'properties': properties,
      if (category != null) 'category': category,
      if (action != null) 'action': action,
      if (label != null) 'label': label,
      if (value != null) 'value': value,
    };
  }

  /// Create an event with current timestamp
  factory AnalyticsEvent.now({
    required String name,
    Map<String, dynamic>? properties,
    String? category,
    String? action,
    String? label,
    double? value,
  }) {
    return AnalyticsEvent(
      name: name,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      properties: properties,
      category: category,
      action: action,
      label: label,
      value: value,
    );
  }

  @override
  String toString() {
    return 'AnalyticsEvent(name: $name, timestamp: $timestamp, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalyticsEvent &&
        other.name == name &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => name.hashCode ^ timestamp.hashCode;
}

/// Device information for analytics
class DeviceInfo {
  /// Device identifier
  final String deviceId;
  
  /// Platform (iOS, Android, Web, etc.)
  final String platform;
  
  /// Operating system version
  final String? osVersion;
  
  /// Device model
  final String? deviceModel;
  
  /// App version
  final String? appVersion;
  
  /// App build number
  final String? buildNumber;
  
  /// Device language
  final String? language;
  
  /// Device timezone
  final String? timezone;

  const DeviceInfo({
    required this.deviceId,
    required this.platform,
    this.osVersion,
    this.deviceModel,
    this.appVersion,
    this.buildNumber,
    this.language,
    this.timezone,
  });

  /// Create DeviceInfo from JSON
  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceId: json['device_id'] as String,
      platform: json['platform'] as String,
      osVersion: json['os_version'] as String?,
      deviceModel: json['device_model'] as String?,
      appVersion: json['app_version'] as String?,
      buildNumber: json['build_number'] as String?,
      language: json['language'] as String?,
      timezone: json['timezone'] as String?,
    );
  }

  /// Convert DeviceInfo to JSON
  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'platform': platform,
      if (osVersion != null) 'os_version': osVersion,
      if (deviceModel != null) 'device_model': deviceModel,
      if (appVersion != null) 'app_version': appVersion,
      if (buildNumber != null) 'build_number': buildNumber,
      if (language != null) 'language': language,
      if (timezone != null) 'timezone': timezone,
    };
  }

  @override
  String toString() {
    return 'DeviceInfo(deviceId: $deviceId, platform: $platform)';
  }
}

/// Encryption configuration
class EncryptionConfig {
  /// Whether encryption is enabled
  final bool enabled;
  
  /// AES secret key (16, 24, or 32 bytes for AES-128, AES-192, or AES-256)
  final String secretKey;

  const EncryptionConfig({
    required this.enabled,
    required this.secretKey,
  });

  /// Create disabled encryption config
  factory EncryptionConfig.disabled() {
    return const EncryptionConfig(enabled: false, secretKey: '');
  }

  /// Create enabled encryption config with secret key
  factory EncryptionConfig.enabled(String secretKey) {
    return EncryptionConfig(enabled: true, secretKey: secretKey);
  }
}

/// Product status information
class ProductStatus {
  /// Product name
  final String name;
  
  /// Display name
  final String displayName;
  
  /// Product description
  final String description;
  
  /// Icon URL
  final String iconUrl;
  
  /// Homepage URL
  final String homepageUrl;
  
  /// Product status (active, inactive, etc.)
  final String status;
  
  // /// Total events count
  // final int totalEvents;
  
  // /// Total devices count
  // final int totalDevices;
  
  // /// Total licenses count
  // final int totalLicenses;
  
  // /// Active devices in last 7 days
  // final int activeDevices7d;
  
  // /// Active devices in last 30 days
  // final int activeDevices30d;
  
  // /// Events today count
  // final int eventsToday;
  
  // /// Last activity timestamp
  // final String lastActivity;
  
  // /// First seen timestamp
  // final String firstSeen;
  
  /// Created at timestamp
  final String createdAt;
  
  /// Updated at timestamp
  final String updatedAt;

  const ProductStatus({
    required this.name,
    required this.displayName,
    required this.description,
    required this.iconUrl,
    required this.homepageUrl,
    required this.status,
    // required this.totalEvents,
    // required this.totalDevices,
    // required this.totalLicenses,
    // required this.activeDevices7d,
    // required this.activeDevices30d,
    // required this.eventsToday,
    // required this.lastActivity,
    // required this.firstSeen,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create ProductStatus from JSON
  factory ProductStatus.fromJson(Map<String, dynamic> json) {
    return ProductStatus(
      name: json['name'] as String,
      displayName: json['display_name'] as String,
      description: json['description'] as String,
      iconUrl: json['icon_url'] as String,
      homepageUrl: json['homepage_url'] as String,
      status: json['status'] as String,
      // totalEvents: json['total_events'] as int,
      // totalDevices: json['total_devices'] as int,
      // totalLicenses: json['total_licenses'] as int,
      // activeDevices7d: json['active_devices_7d'] as int,
      // activeDevices30d: json['active_devices_30d'] as int,
      // eventsToday: json['events_today'] as int,
      // lastActivity: json['last_activity'] as String,
      // firstSeen: json['first_seen'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  /// Convert ProductStatus to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'display_name': displayName,
      'description': description,
      'icon_url': iconUrl,
      'homepage_url': homepageUrl,
      'status': status,
      // 'total_events': totalEvents,
      // 'total_devices': totalDevices,
      // 'total_licenses': totalLicenses,
      // 'active_devices_7d': activeDevices7d,
      // 'active_devices_30d': activeDevices30d,
      // 'events_today': eventsToday,
      // 'last_activity': lastActivity,
      // 'first_seen': firstSeen,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Check if the product is active and can be launched
  bool get isActive => status == 'active';

  @override
  String toString() {
    return 'ProductStatus(name: $name, status: $status, isActive: $isActive)';
  }
}

/// Product status response wrapper
class ProductStatusResponse {
  /// Response code
  final int code;
  
  /// Product status data
  final ProductStatus? data;
  
  /// Response message
  final String message;

  const ProductStatusResponse({
    required this.code,
    this.data,
    required this.message,
  });

  /// Create ProductStatusResponse from JSON
  factory ProductStatusResponse.fromJson(Map<String, dynamic> json) {
    return ProductStatusResponse(
      code: json['code'] as int,
      data: json['data'] != null ? ProductStatus.fromJson(json['data'] as Map<String, dynamic>) : null,
      message: json['message'] as String,
    );
  }

  /// Check if the response is successful
  bool get isSuccess => code == 200;

  /// Check if the product can be launched
  bool get canLaunch => isSuccess && data?.isActive == true;

  @override
  String toString() {
    return 'ProductStatusResponse(code: $code, message: $message, canLaunch: $canLaunch)';
  }
}

/// Analytics client configuration
class AnalyticsConfig {
  /// Server URL
  final String serverUrl;
  
  /// Product name
  final String productName;
  
  /// Device ID (optional, will be generated if not provided)
  final String? deviceId;
  
  /// User ID (optional)
  final String? userId;
  
  /// HTTP timeout duration
  final Duration timeout;
  
  /// Batch size for events
  final int batchSize;
  
  /// Flush interval for sending events
  final Duration flushInterval;
  
  /// Event buffer size
  final int bufferSize;
  
  /// Enable debug logging
  final bool debug;
  
  /// Encryption configuration
  final EncryptionConfig encryption;

  const AnalyticsConfig({
    required this.serverUrl,
    required this.productName,
    this.deviceId,
    this.userId,
    this.timeout = const Duration(seconds: 10),
    this.batchSize = 20,
    this.flushInterval = const Duration(seconds: 5),
    this.bufferSize = 1000,
    this.debug = false,
    this.encryption = const EncryptionConfig(enabled: false, secretKey: ''),
  });

  /// Create a copy of the config with updated values
  AnalyticsConfig copyWith({
    String? serverUrl,
    String? productName,
    String? deviceId,
    String? userId,
    Duration? timeout,
    int? batchSize,
    Duration? flushInterval,
    int? bufferSize,
    bool? debug,
    EncryptionConfig? encryption,
  }) {
    return AnalyticsConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      productName: productName ?? this.productName,
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      timeout: timeout ?? this.timeout,
      batchSize: batchSize ?? this.batchSize,
      flushInterval: flushInterval ?? this.flushInterval,
      bufferSize: bufferSize ?? this.bufferSize,
      debug: debug ?? this.debug,
      encryption: encryption ?? this.encryption,
    );
  }
}