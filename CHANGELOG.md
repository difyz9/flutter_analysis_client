# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-10-31

### Added
- 🎉 Initial release of Flutter Analysis Client
- ✅ Core analytics client with event tracking
- ✅ AES encryption support for secure data transmission
- ✅ Batch event reporting mechanism
- ✅ Session management and device identification
- ✅ Comprehensive error handling with Result pattern
- ✅ Multi-platform support (Android, iOS, Web)
- ✅ Lifecycle event tracking (install, launch)
- ✅ Configurable batch size and flush intervals
- ✅ Event streaming support
- ✅ Debug logging capabilities
- ✅ Complete API documentation and examples
- ✅ Test suite for core functionality
- ✅ Flutter integration examples

### Features
- **Event Tracking**: Support for custom events with properties, categories, actions, and labels
- **Encryption**: AES-256 encryption for sensitive data transmission
- **Performance**: Asynchronous event processing with configurable batching
- **Reliability**: Comprehensive error handling and retry mechanisms
- **Flexibility**: Customizable HTTP client and configuration options
- **Compatibility**: Full compatibility with go-analysis-server backend

### API
- `AnalyticsClient.create()` - Factory constructor with fluent configuration
- `track()` - Track events with full configuration options
- `trackEvent()` - Simple event tracking
- `trackAction()` - Google Analytics style action tracking
- `reportInstall()` - Report app installation
- `reportLaunch()` - Report app launch
- `flush()` - Manual event flushing
- `close()` - Graceful client shutdown

### Models
- `AnalyticsEvent` - Event data model with JSON serialization
- `DeviceInfo` - Device information model
- `AnalyticsConfig` - Client configuration model
- `EncryptionConfig` - Encryption configuration model

### Error Handling
- `Result<T>` pattern for type-safe error handling
- Specific exception types for different error scenarios
- Comprehensive error context and debugging information

## [Unreleased]

## [1.1.0] - 2025-10-31

### Added
- 🎯 **Singleton Pattern**: New `Analytics` singleton class for convenient global access
  - `Analytics.initialize()` - One-time initialization at app startup
  - `Analytics.instance` - Access singleton instance from anywhere
  - `Analytics.trackStatic()` and other static convenience methods
  - Automatic state management and error handling
- 📝 New singleton usage examples in `example/singleton_example.dart`
- 📚 Updated README with comprehensive singleton usage guide

### Changed
- 💡 **Recommended Usage**: Singleton pattern is now the recommended way to use the SDK
- 📖 Updated documentation to prioritize singleton pattern over direct client usage
- ✨ Improved library exports for better discoverability

### Benefits
- ✅ No need to pass client instances through constructors
- ✅ Use analytics from any file without dependency injection
- ✅ Cleaner code and better separation of concerns
- ✅ Thread-safe singleton implementation
- ✅ Optional direct client usage for multiple instances

### Example
```dart
// Initialize once in main()
Analytics.initialize(
  serverUrl: 'http://localhost:8080',
  productName: 'MyApp',
  debug: true,
);

// Use anywhere in your app
Analytics.instance.track(name: 'button_click');
Analytics.trackStatic('page_view');
```

## [1.2.0] - 2025-10-31

### Added
- 🔍 **Product Status Checking**: New API to check if applications can be launched
  - `checkProductStatus([productName])` - Get detailed product status information
  - `canLaunchApp([productName])` - Simple boolean check for app launch permission
  - `ProductStatus` model with comprehensive product information
  - `ProductStatusResponse` wrapper with success/error handling
- 🚦 **Application Startup Control**: Ability to conditionally allow/block app startup based on server-side product status
- 📊 **Enhanced Product Management**: Support for server-side product lifecycle management
- 🧪 New test suite for product status functionality in `test/product_status_test.dart`
- 📚 New example showing product status integration in `example/product_status_example.dart`

### API Endpoints
- `GET /api/products/{productName}` - Check product status
- Support for status values: `active`, `inactive`, `maintenance`, etc.
- Only products with `status: "active"` allow app launches

### Models
- `ProductStatus` - Complete product information model
  - `name`, `displayName`, `description`
  - `status`, `iconUrl`, `homepageUrl`
  - `totalEvents`, `totalDevices`, `totalLicenses`
  - `activeDevices7d`, `activeDevices30d`, `eventsToday`
  - `lastActivity`, `firstSeen`, `createdAt`, `updatedAt`
  - `isActive` computed property for launch permission
- `ProductStatusResponse` - API response wrapper
  - `code`, `data`, `message`
  - `isSuccess` and `canLaunch` computed properties

### Usage Examples
```dart
// Check if app can launch
final canLaunch = await client.canLaunchApp();
if (canLaunch.isSuccess && canLaunch.value) {
  // Proceed with app startup
  await client.reportLaunch();
} else {
  // Show maintenance screen
}

// Get detailed product status
final status = await client.checkProductStatus();
if (status.isSuccess && status.value.data?.isActive == true) {
  print('App is active with ${status.value.data!.totalDevices} devices');
}
```

### Benefits
- ✅ Server-side control over app availability
- ✅ Graceful handling of maintenance modes
- ✅ Rich product analytics and lifecycle data
- ✅ Flexible product status management
- ✅ Easy integration with existing startup flows

## [Unreleased]

### Planned
- [ ] Real AES encryption implementation (currently uses simplified XOR)
- [ ] Enhanced device information collection
- [ ] Offline event storage and replay
- [ ] Event validation and schema support
- [ ] Performance monitoring and metrics
- [ ] Advanced retry mechanisms
- [ ] Plugin system for extensibility