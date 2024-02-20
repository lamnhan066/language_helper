import 'package:flutter_test/flutter_test.dart';
import 'package:language_helper/language_helper.dart';
import 'package:language_helper_example/resources/language_helper/language_data.dart';

void main() {
  test('', () {
    languageData.exportJson('./assets/resources');
  });
}
