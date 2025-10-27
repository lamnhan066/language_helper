import 'dart:convert';
import 'dart:io';

import 'package:language_helper/language_helper.dart';
import 'package:language_helper/src/utils/print_debug.dart';
import 'package:language_helper/src/utils/serializer.dart';

extension ExportLanguageData on LanguageData {
  /// Export to json files for `LanguageDataProvider`. Default `path` is set to './assets/languages'.
  ///
  /// We need a little trick to run this script to get the expected result:
  /// - Create a `export_json.dart` file in your `bin` folder (the same level with the `lib`).
  /// - Add the below code:
  ///
  /// ```dart
  /// void main() {
  ///   test('', () {
  ///     languageData.exportJson('./assets/languages');
  ///   });
  /// }
  /// ```
  /// - Add the missed `import`.
  /// - Run `flutter test ./bin/export_json.dart`.
  ///
  /// Generated path:
  /// [path]
  ///  |  |- language_helper
  ///  |  |  |- codes.json
  ///  |  |  |  |- languages
  ///  |  |  |  |  |- en.json
  ///  |  |  |  |  |- vi.json
  ///  |  |  |  |  |- ...
  void exportJson([String path = './assets/languages']) {
    return _exportJson(this, path);
  }
}

extension ExportLazyLanguageData on LazyLanguageData {
  /// Export to json files for `LanguageDataProvider`. Default `path` is set to './assets/languages'.
  ///
  /// We need a little trick to run this script to get the expected result:
  /// - Create a `export_json.dart` file in your `bin` folder (the same level with the `lib`).
  /// - Add the below code:
  ///
  /// ```dart
  /// void main() {
  ///   test('', () {
  ///     languageData.exportJson('./assets/languages');
  ///   });
  /// }
  /// ```
  /// - Add the missed `import`.
  /// - Run `flutter test ./bin/export_json.dart`.
  ///
  /// Generated path:
  /// [path]
  ///  |  |- language_helper
  ///  |  |  |- codes.json
  ///  |  |  |  |- languages
  ///  |  |  |  |  |- en.json
  ///  |  |  |  |  |- vi.json
  ///  |  |  |  |  |- ...
  void exportJson([String path = './assets/languages']) {
    return _exportJson(map((k, v) => MapEntry(k, v())), path);
  }
}

/// Generated path:
/// `path`
///  |  |- codes.json
///  |  |  |- languages
///  |  |  |  |- en.json
///  |  |  |  |- vi.json
void _exportJson(LanguageData data, String path) {
  printDebug(
    () => '===========================================================',
  );
  printDebug(() => 'Exporting Json...');
  _exportJsonCodes(data, path);
  _exportJsonLanguages(data, path);
  printDebug(() => 'Exported Json');
  printDebug(
    () => '===========================================================',
  );
}

void _exportJsonCodes(LanguageData data, String path) {
  printDebug(() => 'Creating codes.json...');

  JsonEncoder encoder = const JsonEncoder.withIndent('  ');

  final desFile = File('$path/codes.json');
  desFile.createSync(recursive: true);
  final codes = data.keys.map((e) => e.code).toList();
  desFile.writeAsStringSync(encoder.convert(codes));

  printDebug(() => 'Created codes.json');
}

void _exportJsonLanguages(LanguageData data, String path) {
  printDebug(() => 'Creating languages json files...');

  JsonEncoder encoder = const JsonEncoder.withIndent('  ');

  final desPath = '$path/data/';
  final map = languageDataToMap(data);
  for (final MapEntry(key: String key, value: dynamic value) in map.entries) {
    final desFile = File('$desPath$key.json');
    desFile.createSync(recursive: true);
    final data = encoder.convert(value);
    desFile.writeAsStringSync(data);
  }

  printDebug(() => 'Created languages json files');
}
