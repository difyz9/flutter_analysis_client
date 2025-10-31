/// Flutter Analytics Client
/// 
/// A lightweight analytics client SDK for Flutter applications,
/// providing event tracking, user behavior analysis, and data collection capabilities.
/// 
/// ## Features
/// 
/// - 🚀 **High Performance**: Asynchronous event reporting without affecting main business performance
/// - 🔒 **Security**: AES encryption support for data transmission
/// - 📊 **Rich Events**: Support for custom events, user events, device information, etc.
/// - 🎯 **Batch Reporting**: Support for event batch reporting to improve transmission efficiency
/// - 🛡️ **Error Handling**: Comprehensive error handling and retry mechanisms
/// - 📱 **Multi-platform**: Support for Web, mobile, and other scenarios
/// - 📈 **Installation Statistics**: Automatic collection of installation information and app lifecycle data
/// - 🔄 **Session Management**: Automatic management of user sessions and device identification
/// 
/// ## Quick Start
/// 
/// ### Singleton Usage (Recommended - Most Convenient)
/// 
/// ```dart
/// import 'package:flutter_analysis_client/flutter_analysis_client.dart';
/// 
/// // Initialize once in main()
/// void main() {
///   Analytics.initialize(
///     serverUrl: 'http://localhost:8080',
///     productName: 'MyApp',
///     debug: true,
///   );
///   
///   runApp(MyApp());
/// }
/// 
/// // Use anywhere in your app - no need to pass the client around!
/// class MyWidget extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return ElevatedButton(
///       onPressed: () {
///         // Track event from anywhere
///         Analytics.instance.track(name: 'button_click');
///         // Or use static method
///         Analytics.trackStatic('button_click');
///       },
///       child: Text('Click Me'),
///     );
///   }
/// }
/// ```
/// 
/// ### Direct Client Usage (For Multiple Instances)
/// 
/// ```dart
/// import 'package:flutter_analysis_client/flutter_analysis_client.dart';
/// 
/// // Create client
/// final client = AnalyticsClient.create(
///   serverUrl: 'http://localhost:8080',
///   productName: 'MyApp',
///   debug: true,
/// );
/// 
/// // Track events
/// await client.track(name: 'button_click', properties: {
///   'button_name': 'login',
///   'screen': 'home',
/// });
/// 
/// // Close client when done
/// await client.close();
/// ```
library flutter_analysis_client;

// Export singleton (recommended for most use cases)
export 'src/analytics_singleton.dart' show Analytics;

// Export Dart client (works in all environments)
export 'src/dart_client.dart' show AnalyticsClient;

// Export models and utilities
export 'src/models.dart' show 
    AnalyticsEvent, 
    DeviceInfo, 
    AnalyticsConfig, 
    EncryptionConfig,
    ProductStatus,
    ProductStatusResponse;
export 'src/errors.dart' show 
    AnalyticsException,
    ConfigurationException,
    NetworkException,
    EncryptionException,
    SerializationException,
    BufferOverflowException,
    ClientStateException,
    AnalyticsErrors,
    Result,
    Success,
    Failure;
export 'src/encryption.dart' show AESEncryption;