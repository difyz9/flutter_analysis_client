// Flutter App Integration Example
// 
// This example shows how to integrate product status checking
// into a real Flutter application startup flow.

import 'package:flutter/material.dart';
import '../lib/flutter_analysis_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize analytics
  Analytics.initialize(
    serverUrl: 'http://localhost:8080',
    productName: 'DigiBankApp',
    debug: true,
  );

  // Check if app can launch before starting
  final startupManager = AppStartupManager();
  final canStart = await startupManager.checkAppStatus();

  if (canStart) {
    runApp(MyApp());
  } else {
    runApp(MaintenanceApp());
  }
}

class AppStartupManager {
  /// Check app status and perform necessary startup checks
  Future<bool> checkAppStatus() async {
    try {
      print('🔍 Checking app status...');

      // Check product status
      final statusResult = await Analytics.instance.checkProductStatus();
      
      if (statusResult.isFailure) {
        print('❌ Failed to check product status: ${statusResult.error}');
        // In case of network error, allow app to start (graceful degradation)
        return true;
      }

      final statusResponse = statusResult.value;
      
      if (!statusResponse.isSuccess) {
        print('❌ Server returned error: ${statusResponse.message}');
        return false;
      }

      final productStatus = statusResponse.data;
      if (productStatus == null) {
        print('❌ No product data received');
        return false;
      }

      print('📊 Product Status: ${productStatus.status}');
      print('📱 Total Devices: ${productStatus.totalDevices}');
      print('📈 Active Devices (7d): ${productStatus.activeDevices7d}');

      if (productStatus.isActive) {
        print('✅ App is authorized to launch');
        
        // Report app launch since we're authorized
        await Analytics.instance.reportLaunch();
        
        return true;
      } else {
        print('🚫 App is not authorized to launch - Status: ${productStatus.status}');
        return false;
      }
      
    } catch (e) {
      print('💥 Unexpected error during startup check: $e');
      // Graceful degradation - allow app to start on unexpected errors
      return true;
    }
  }
}

/// Main application when startup is successful
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DigiBankApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DigiBankApp'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              '✅ App Successfully Launched',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Product status is active',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                // Track a user action
                await Analytics.instance.trackAction(
                  category: 'user',
                  action: 'button_click',
                  label: 'home_screen_action',
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Action tracked!')),
                );
              },
              child: Text('Track Action'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // Check status again
                final result = await Analytics.instance.canLaunchApp();
                final message = result.isSuccess && result.value
                    ? 'App is still authorized'
                    : 'App authorization changed';
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              },
              child: Text('Re-check Status'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Maintenance app when startup fails
class MaintenanceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maintenance',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MaintenanceScreen(),
    );
  }
}

class MaintenanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.build_circle,
                color: Colors.orange,
                size: 80,
              ),
              SizedBox(height: 24),
              Text(
                '🔧 App Under Maintenance',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'We\'re currently performing maintenance on the app. Please try again later.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.orange[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  // Try to check status again
                  final startupManager = AppStartupManager();
                  final canStart = await startupManager.checkAppStatus();
                  
                  if (canStart) {
                    // Restart the app
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => MyApp()),
                      (route) => false,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('App is still under maintenance'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alternative startup flow using FutureBuilder
class AppWithFutureBuilder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DigiBankApp',
      home: FutureBuilder<bool>(
        future: _checkAppStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SplashScreen();
          }
          
          if (snapshot.hasError) {
            return ErrorScreen(error: snapshot.error.toString());
          }
          
          final canLaunch = snapshot.data ?? false;
          return canLaunch ? HomeScreen() : MaintenanceScreen();
        },
      ),
    );
  }

  Future<bool> _checkAppStatus() async {
    final manager = AppStartupManager();
    return await manager.checkAppStatus();
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.blue[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Checking app status',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[800],
                ),
              ),
              SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}