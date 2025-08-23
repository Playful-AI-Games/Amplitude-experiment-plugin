import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

/// HTTP request object
class HttpRequest {
  final String url;
  final String method;
  final Map<String, String>? headers;
  final dynamic body;
  final Duration? timeout;

  const HttpRequest({
    required this.url,
    this.method = 'GET',
    this.headers,
    this.body,
    this.timeout,
  });
}

/// HTTP response object
class HttpResponse {
  final int statusCode;
  final Map<String, String> headers;
  final dynamic body;

  const HttpResponse({
    required this.statusCode,
    required this.headers,
    this.body,
  });
}

/// Abstract HTTP client interface
abstract class HttpClient {
  Future<HttpResponse> request(HttpRequest request);
}

/// Default HTTP client implementation using the http package
class DefaultHttpClient implements HttpClient {
  final http.Client _client;
  final Logger _logger;
  final String _apiKey;
  final String _libraryVersion;

  DefaultHttpClient({
    http.Client? client,
    Logger? logger,
    required String apiKey,
    String libraryVersion = '1.0.0',
  })  : _client = client ?? http.Client(),
        _logger = logger ?? Logger(),
        _apiKey = apiKey,
        _libraryVersion = libraryVersion;

  @override
  Future<HttpResponse> request(HttpRequest request) async {
    try {
      final uri = Uri.parse(request.url);
      
      // Prepare headers
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Api-Key $_apiKey',
        'X-Amp-Exp-Library': 'experiment-flutter-client/$_libraryVersion',
        ...?request.headers,
      };

      // Prepare body
      String? body;
      if (request.body != null) {
        if (request.body is String) {
          body = request.body;
        } else {
          body = jsonEncode(request.body);
        }
      }

      _logger.d('Request URL: ${request.url}');
      _logger.d('Request Method: ${request.method}');
      _logger.d('Request Headers: $headers');
      _logger.d('Request Body: $body');

      // Make request based on method
      http.Response response;
      switch (request.method.toUpperCase()) {
        case 'GET':
          response = await _client
              .get(uri, headers: headers)
              .timeout(request.timeout ?? const Duration(seconds: 10));
          break;
        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: body)
              .timeout(request.timeout ?? const Duration(seconds: 10));
          break;
        case 'PUT':
          response = await _client
              .put(uri, headers: headers, body: body)
              .timeout(request.timeout ?? const Duration(seconds: 10));
          break;
        case 'DELETE':
          response = await _client
              .delete(uri, headers: headers, body: body)
              .timeout(request.timeout ?? const Duration(seconds: 10));
          break;
        default:
          throw UnsupportedError('HTTP method ${request.method} not supported');
      }

      // Parse response
      dynamic responseBody;
      if (response.headers['content-type']?.contains('application/json') ?? false) {
        try {
          responseBody = jsonDecode(response.body);
        } catch (e) {
          responseBody = response.body;
        }
      } else {
        responseBody = response.body;
      }

      _logger.d('Response Status: ${response.statusCode}');
      _logger.d('Response Headers: ${response.headers}');
      _logger.d('Response Body: $responseBody');

      return HttpResponse(
        statusCode: response.statusCode,
        headers: response.headers,
        body: responseBody,
      );
    } on TimeoutException catch (e) {
      _logger.e('Request timeout', error: e);
      throw FetchTimeoutException('Request timed out');
    } catch (e) {
      _logger.e('Request failed', error: e);
      throw FetchException('Request failed: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Exception thrown when a fetch operation fails
class FetchException implements Exception {
  final String message;
  final int? statusCode;
  
  const FetchException(this.message, [this.statusCode]);
  
  @override
  String toString() => 'FetchException: $message${statusCode != null ? ' (status: $statusCode)' : ''}';
}

/// Exception thrown when a fetch operation times out
class FetchTimeoutException extends FetchException {
  const FetchTimeoutException(super.message);
  
  @override
  String toString() => 'FetchTimeoutException: $message';
}