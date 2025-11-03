import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lite_logger/lite_logger.dart';

class Utils {
  static String removeLastSlash(String path) {
    while (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    return path;
  }

  static Future<String> getUrl(
    Uri uri, {
    Map<String, String>? headers,
    http.Client? client,
  }) async {
    final logger = LiteLogger(
      name: 'GetUrl',
      enabled: true,
      minLevel: LogLevel.debug,
    );
    client ??= http.Client();
    try {
      final response = await client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return utf8.decode(response.bodyBytes);
      } else {
        logger.debug(
          () =>
              'Failed to load data from URL. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      logger.debug(() => 'Error fetching data from URL: $e');
    }

    return '';
  }
}
