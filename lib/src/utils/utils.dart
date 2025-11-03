import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lite_logger/lite_logger.dart';

/// Utility functions for path manipulation and network operations.
class Utils {
  /// Removes trailing slashes from [path].
  ///
  /// This utility normalizes paths by removing all trailing `/` characters,
  /// ensuring consistent path formatting for asset and network URLs.
  ///
  /// Returns the normalized path without trailing slashes.
  ///
  /// Example:
  /// ```dart
  /// Utils.removeLastSlash('assets/languages/'); // 'assets/languages'
  /// Utils.removeLastSlash('https://api.com/');  // 'https://api.com'
  /// Utils.removeLastSlash('path');              // 'path'
  /// ```
  static String removeLastSlash(String path) {
    while (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    return path;
  }

  /// Fetches content from a network URL using HTTP GET request.
  ///
  /// This utility method retrieves content (typically JSON) from a remote URL
  /// with optional headers and a custom HTTP client.
  ///
  /// **Parameters:**
  /// - [uri] - The URI to fetch content from
  /// - [headers] - Optional HTTP headers (e.g., `{'Authorization': 'Bearer token'}`)
  /// - [client] - Optional custom HTTP client for advanced configuration (timeouts, interceptors, etc.)
  ///               If not provided, creates a new default client
  ///
  /// **Returns:**
  /// - UTF-8 decoded string content if the request succeeds (status code 200)
  /// - Empty string if the request fails, returns non-200 status, or throws an exception
  ///
  /// **Error handling:** Errors are logged but not thrown. Returns empty string on any failure.
  ///
  /// Example:
  /// ```dart
  /// final uri = Uri.parse('https://api.example.com/data.json');
  /// final content = await Utils.getUrl(uri);
  ///
  /// // With custom headers
  /// final content = await Utils.getUrl(
  ///   uri,
  ///   headers: {'Authorization': 'Bearer token'},
  /// );
  ///
  /// // With custom client (for timeouts, etc.)
  /// final client = http.Client();
  /// final content = await Utils.getUrl(uri, client: client);
  /// ```
  static Future<String> getUrl(
    Uri uri, {
    Map<String, String>? headers,
    http.Client? client,
  }) async {
    final logger = LiteLogger(
      name: 'GetUrl',
      enabled: true,
      minLevel: LogLevel.debug,
      usePrint: false,
    );
    client ??= http.Client();
    try {
      final response = await client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return utf8.decode(response.bodyBytes);
      } else {
        logger.warning(
          () =>
              'Failed to load data from URL. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      logger.error(() => 'Error fetching data from URL: $e');
    }

    return '';
  }
}
