import 'dart:convert';
import 'dart:io';

import 'package:language_helper/language_helper.dart';
import 'package:language_helper/src/utils/serializer.dart';
import 'package:lite_logger/lite_logger.dart';

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

/// Exports [LanguageData] to JSON files in the specified directory structure.
///
/// This internal function handles the actual export operation, creating:
/// - `[path]/codes.json` - List of all supported language codes
/// - `[path]/data/[code].json` - Translation files for each language code
///
/// The generated structure matches what [LanguageDataProvider.asset] expects
/// when loading translations.
///
/// Example output structure:
/// ```
/// assets/languages/
///   ├── codes.json          → ["en", "vi"]
///   └── data/
///       ├── en.json         → {"Hello": "Hello", ...}
///       └── vi.json         → {"Hello": "Xin chào", ...}
/// ```
void _exportJson(LanguageData data, String path) {
  final logger = LiteLogger(
    name: 'ExportJson',
    enabled: true,
    minLevel: LogLevel.debug,
  );
  logger.debug(
    () => '===========================================================',
  );
  logger.debug(() => 'Exporting Json...');
  _exportJsonCodes(data, path);
  _exportJsonLanguages(data, path);
  logger.debug(() => 'Exported Json');
  logger.debug(
    () => '===========================================================',
  );
}

/// Exports the list of supported language codes to `codes.json`.
///
/// This internal function creates `[path]/codes.json` containing an array
/// of language code strings (e.g., `["en", "vi", "es"]`).
///
/// The file is created with proper directory structure and formatted JSON
/// with 2-space indentation for readability.
void _exportJsonCodes(LanguageData data, String path) {
  final logger = LiteLogger(
    name: 'ExportJsonCodes',
    enabled: true,
    minLevel: LogLevel.debug,
  );
  logger.debug(() => 'Creating codes.json...');

  JsonEncoder encoder = const JsonEncoder.withIndent('  ');

  final desFile = File('$path/codes.json');
  desFile.createSync(recursive: true);
  final codes = data.keys.map((e) => e.code).toList();
  desFile.writeAsStringSync(encoder.convert(codes));

  logger.debug(() => 'Created codes.json');
}

/// Exports translation data for each language to individual JSON files.
///
/// This internal function creates `[path]/data/[code].json` files for each
/// language code in [data]. Each file contains the translations for that
/// specific language, including [LanguageConditions] converted to map format.
///
/// Files are created with proper directory structure and formatted JSON
/// with 2-space indentation for readability.
void _exportJsonLanguages(LanguageData data, String path) {
  final logger = LiteLogger(
    name: 'ExportJsonLanguages',
    enabled: true,
    minLevel: LogLevel.debug,
  );
  logger.debug(() => 'Creating languages json files...');

  JsonEncoder encoder = const JsonEncoder.withIndent('  ');

  final desPath = '$path/data/';
  final map = languageDataToMap(data);
  for (final MapEntry(key: String key, value: dynamic value) in map.entries) {
    final desFile = File('$desPath$key.json');
    desFile.createSync(recursive: true);
    final data = encoder.convert(value);
    desFile.writeAsStringSync(data);
  }

  logger.debug(() => 'Created languages json files');
}
