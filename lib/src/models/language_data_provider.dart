import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:language_helper/language_helper.dart';
import 'package:language_helper/src/utils/utils.dart';
import 'package:lite_logger/lite_logger.dart';

/// Provides translation data from various sources (Dart maps, JSON assets, network).
///
/// [LanguageDataProvider] is an abstraction that allows [LanguageHelper] to load
/// translation data from different sources:
/// - [LanguageDataProvider.data] - Direct Dart map data
/// - [LanguageDataProvider.lazyData] - Lazy-loaded Dart map data
/// - [LanguageDataProvider.asset] - JSON files from Flutter assets
/// - [LanguageDataProvider.network] - JSON files from HTTP/HTTPS URLs
/// - [LanguageDataProvider.empty] - Empty provider (for testing or placeholder)
///
/// Each provider exposes:
/// - [getData] - Function to get translations for a specific language code
/// - [getSupportedCodes] - Function to get all supported language codes
///
/// Example:
/// ```dart
/// // From Dart map
/// final dataProvider = LanguageDataProvider.data(myLanguageData);
///
/// // From assets
/// final assetProvider = LanguageDataProvider.asset('assets/languages');
///
/// // From network
/// final networkProvider = LanguageDataProvider.network('https://api.example.com/languages');
///
/// // Use in LanguageHelper
/// await languageHelper.initial(data: [dataProvider, assetProvider]);
/// ```
class LanguageDataProvider {
  /// Loads an asset file from Flutter's asset bundle.
  ///
  /// This internal method loads JSON files from the asset bundle and logs
  /// debug messages if the asset is not found.
  static Future<String> _loadAsset(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (_) {
      LiteLogger(
        name: 'LoadAsset',
        enabled: true,
        minLevel: LogLevel.debug,
        usePrint: false,
      ).warning(() => 'The $path does not exist in the assets');
    }
    return Future.value('');
  }

  /// Function to retrieve translation data for a specific language code.
  ///
  /// Returns a [FutureOr] that resolves to [LanguageData] containing translations
  /// for the requested [code]. Returns an empty map if no data is available for
  /// the specified code.
  ///
  /// This function is provided by the factory constructors and varies based on
  /// the data source (asset, network, data, etc.).
  FutureOr<LanguageData> Function(LanguageCodes code) get getData =>
      _getData ?? (code) => Future.value({});
  final FutureOr<LanguageData> Function(LanguageCodes code)? _getData;

  /// Function to retrieve all supported language codes.
  ///
  /// Returns a [FutureOr] that resolves to a [Set] of [LanguageCodes] that are
  /// available in this provider. Returns an empty set if the provider has no data.
  ///
  /// This is used by [LanguageHelper] to determine which languages are available
  /// for translation.
  FutureOr<Set<LanguageCodes>> Function() get getSupportedCodes =>
      _getSupportedCodes ?? () => Future.value({});
  final FutureOr<Set<LanguageCodes>> Function()? _getSupportedCodes;

  /// Whether this provider is empty (has no data source).
  ///
  /// Returns `true` if both [getData] and [getSupportedCodes] are null, indicating
  /// this is an empty provider created with [LanguageDataProvider.empty].
  bool get isEmpty => _getData == null || _getSupportedCodes == null;

  /// Internal constructor for creating a provider with custom getter functions.
  const LanguageDataProvider._(this._getData, this._getSupportedCodes);

  /// Creates an empty provider with no data source.
  ///
  /// This is useful for:
  /// - Placeholder providers during initialization
  /// - Testing scenarios where you need a provider but no data
  /// - Conditional provider creation
  ///
  /// An empty provider will return empty maps/sets when [getData] or [getSupportedCodes]
  /// are called, and [isEmpty] will return `true`.
  ///
  /// Example:
  /// ```dart
  /// final emptyProvider = LanguageDataProvider.empty();
  /// print(emptyProvider.isEmpty); // true
  /// ```
  const LanguageDataProvider.empty() : this._(null, null);

  /// Creates a provider that loads translations from Flutter asset bundle.
  ///
  /// The [parentPath] is the directory path containing `codes.json` and a `data/`
  /// subdirectory with language-specific JSON files. It should NOT include `codes.json`.
  ///
  /// **Expected directory structure:**
  /// ```
  /// [parentPath]/
  ///   ├── codes.json          (List of language codes: ["en", "vi", ...])
  ///   └── data/
  ///       ├── en.json         (English translations)
  ///       ├── vi.json         (Vietnamese translations)
  ///       └── ...
  /// ```
  ///
  /// **Important:** Add the assets to your `pubspec.yaml`:
  /// ```yaml
  /// flutter:
  ///   assets:
  ///     - assets/languages/
  ///     - assets/languages/data/
  /// ```
  ///
  /// Example:
  /// ```dart
  /// final provider = LanguageDataProvider.asset('assets/languages');
  /// // Will load from: assets/languages/codes.json and assets/languages/data/*.json
  /// ```
  factory LanguageDataProvider.asset(String parentPath) {
    return LanguageDataProvider._(
      (code) async {
        String path = Utils.removeLastSlash(parentPath);
        final uri = Uri.parse('$path/data/${code.code}.json');
        String json = await _loadAsset(uri.path);
        if (json.isNotEmpty) {
          return {code: LanguageDataSerializer.valuesFromJson(json)};
        }
        return {};
      },
      () async {
        String path = Utils.removeLastSlash(parentPath);
        final uri = Uri.parse('$path/codes.json');
        final json = await _loadAsset(uri.path);
        if (json.isNotEmpty) {
          final decoded = jsonDecode(json).cast<String>() as List<String>;
          final set = decoded.map((e) => LanguageCodes.fromCode(e)).toSet();
          return Future.value(set);
        }
        return {};
      },
    );
  }

