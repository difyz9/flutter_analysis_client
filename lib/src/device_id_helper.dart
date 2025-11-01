import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_udid/flutter_udid.dart';

/// Helper class for device ID management
class DeviceIdHelper {
  /// Get or create a short device ID (16-character hexadecimal)
  /// 
  /// This method:
  /// 1. Uses flutter_udid to get the device's unique identifier
  /// 2. Converts the UDID to a short 16-character hash using MD5
  /// 
  /// Returns a 16-character hexadecimal string (e.g., "a1b2c3d4e5f60718")
  static Future<String> getShortDeviceId() async {
    try {
      // Get the device UDID (flutter_udid already ensures consistency)
      final udid = await FlutterUdid.consistentUdid;
      
      // Convert to short device ID
      return _generateShortDeviceId(udid);
    } catch (e) {
      // If flutter_udid fails, fall back to timestamp-based ID
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      return _generateShortDeviceId(timestamp);
    }
  }
  
  /// Get the full original UDID (for debugging purposes)
  static Future<String> getOriginalUdid() async {
    try {
      return await FlutterUdid.consistentUdid;
    } catch (e) {
      return 'unknown';
    }
  }
  
  /// Convert long UDID to short 16-character hash using MD5
  /// 
  /// Takes the first 16 hex characters (8 bytes = 64 bits)
  static String _generateShortDeviceId(String udid) {
    final bytes = utf8.encode(udid);
    final digest = md5.convert(bytes);
    // Take first 16 hexadecimal characters (8 bytes)
    return digest.toString().substring(0, 16);
  }
  
  /// Get device ID info for debugging
  static Future<Map<String, String>> getDeviceIdInfo() async {
    try {
      final originalUdid = await getOriginalUdid();
      final shortId = await getShortDeviceId();
      
      return {
        'original_udid': originalUdid,
        'short_device_id': shortId,
        'hash_method': 'MD5 (first 16 chars)',
        'id_length': shortId.length.toString(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }
}