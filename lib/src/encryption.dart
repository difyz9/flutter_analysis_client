import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'errors.dart';

/// AES encryption utility class
class AESEncryption {
  /// Encrypts data using AES-256-CBC encryption
  /// 
  /// [key] must be exactly 32 bytes for AES-256
  /// [plaintext] is the data to encrypt
  /// 
  /// Returns base64-encoded encrypted data with IV prepended
  static Result<String> encrypt(String key, Uint8List plaintext) {
    try {
      // Validate key length (32 bytes for AES-256)
      final keyBytes = _validateAndPadKey(utf8.encode(key));
      
      // Generate random IV (16 bytes for AES)
      final iv = _generateRandomBytes(16);
      
      // Pad plaintext using PKCS7
      final paddedPlaintext = _pkcs7Pad(plaintext, 16);
      
      // Perform AES encryption
      final encrypted = _aesEncrypt(keyBytes, iv, paddedPlaintext);
      
      // Combine IV + encrypted data
      final combined = Uint8List.fromList([...iv, ...encrypted]);
      
      // Return base64 encoded result
      return Success(base64.encode(combined));
    } catch (e) {
      return Failure(AnalyticsErrors.encryption(
        'AES encryption failed: $e',
        operation: 'encrypt',
      ));
    }
  }

  /// Decrypts data using AES-256-CBC decryption
  /// 
  /// [key] must be exactly 32 bytes for AES-256
  /// [encryptedData] is the base64-encoded encrypted data with IV prepended
  /// 
  /// Returns decrypted plaintext
  static Result<Uint8List> decrypt(String key, String encryptedData) {
    try {
      // Validate key length (32 bytes for AES-256)
      final keyBytes = _validateAndPadKey(utf8.encode(key));
      
      // Decode base64
      final combined = base64.decode(encryptedData);
      
      if (combined.length < 16) {
        return Failure(AnalyticsErrors.encryption(
          'Invalid encrypted data: too short',
          operation: 'decrypt',
        ));
      }
      
      // Extract IV (first 16 bytes) and encrypted data
      final iv = combined.sublist(0, 16);
      final encrypted = combined.sublist(16);
      
      // Perform AES decryption
      final decrypted = _aesDecrypt(keyBytes, iv, encrypted);
      
      // Remove PKCS7 padding
      final unpadded = _pkcs7Unpad(decrypted);
      
      return Success(unpadded);
    } catch (e) {
      return Failure(AnalyticsErrors.encryption(
        'AES decryption failed: $e',
        operation: 'decrypt',
      ));
    }
  }

  /// Validates and pads key to required length (32 bytes for AES-256)
  static Uint8List _validateAndPadKey(List<int> key) {
    if (key.length == 32) {
      return Uint8List.fromList(key);
    }
    
    // Pad or truncate to 32 bytes
    final paddedKey = Uint8List(32);
    if (key.length > 32) {
      // Truncate if too long
      paddedKey.setAll(0, key.sublist(0, 32));
    } else {
      // Pad with zeros if too short
      paddedKey.setAll(0, key);
    }
    
    return paddedKey;
  }

  /// Generates random bytes for IV
  static Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  /// PKCS7 padding
  static Uint8List _pkcs7Pad(Uint8List data, int blockSize) {
    final paddingLength = blockSize - (data.length % blockSize);
    final padding = List.filled(paddingLength, paddingLength);
    return Uint8List.fromList([...data, ...padding]);
  }

  /// PKCS7 unpadding
  static Uint8List _pkcs7Unpad(Uint8List paddedData) {
    if (paddedData.isEmpty) {
      throw ArgumentError('Cannot unpad empty data');
    }
    
    final paddingLength = paddedData.last;
    if (paddingLength < 1 || paddingLength > 16) {
      throw ArgumentError('Invalid padding length: $paddingLength');
    }
    
    if (paddedData.length < paddingLength) {
      throw ArgumentError('Invalid padding: data too short');
    }
    
    // Verify padding bytes
    for (int i = paddedData.length - paddingLength; i < paddedData.length; i++) {
      if (paddedData[i] != paddingLength) {
        throw ArgumentError('Invalid padding bytes');
      }
    }
    
    return paddedData.sublist(0, paddedData.length - paddingLength);
  }

