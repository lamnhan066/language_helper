import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:language_helper/src/mixins/update_language.dart';

class UpdateLanguageMixinMock with UpdateLanguage {}

class CustomUpdateLanguageMixin with UpdateLanguage {
  int updateCount = 0;

  @override
  void updateLanguage() {
    updateCount++;
  }
}

class MockClient extends http.BaseClient {
  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return switch (url.path) {
      '/languages/codes.json' => Future.value(
        http.Response(jsonEncode(["en", "vi"]), 200),
      ),
      '/languages/data/en.json' => Future.value(
        http.Response(
          jsonEncode({
            "Hello": "Hello",
            "You have @number dollars": "You have @number dollars",
            "You have @{number}, dollars": "You have @{number}, dollars",
            "You have @{number} dollar": {
              "param": "number",
              "conditions": {
                "0": "You have zero dollar",
                "1": "You have @{number} dollar",
                "2": "You have @{number} dollars",
                "default": "You have @{number} dollars",
              },
            },
            "Text is missed in vi": "Text is missed in vi",
            "There are @number people in your family": {
              "param": "number",
              "conditions": {
                "0": "There is @number people in your family",
                "1": "There is @number people in your family",
                "2": "There are @number people in your family",
              },
            },
            "You have @{number} dollar in your wallet":
                "You have @{number} dollar in your wallet",
          }),
          200,
        ),
      ),
      '/languages/data/vi.json' => Future.value(
        http.Response(
          jsonEncode({
            "Hello": "Xin Chào",
            "You have @number dollars": "Bạn có @number đô-la",
            "You have @{number}, dollars": "Bạn có @{number}, đô-la",
            "You have @{number} dollar": "Bạn có @{number} đô-la",
            "Text is missed in en": "Text is missed in en",
            "There are @number people in your family":
                "Có @number người trong gia đình bạn",
            "You have @{number} dollar in your wallet":
                "Bạn có @{number} đô-la trong ví của bạn",
          }),
          200,
        ),
      ),
      _ => throw Exception('Unexpected request: $url'),
    };
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError();
  }
}
