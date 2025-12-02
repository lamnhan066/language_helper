import 'dart:convert';
import 'dart:io';

import 'package:language_helper/language_helper.dart';
import 'package:language_helper/src/utils/serializer.dart';
import 'package:lite_logger/lite_logger.dart';

/// Extension on [LanguageData] to export to JSON files.
extension ExportLanguageData on LanguageData {
  /// Export to json files for `LanguageDataProvider`. Default `path` is set
  /// to './assets/languages'.
  ///
  /// We need a little trick to run this script to get the expected result:
  /// - Create a `export_json.dart` file in your `bin` folder (the same level
  ///   with the `lib`).
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

/// Extension on [LazyLanguageData] to export to JSON files.
extension ExportLazyLanguageData on LazyLanguageData {
  /// Exports to JSON files for [LanguageDataProvider]. Default path:
  /// './assets/languages'. Creates `codes.json` and `data/[code].json` files.
  /// Run via `flutter test` script in `bin` folder.
  void exportJson([String path = './assets/languages']) {
    return _exportJson(map((k, v) => MapEntry(k, v())), path);
  }
}

/// Exports [LanguageData] to JSON files. Creates `codes.json` and
/// `data/[code].json` files matching [LanguageDataProvider.asset] structure.
void _exportJson(LanguageData data, String path) {
  final logger =
      const LiteLogger(
          name: 'ExportJson',
          minLevel: LogLevel.debug,
        )
        ..step(
          () => '===========================================================',
        )
        ..step(() => 'Exporting Json...');
  _exportJsonCodes(data, path);
  _exportJsonLanguages(data, path);
  logger
    ..step(() => 'Exported Json')
    ..step(
      () => '===========================================================',
    );
}

/// Exports language codes to `codes.json`. Creates array of language code
/// strings with formatted JSON.
void _exportJsonCodes(LanguageData data, String path) {
  final logger = const LiteLogger(
    name: 'ExportJsonCodes',
    minLevel: LogLevel.debug,
  )..info(() => 'Creating codes.json...');

  const encoder = JsonEncoder.withIndent('  ');

  final desFile = File('$path/codes.json')..createSync(recursive: true);
  final codes = data.keys.map((e) => e.code).toList();
  desFile.writeAsStringSync(encoder.convert(codes));

  logger.step(() => 'Created codes.json');
}

/// Exports translation data for each language to `data/[code].json` files.
/// Converts [LanguageConditions] to map format.
void _exportJsonLanguages(LanguageData data, String path) {
  final logger = const LiteLogger(
    name: 'ExportJsonLanguages',
    minLevel: LogLevel.debug,
  )..info(() => 'Creating languages json files...');

  const encoder = JsonEncoder.withIndent('  ');

  final desPath = '$path/data/';
  final map = languageDataToMap(data);
  for (final MapEntry(key: String key, value: dynamic value) in map.entries) {
    final desFile = File('$desPath$key.json')..createSync(recursive: true);
    final data = encoder.convert(value);
    desFile.writeAsStringSync(data);
  }

  logger.step(() => 'Created languages json files');
}
