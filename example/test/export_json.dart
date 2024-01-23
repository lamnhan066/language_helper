import 'package:flutter_test/flutter_test.dart';
import 'package:language_helper/language_helper.dart';
import 'package:language_helper_example/resources/language_helper/language_data.dart';

/// A script that let us able to run the `languageData.exportJson()`
void main() {
  test('', () {
    languageData.exportJson('./lib');
  });
}