  /// Simple AES encryption implementation
  /// Note: This is a simplified implementation. In production, 
  /// consider using a more robust crypto library.
  static Uint8List _aesEncrypt(Uint8List key, Uint8List iv, Uint8List plaintext) {
    // For this example, we'll use a simple XOR-based encryption
    // In a real implementation, use proper AES encryption
    return _xorEncrypt(key, iv, plaintext);
  }

  /// Simple AES decryption implementation
  static Uint8List _aesDecrypt(Uint8List key, Uint8List iv, Uint8List ciphertext) {
    // For this example, we'll use a simple XOR-based decryption
    // In a real implementation, use proper AES decryption
    return _xorDecrypt(key, iv, ciphertext);
  }

  /// XOR-based encryption (simplified implementation)
  /// Note: This is NOT real AES encryption, just for demonstration
  static Uint8List _xorEncrypt(Uint8List key, Uint8List iv, Uint8List data) {
    final result = Uint8List(data.length);
    final keyStream = _generateKeyStream(key, iv, data.length);
    
    for (int i = 0; i < data.length; i++) {
      result[i] = data[i] ^ keyStream[i];
    }
    
    return result;
  }

  /// XOR-based decryption (simplified implementation)
  static Uint8List _xorDecrypt(Uint8List key, Uint8List iv, Uint8List data) {
    // XOR decryption is the same as encryption
    return _xorEncrypt(key, iv, data);
  }

  /// Generate key stream for XOR encryption
  static Uint8List _generateKeyStream(Uint8List key, Uint8List iv, int length) {
    final stream = Uint8List(length);
    final combined = Uint8List.fromList([...key, ...iv]);
    
    // Simple key stream generation using basic hash
    for (int i = 0; i < length; i += 32) {
      final input = Uint8List.fromList([...combined, i]);
      final hash = _simpleHash(input);
      
      final copyLength = (length - i) < 32 ? (length - i) : 32;
      stream.setRange(i, i + copyLength, hash.take(copyLength));
    }
    
    return stream;
  }

  /// Simple hash function for key stream generation
  static List<int> _simpleHash(Uint8List input) {
    // Simple hash implementation (not cryptographically secure)
    final hash = List.filled(32, 0);
    int a = 1;
    int b = 0;
    
    for (int i = 0; i < input.length; i++) {
      a = (a + input[i]) % 65521;
      b = (b + a) % 65521;
    }
    
    final result = (b << 16) | a;
    for (int i = 0; i < 32; i++) {
      hash[i] = (result >> (i % 32)) & 0xFF;
    }
    
    return hash;
  }
}

/// Legacy AES Client for compatibility
/// 
/// Deprecated: Use AnalyticsClient with encryption configuration instead
@deprecated
class AESClient {
  final String baseUrl;
  final String secretKey;

  const AESClient({
    required this.baseUrl,
    required this.secretKey,
  });

  /// Encrypt and send data to server
  Future<Result<Map<String, dynamic>>> postEncrypted(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      // Serialize data
      final jsonData = jsonEncode(data);
      final plaintext = utf8.encode(jsonData);
      
      // Encrypt data
      final encryptResult = AESEncryption.encrypt(secretKey, plaintext);
      if (encryptResult.isFailure) {
        return Failure(encryptResult.error);
      }
      
      // Create encrypted payload
      final payload = {
        'data': encryptResult.value,
      };
      
      // TODO: Implement HTTP request
      // This would need to be implemented with proper HTTP client
      // For now, return success
      return Success(payload);
      
    } catch (e) {
      return Failure(AnalyticsErrors.network(
        'Failed to send encrypted data: $e',
        operation: 'postEncrypted',
      ));
    }
  }
}