import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:language_helper/language_helper.dart';
import 'package:language_helper/src/utils/utils.dart';
import 'package:lite_logger/lite_logger.dart';

/// Provides translation data from various sources (Dart maps, JSON assets,
/// network).
///
/// Provider types:
/// - [data] - Direct Dart map (synchronous, fastest)
/// - [lazyData] - Lazy-loaded Dart map (on-demand)
/// - [asset] - JSON from Flutter assets (async, bundled)
/// - [network] - JSON from HTTP/HTTPS URLs (async, remote)
/// - [empty] - Empty provider (testing/placeholder)
///
/// Providers are processed in order. If [override] is true, translations
/// overwrite existing keys; if false, only new keys are added. Performance:
/// [data] > [lazyData] > [asset] > [network].
///
/// Example:
/// ```dart
/// await languageHelper.initial(data: [
///   LanguageDataProvider.data(myLanguageData),
///   LanguageDataProvider.asset('assets/languages'),
///   LanguageDataProvider.network('https://api.example.com/languages'),
/// ]);
/// ```
class LanguageDataProvider {
  /// Loads an asset file from Flutter's asset bundle. Returns empty string if not found.
  /// Internal method used by [asset] providers.
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

  /// Retrieves translation data for a specific language code. Returns empty
  /// map if unavailable. For [data] providers, returns the entire
  /// [LanguageData] map; others return only the requested code.
  FutureOr<LanguageData> Function(LanguageCodes code) get getData =>
      _getData ?? (code) => Future.value({});
  final FutureOr<LanguageData> Function(LanguageCodes code)? _getData;

  /// Retrieves all supported language codes. Returns empty set if provider has
  /// no data. May perform I/O for asset/network providers. Result is cached
  /// by [LanguageHelper] after first call.
  Future<Set<LanguageCodes>> Function() get getSupportedCodes =>
      _getSupportedCodes ?? () async => {};
  final Future<Set<LanguageCodes>> Function()? _getSupportedCodes;

  /// Whether this provider overwrites existing translations with matching keys.
  /// If true (default), overwrites; if false, only adds new keys. Order matters.
  final bool override;

  /// Returns true if this is an empty provider (no data source). Useful for
  /// testing or placeholders.
  bool get isEmpty => _getData == null || _getSupportedCodes == null;

  /// Internal constructor for creating a provider with custom getter functions.
  const LanguageDataProvider._(
    this._getData,
    this._getSupportedCodes,
    this.override,
  );

  /// Creates an empty provider with no data source. Returns empty maps/sets.
  /// Useful for placeholders and testing.
  const LanguageDataProvider.empty() : this._(null, null, false);

  /// Creates a provider that loads translations from Flutter asset bundle.
  ///
  /// Expected structure: `[parentPath]/codes.json` and
  /// `[parentPath]/data/[code].json`. Add assets to `pubspec.yaml`. Missing
  /// files return empty data without exceptions. Asset loading is async but
  /// fast since files are bundled with the app.
  ///
  /// Example:
  /// ```dart
  /// final provider = LanguageDataProvider.asset('assets/languages');
  /// await languageHelper.initial(data: [provider]);
  /// ```
  factory LanguageDataProvider.asset(
    String parentPath, {
    bool override = true,
  }) {
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
      override,
    );
  }

  /// Creates a provider that loads translations from a network URL.
  ///
  /// Expected structure: `[parentUrl]/codes.json` and
  /// `[parentUrl]/data/[code].json`. Data loads on-demand when a language is
  /// first accessed. Failed requests return empty data. Use [client] for
  /// custom timeouts/retries and [headers] for authentication.
  ///
  /// Example:
  /// ```dart
  /// final provider = LanguageDataProvider.network(
  ///   'https://api.example.com/languages',
  ///   headers: {'Authorization': 'Bearer token'},
  /// );
  /// await languageHelper.initial(data: [provider]);
  /// ```
  factory LanguageDataProvider.network(
    String parentUrl, {
    Client? client,
    Map<String, String>? headers,
    bool override = true,
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
      override,
    );
  }

  /// Creates a provider from a [LanguageData] map. Fastest provider type
  /// (synchronous, no I/O). Use for hardcoded translations, compile-time
  /// generated data, or pre-loaded maps. When [getData] is called, returns
  /// the entire [data] map (not just the requested language).
  ///
  /// Example:
  /// ```dart
  /// final languageData = {
  ///   LanguageCodes.en: {'Hello': 'Hello', 'Goodbye': 'Goodbye'},
  ///   LanguageCodes.vi: {'Hello': 'Xin chào', 'Goodbye': 'Tạm biệt'},
  /// };
  /// final provider = LanguageDataProvider.data(languageData);
  /// await languageHelper.initial(data: [provider]);
  /// ```
  factory LanguageDataProvider.data(LanguageData data, {bool override = true}) {
    return LanguageDataProvider._(
      (code) {
        return data;
      },
      () {
        return Future.value(data.keys.toSet());
      },
      override,
    );
  }

  /// Creates a provider from [LazyLanguageData] (lazy-loaded data). Functions
  /// are called synchronously when translations are requested for a specific
  /// language code. Useful for large datasets, conditional loading, or
  /// memory-constrained environments. Keep functions lightweight; results
  /// are cached by [LanguageHelper] internally.
  ///
  /// Example:
  /// ```dart
  /// final lazyData = {
  ///   LanguageCodes.en: () => {'Hello': 'Hello', 'Goodbye': 'Goodbye'},
  ///   LanguageCodes.vi: () => {'Hello': 'Xin chào', 'Goodbye': 'Tạm biệt'},
  /// };
  /// final provider = LanguageDataProvider.lazyData(lazyData);
  /// await languageHelper.initial(data: [provider]);
  /// ```
  factory LanguageDataProvider.lazyData(
    LazyLanguageData data, {
    bool override = true,
  }) {
    return LanguageDataProvider._(
      (code) {
        return {code: data[code]!()};
      },
      () {
        return Future.value(data.keys.toSet());
      },
      override,
    );
  }
}
