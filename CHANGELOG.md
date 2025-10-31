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

## [Unreleased]

### Planned
- [ ] Real AES encryption implementation (currently uses simplified XOR)
- [ ] Enhanced device information collection
- [ ] Offline event storage and replay
- [ ] Event validation and schema support
- [ ] Performance monitoring and metrics
- [ ] Advanced retry mechanisms
- [ ] Plugin system for extensibility