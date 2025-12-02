import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lite_logger/lite_logger.dart';

/// Utility functions for path manipulation and network operations
class Utils {
  /// Removes trailing slashes from [path]. Normalizes paths for asset and
  /// network URLs.
  ///
  /// Parameters:
  /// - [path]: The path string to normalize (may contain trailing slashes).
  ///
  /// Returns the path with all trailing slashes removed.
  static String removeLastSlash(String path) {
    while (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    return path;
  }

  /// Fetches content from a network URL using HTTP GET. Returns UTF-8 decoded
  /// string on success (200), empty string on failure. Errors are logged but
  /// not thrown. Use [client] for custom timeouts/interceptors.
  ///
  /// Parameters:
  /// - [uri]: The URI to fetch content from.
  /// - [headers]: Optional HTTP headers to include in the request
  ///   (e.g., authentication tokens).
  /// - [client]: Optional HTTP client for custom configuration
  ///   (timeouts, interceptors).
  ///   If not provided, a default [http.Client] is used.
  ///
  /// Returns a [Future] that completes with the UTF-8 decoded response body
  /// on success, or an empty string on failure.
  static Future<String> getUrl(
    Uri uri, {
    Map<String, String>? headers,
    http.Client? client,
  }) async {
    const logger = LiteLogger(
      name: 'GetUrl',
      minLevel: LogLevel.debug,
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
