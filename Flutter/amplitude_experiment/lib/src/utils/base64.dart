import 'dart:convert';

/// Base64 encoding utilities
class Base64Utils {
  /// Encode a string to URL-safe base64
  static String encodeURL(String input) {
    final bytes = utf8.encode(input);
    final base64String = base64.encode(bytes);
    // Make URL-safe by replacing + with -, / with _, and removing =
    return base64String
        .replaceAll('+', '-')
        .replaceAll('/', '_')
        .replaceAll('=', '');
  }
  
  /// Decode a URL-safe base64 string
  static String decodeURL(String input) {
    // Restore base64 characters
    String base64String = input
        .replaceAll('-', '+')
        .replaceAll('_', '/');
    
    // Add padding if needed
    final padding = (4 - base64String.length % 4) % 4;
    base64String += '=' * padding;
    
    final bytes = base64.decode(base64String);
    return utf8.decode(bytes);
  }
}