  /// Creates a provider that loads translations from a network URL.
  ///
  /// The [parentUrl] is the base URL containing `codes.json` and a `data/` subdirectory
  /// with language-specific JSON files. It should NOT include `codes.json`.
  ///
  /// **Expected URL structure:**
  /// ```
  /// [parentUrl]/codes.json           (List of language codes)
  /// [parentUrl]/data/en.json         (English translations)
  /// [parentUrl]/data/vi.json         (Vietnamese translations)
  /// ```
  ///
  /// **Parameters:**
  /// - [client] - Optional HTTP client for custom network configuration (timeouts, interceptors, etc.)
  /// - [headers] - Optional HTTP headers to send with requests (e.g., API keys, authentication)
  ///
  /// **Error handling:** If a network request fails or returns non-200 status, the provider
  /// will return empty data for that language code without throwing exceptions.
  ///
  /// Example:
  /// ```dart
  /// // Basic network provider
  /// final provider = LanguageDataProvider.network('https://api.example.com/languages');
  ///
  /// // With custom headers
  /// final provider = LanguageDataProvider.network(
  ///   'https://api.example.com/languages',
  ///   headers: {'Authorization': 'Bearer token'},
  /// );
  ///
  /// // With custom HTTP client
  /// final client = http.Client();
  /// final provider = LanguageDataProvider.network(
  ///   'https://api.example.com/languages',
  ///   client: client,
  /// );
  /// ```
  factory LanguageDataProvider.network(
    String parentUrl, {
    Client? client,
    Map<String, String>? headers,
  }) {
    return LanguageDataProvider._(
      (code) async {
        String path = Utils.removeLastSlash(parentUrl);
        final uri = Uri.parse('$path/data/${code.code}.json');
        String json = await Utils.getUrl(uri, client: client, headers: headers);
        if (json.isNotEmpty) {
          return {code: LanguageDataSerializer.valuesFromJson(json)};
        }
        return {};
      },
      () async {
        String path = Utils.removeLastSlash(parentUrl);
        final uri = Uri.parse('$path/codes.json');
        final json = await Utils.getUrl(uri, client: client, headers: headers);
        if (json.isNotEmpty) {
          final decoded = jsonDecode(json).cast<String>() as List<String>;
          final set = decoded.map((e) => LanguageCodes.fromCode(e)).toSet();
          return Future.value(set);
        }
        return {};
      },
    );
  }

  /// Creates a provider from a [LanguageData] map (synchronous data).
  ///
  /// This factory is used when you have translation data already loaded in memory
  /// as a Dart map. The data is returned immediately without async operations.
  ///
  /// This is the most efficient provider type for data that's already available
  /// in your application code.
  ///
  /// Example:
  /// ```dart
  /// final languageData = {
  ///   LanguageCodes.en: {'Hello': 'Hello', 'Goodbye': 'Goodbye'},
  ///   LanguageCodes.vi: {'Hello': 'Xin chào', 'Goodbye': 'Tạm biệt'},
  /// };
  ///
  /// final provider = LanguageDataProvider.data(languageData);
  /// await languageHelper.initial(data: [provider]);
  /// ```
  factory LanguageDataProvider.data(LanguageData data) {
    return LanguageDataProvider._(
      (code) {
        return data;
      },
      () {
        return data.keys.toSet();
      },
    );
  }

  /// Creates a provider from [LazyLanguageData] (lazy-loaded data).
  ///
  /// This factory is used when you want to defer loading translation data until
  /// it's actually needed. The functions in [LazyLanguageData] are called only
  /// when translations are requested for a specific language code.
  ///
  /// This is useful for:
  /// - Large translation datasets that shouldn't all be loaded at once
  /// - Conditional loading based on app state or user preferences
  /// - Performance optimization by loading translations on-demand
  ///
  /// Example:
  /// ```dart
  /// final lazyData = {
  ///   LanguageCodes.en: () => loadEnglishTranslations(), // Function called when needed
  ///   LanguageCodes.vi: () => loadVietnameseTranslations(),
  /// };
  ///
  /// final provider = LanguageDataProvider.lazyData(lazyData);
  /// await languageHelper.initial(data: [provider]);
  /// // English translations loaded only when LanguageCodes.en is used
  /// ```
  factory LanguageDataProvider.lazyData(LazyLanguageData data) {
    return LanguageDataProvider._(
      (code) {
        return {code: data[code]!()};
      },
      () {
        return data.keys.toSet();
      },
    );
  }
}
