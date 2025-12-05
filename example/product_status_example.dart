import '../lib/flutter_analysis_client.dart';

/// Example showing how to check product status before launching an app
void main() async {
  // Create analytics client
  final client = AnalyticsClient.create(
    serverUrl: 'http://localhost:8080',
    productName: 'HelloWorldApp',
    debug: true,
  );

  print('Checking product status...');

  try {
    // Method 1: Check product status and get detailed information
    final statusResult = await client.checkProductStatus();
    
    if (statusResult.isSuccess) {
      final statusResponse = statusResult.value;
      print('Product Status Response:');
      print('  Code: ${statusResponse.code}');
      print('  Message: ${statusResponse.message}');
      
      if (statusResponse.data != null) {
        final productStatus = statusResponse.data!;
        print('  Product Details:');
        print('    Name: ${productStatus.name}');
        print('    Display Name: ${productStatus.displayName}');
        print('    Status: ${productStatus.status}');

        
        // Check if app can be launched
        if (productStatus.isActive) {
          print('✅ App can be launched - Status is active');
          
          // Since the app can be launched, report the launch
          await client.reportLaunch();
          print('📊 App launch reported');
        } else {
          print('❌ App cannot be launched - Status is ${productStatus.status}');
        }
      }
    } else {
      print('❌ Failed to check product status: ${statusResult.error}');
    }

    // Method 2: Simple boolean check
    print('\nSimple launch check...');
    final canLaunchResult = await client.canLaunchApp();
    
    if (canLaunchResult.isSuccess) {
      if (canLaunchResult.value) {
        print('✅ App launch is allowed');
      } else {
        print('❌ App launch is not allowed');
      }
    } else {
      print('❌ Failed to check launch permission: ${canLaunchResult.error}');
    }

    // Method 3: Check status for a different product
    print('\nChecking status for another product...');
    final otherProductResult = await client.checkProductStatus('AnotherApp');
    
    if (otherProductResult.isSuccess) {
      final canLaunch = otherProductResult.value.canLaunch;
      print('AnotherApp can launch: $canLaunch');
    } else {
      print('Failed to check AnotherApp status: ${otherProductResult.error}');
    }

  } catch (e) {
    print('Unexpected error: $e');
  } finally {
    // Clean up
    await client.close();
    print('Analytics client closed');
  }
}

/// Example of integrating product status check into app startup
class AppStartupManager {
  final AnalyticsClient _analyticsClient;

  AppStartupManager(this._analyticsClient);

  /// Check if app can start and perform startup sequence
  Future<bool> startApp() async {
    print('🚀 Starting app initialization...');

    // Step 1: Check product status
    final canLaunchResult = await _analyticsClient.canLaunchApp();
    
    if (canLaunchResult.isFailure) {
      print('❌ Failed to verify app status: ${canLaunchResult.error}');
      return false;
    }

    if (!canLaunchResult.value) {
      print('❌ App is not authorized to launch');
      // You might want to show a specific UI message to the user
      await _showMaintenanceMessage();
      return false;
    }

    print('✅ App is authorized to launch');

    // Step 2: Report installation if this is first launch
    await _analyticsClient.reportInstall();

    // Step 3: Report app launch
    await _analyticsClient.reportLaunch();

    // Step 4: Continue with normal app initialization
    await _initializeApp();

    return true;
  }

  Future<void> _showMaintenanceMessage() async {
    // In a real app, this would show a maintenance/unavailable screen
    print('🔧 Showing maintenance message to user');
  }

  Future<void> _initializeApp() async {
    // Your normal app initialization logic here
    print('📱 App initialized successfully');
  }
}

/// Example usage in a Flutter app's main function
void exampleFlutterIntegration() async {
  // Initialize analytics client
  final analyticsClient = AnalyticsClient.create(
    serverUrl: 'http://localhost:8080',
    productName: 'HelloWorldApp',
    debug: true,
  );

  // Create startup manager
  final startupManager = AppStartupManager(analyticsClient);

  // Try to start the app
  final appStarted = await startupManager.startApp();

  if (appStarted) {
    // Continue with Flutter app initialization
    // runApp(MyApp());
    print('🎉 Flutter app ready to run');
  } else {
    // Show error screen or exit
    print('💥 App startup failed');
  }
}