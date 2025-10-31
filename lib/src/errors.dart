/// Base exception class for analytics client errors
abstract class AnalyticsException implements Exception {
  /// Error message
  final String message;
  
  /// Operation that caused the error
  final String? operation;
  
  /// Additional context information
  final Map<String, dynamic>? context;

  const AnalyticsException(
    this.message, {
    this.operation,
    this.context,
  });

  @override
  String toString() {
    final parts = <String>[];
    if (operation != null) {
      parts.add('Operation: $operation');
    }
    parts.add('Message: $message');
    if (context != null && context!.isNotEmpty) {
      parts.add('Context: $context');
    }
    return '${runtimeType}(${parts.join(', ')})';
  }
}

/// Configuration related errors
class ConfigurationException extends AnalyticsException {
  const ConfigurationException(
    super.message, {
    super.operation,
    super.context,
  });
}

/// Network related errors
class NetworkException extends AnalyticsException {
  /// HTTP status code (if available)
  final int? statusCode;
  
  /// Response body (if available)
  final String? responseBody;

  const NetworkException(
    super.message, {
    this.statusCode,
    this.responseBody,
    super.operation,
    super.context,
  });

  @override
  String toString() {
    final parts = <String>[];
    if (operation != null) {
      parts.add('Operation: $operation');
    }
    parts.add('Message: $message');
    if (statusCode != null) {
      parts.add('Status Code: $statusCode');
    }
    if (responseBody != null) {
      parts.add('Response: $responseBody');
    }
    if (context != null && context!.isNotEmpty) {
      parts.add('Context: $context');
    }
    return '${runtimeType}(${parts.join(', ')})';
  }
}

/// Encryption related errors
class EncryptionException extends AnalyticsException {
  const EncryptionException(
    super.message, {
    super.operation,
    super.context,
  });
}

/// Serialization related errors
class SerializationException extends AnalyticsException {
  const SerializationException(
    super.message, {
    super.operation,
    super.context,
  });
}

/// Buffer overflow errors
class BufferOverflowException extends AnalyticsException {
  const BufferOverflowException(
    super.message, {
    super.operation,
    super.context,
  });
}

/// Client state errors (e.g., client already closed)
class ClientStateException extends AnalyticsException {
  const ClientStateException(
    super.message, {
    super.operation,
    super.context,
  });
}

/// Predefined error messages and factory methods
class AnalyticsErrors {
  static const String invalidServerUrl = 'Invalid server URL';
  static const String invalidProductName = 'Invalid product name';
  static const String networkTimeout = 'Network request timeout';
  static const String networkFailure = 'Network request failed';
  static const String encryptionFailed = 'Data encryption failed';
  static const String decryptionFailed = 'Data decryption failed';
  static const String invalidEncryptionKey = 'Invalid encryption key';
  static const String serializationFailed = 'Data serialization failed';
  static const String deserializationFailed = 'Data deserialization failed';
  static const String bufferFull = 'Event buffer is full';
  static const String clientClosed = 'Analytics client is closed';
  static const String deviceInfoFailed = 'Failed to get device information';

  /// Create a configuration exception
  static ConfigurationException configuration(
    String message, {
    String? operation,
    Map<String, dynamic>? context,
  }) {
    return ConfigurationException(
      message,
      operation: operation,
      context: context,
    );
  }

  /// Create a network exception
  static NetworkException network(
    String message, {
    int? statusCode,
    String? responseBody,
    String? operation,
    Map<String, dynamic>? context,
  }) {
    return NetworkException(
      message,
      statusCode: statusCode,
      responseBody: responseBody,
      operation: operation,
      context: context,
    );
  }

  /// Create an encryption exception
  static EncryptionException encryption(
    String message, {
    String? operation,
    Map<String, dynamic>? context,
  }) {
    return EncryptionException(
      message,
      operation: operation,
      context: context,
    );
  }

  /// Create a serialization exception
  static SerializationException serialization(
    String message, {
    String? operation,
    Map<String, dynamic>? context,
  }) {
    return SerializationException(
      message,
      operation: operation,
      context: context,
    );
  }

  /// Create a buffer overflow exception
  static BufferOverflowException bufferOverflow(
    String message, {
    String? operation,
    Map<String, dynamic>? context,
  }) {
    return BufferOverflowException(
      message,
      operation: operation,
      context: context,
    );
  }

  /// Create a client state exception
  static ClientStateException clientState(
    String message, {
    String? operation,
    Map<String, dynamic>? context,
  }) {
    return ClientStateException(
      message,
      operation: operation,
      context: context,
    );
  }
}

/// Result wrapper for operations that can fail
abstract class Result<T> {
  const Result();

  /// Check if the result is successful
  bool get isSuccess => this is Success<T>;

  /// Check if the result is a failure
  bool get isFailure => this is Failure<T>;

  /// Get the success value (throws if failure)
  T get value {
    if (this is Success<T>) {
      return (this as Success<T>).value;
    }
    throw StateError('Cannot get value from a failure result');
  }

  /// Get the error (throws if success)
  AnalyticsException get error {
    if (this is Failure<T>) {
      return (this as Failure<T>).error;
    }
    throw StateError('Cannot get error from a success result');
  }

  /// Execute a function if the result is successful
  Result<U> map<U>(U Function(T value) mapper) {
    if (this is Success<T>) {
      try {
        return Success(mapper((this as Success<T>).value));
      } catch (e) {
        return Failure(AnalyticsErrors.serialization(
          'Mapping failed: $e',
          operation: 'map',
        ));
      }
    }
    return Failure((this as Failure<T>).error);
  }

  /// Execute a function if the result is a failure
  Result<T> catchError(T Function(AnalyticsException error) handler) {
    if (this is Failure<T>) {
      try {
        return Success(handler((this as Failure<T>).error));
      } catch (e) {
        return Failure(AnalyticsErrors.serialization(
          'Error handler failed: $e',
          operation: 'catchError',
        ));
      }
    }
    return this;
  }
}

/// Successful result
class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  String toString() => 'Success($value)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Success<T> && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

/// Failed result
class Failure<T> extends Result<T> {
  final AnalyticsException error;

  const Failure(this.error);

  @override
  String toString() => 'Failure($error)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure<T> && other.error == error;
  }

  @override
  int get hashCode => error.hashCode;
}