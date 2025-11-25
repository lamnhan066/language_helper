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
/// - [LanguageDataProvider.data] - Direct Dart map data (synchronous, fastest)
/// - [LanguageDataProvider.lazyData] - Lazy-loaded Dart map data (on-demand evaluation)
/// - [LanguageDataProvider.asset] - JSON files from Flutter assets (async, bundled with app)
/// - [LanguageDataProvider.network] - JSON files from HTTP/HTTPS URLs (async, remote)
/// - [LanguageDataProvider.empty] - Empty provider (for testing or placeholder)
///
/// Each provider exposes:
/// - [getData] - Function to get translations for a specific language code
/// - [getSupportedCodes] - Function to get all supported language codes
/// - [override] - Whether this provider's translations override existing ones
///
/// **Provider Priority:**
/// When multiple providers contain the same translation key, the order matters:
/// - Providers are processed in the order they're added to [LanguageHelper]
/// - If a provider has [override] set to `true`, it will overwrite existing translations
/// - If [override] is `false`, only new keys are added (existing keys are preserved)
///
/// **Performance Considerations:**
/// - [data]: Fastest (no I/O, synchronous)
/// - [lazyData]: Fast (synchronous function calls, but data loaded on-demand)
/// - [asset]: Medium (async I/O, but bundled with app)
/// - [network]: Slowest (async network requests, depends on connection)
///
/// Example:
/// ```dart
/// // From Dart map (fastest, for static translations)
/// final dataProvider = LanguageDataProvider.data(myLanguageData);
///
/// // From assets (for bundled translations)
/// final assetProvider = LanguageDataProvider.asset('assets/languages');
///
/// // From network (for remote translations)
/// final networkProvider = LanguageDataProvider.network('https://api.example.com/languages');
///
/// // Use multiple providers together
/// await languageHelper.initial(data: [
///   dataProvider,      // Base translations (override: true by default)
///   assetProvider,     // Additional translations (override: true by default)
///   networkProvider,   // Remote overrides (override: true by default)
/// ]);
/// ```
class LanguageDataProvider {
  /// Loads an asset file from Flutter's asset bundle.
  ///
  /// This internal method loads JSON files from the asset bundle using
  /// [rootBundle.loadString]. If the asset is not found, it logs a warning
  /// (if debug logging is enabled) and returns an empty string instead of
  /// throwing an exception.
  ///
  /// **Error handling:** This method catches all exceptions and returns an
  /// empty string, allowing the provider to gracefully handle missing assets
  /// without crashing the app.
  ///
  /// **Note:** This is an internal method used by [asset] providers. It should
  /// not be called directly by users of this class.
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
  /// Returns a [FutureOr] that resolves to [LanguageData] (a map of [LanguageCodes]
  /// to translation maps) containing translations for the requested [code].
  ///
  /// The returned map will contain the requested [code] as a key, with its value
  /// being a map of translation keys to their translated values. Returns an empty
  /// map if no data is available for the specified code.
  ///
  /// **Return Structure:**
  /// ```dart
  /// {
  ///   LanguageCodes.en: {
  ///     'Hello': 'Hello',
  ///     'Goodbye': 'Goodbye',
  ///   }
  /// }
  /// ```
  ///
  /// This function is provided by the factory constructors and varies based on
  /// the data source (asset, network, data, etc.). The implementation handles
  /// loading, parsing, and error handling appropriate to each source type.
  ///
  /// **Note:** For providers created with [data], the entire [LanguageData] map
  /// is returned (which may contain multiple language codes). For other provider
  /// types, only the requested language code is included in the returned map.
  FutureOr<LanguageData> Function(LanguageCodes code) get getData =>
      _getData ?? (code) => Future.value({});
  final FutureOr<LanguageData> Function(LanguageCodes code)? _getData;

  /// Function to retrieve all supported language codes.
  ///
  /// Returns a [Future] that resolves to a [Set] of [LanguageCodes] that are
  /// available in this provider. Returns an empty set if the provider has no data.
  ///
  /// This is used by [LanguageHelper] to determine which languages are available
  /// for translation. The returned set is used to:
  /// - Validate language code changes
  /// - Display available languages in UI
  /// - Initialize the helper with supported locales
  ///
  /// **Implementation details:**
  /// - For [asset] providers: Loads and parses `codes.json` from the asset bundle
  /// - For [network] providers: Fetches and parses `codes.json` from the network URL
  /// - For [data] providers: Returns the keys of the [LanguageData] map
  /// - For [lazyData] providers: Returns the keys of the [LazyLanguageData] map
  /// - For [empty] providers: Returns an empty set
  ///
  /// **Note:** This method may perform I/O operations (for asset/network providers),
  /// so it returns a [Future]. The result is typically cached by [LanguageHelper]
  /// after the first call.
  ///
  /// Example:
  /// ```dart
  /// final provider = LanguageDataProvider.asset('assets/languages');
  /// final codes = await provider.getSupportedCodes();
  /// print(codes); // {LanguageCodes.en, LanguageCodes.vi, ...}
  /// ```
  Future<Set<LanguageCodes>> Function() get getSupportedCodes =>
      _getSupportedCodes ?? () async => {};
  final Future<Set<LanguageCodes>> Function()? _getSupportedCodes;

  /// Whether this provider overrides existing translations with the same keys.
  ///
  /// When multiple providers contain translations for the same language code:
  /// - If `true` (default for most providers): Translations from this provider
  ///   will overwrite existing translations with matching keys from providers
  ///   processed earlier.
  /// - If `false`: Only new translation keys are added; existing keys from
  ///   earlier providers are preserved.
  ///
  /// **Example:**
  /// ```dart
  /// // Provider 1: Base translations
  /// final base = LanguageDataProvider.data({
  ///   LanguageCodes.en: {'Hello': 'Hello', 'Goodbye': 'Goodbye'},
  /// }, override: false);
  ///
  /// // Provider 2: Override translations
  /// final overrides = LanguageDataProvider.data({
  ///   LanguageCodes.en: {'Hello': 'Hi', 'Welcome': 'Welcome'},
  /// }, override: true);
  ///
  /// // Result: {'Hello': 'Hi', 'Goodbye': 'Goodbye', 'Welcome': 'Welcome'}
  /// // 'Hello' is overwritten, 'Goodbye' is preserved, 'Welcome' is added
  /// ```
  ///
  /// **Note:** The order of providers matters. Providers are processed in the
  /// order they're added to [LanguageHelper]. Later providers with `override: true`
  /// will overwrite earlier providers' translations.
  final bool override;

  /// Whether this provider is empty (has no data source).
  ///
  /// Returns `true` if both [getData] and [getSupportedCodes] are null, indicating
  /// this is an empty provider created with [LanguageDataProvider.empty].
  ///
  /// Empty providers return empty maps/sets when [getData] or [getSupportedCodes]
  /// are called, and are useful for testing or as placeholders during initialization.
  ///
  /// Example:
  /// ```dart
  /// final provider = LanguageDataProvider.empty();
  /// print(provider.isEmpty); // true
  /// final data = await provider.getData(LanguageCodes.en);
  /// print(data); // {}
  /// ```
  bool get isEmpty => _getData == null || _getSupportedCodes == null;

  /// Internal constructor for creating a provider with custom getter functions.
  const LanguageDataProvider._(
    this._getData,
    this._getSupportedCodes,
    this.override,
  );

  /// Creates an empty provider with no data source.
  ///
  /// This is useful for:
  /// - Placeholder providers during initialization when data isn't ready yet
  /// - Testing scenarios where you need a provider instance but no actual data
  /// - Conditional provider creation (e.g., when data may or may not be available)
  /// - Default values in optional parameters
  ///
  /// An empty provider will return empty maps/sets when [getData] or [getSupportedCodes]
  /// are called, and [isEmpty] will return `true`. The [override] property is set to
  /// `false` for empty providers.
  ///
  /// **Note:** Empty providers don't contribute any translations to [LanguageHelper],
  /// so they're effectively no-ops. They're primarily useful for code structure
  /// and testing purposes.
  ///
  /// Example:
  /// ```dart
  /// // Basic usage
  /// final emptyProvider = LanguageDataProvider.empty();
  /// print(emptyProvider.isEmpty); // true
  /// final data = await emptyProvider.getData(LanguageCodes.en);
  /// print(data); // {}
  ///
  /// // Conditional provider creation
  /// final provider = shouldLoadData
  ///   ? LanguageDataProvider.data(myData)
  ///   : LanguageDataProvider.empty();
  ///
  /// // Use in LanguageHelper (empty provider will be ignored)
  /// await languageHelper.initial(data: [provider]);
  /// ```
  const LanguageDataProvider.empty() : this._(null, null, false);

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
  /// **JSON Format:**
  /// Each language JSON file should contain a map of translation keys to values:
  /// ```json
  /// {
  ///   "Hello": "Hello",
  ///   "Goodbye": "Goodbye",
  ///   "Count": {
  ///     "param": "count",
  ///     "conditions": {
  ///       "1": "one item",
  ///       "_": "@{count} items"
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// **Parameters:**
  /// - [parentPath] - The base path to the language assets directory (e.g., `'assets/languages'`)
  /// - [override] - If `true`, translations from this provider will overwrite
  ///   existing translations with the same keys. Defaults to `true`.
  ///
  /// **Error handling:** If an asset file is missing or invalid, the provider
  /// will return empty data for that language code without throwing exceptions.
  /// A warning will be logged (if debug logging is enabled) when an asset is not found.
  ///
  /// **Performance:** Asset loading is asynchronous but fast since files are bundled
  /// with the app. Consider using [data] or [lazyData] for even better performance
  /// if you can pre-process your translations.
  ///
  /// Example:
  /// ```dart
  /// // Basic usage
  /// final provider = LanguageDataProvider.asset('assets/languages');
  /// // Will load from: assets/languages/codes.json and assets/languages/data/*.json
  ///
  /// // With override disabled (preserve existing translations)
  /// final preserveProvider = LanguageDataProvider.asset(
  ///   'assets/languages',
  ///   override: false, // Only adds new keys, preserves existing ones
  /// );
  ///
  /// // Use in LanguageHelper
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
  /// The [parentUrl] is the base URL containing `codes.json` and a `data/` subdirectory
  /// with language-specific JSON files. It should NOT include `codes.json`.
  ///
  /// **Expected URL structure:**
  /// ```
  /// [parentUrl]/codes.json           (List of language codes: ["en", "vi", ...])
  /// [parentUrl]/data/en.json         (English translations)
  /// [parentUrl]/data/vi.json         (Vietnamese translations)
  /// ```
  ///
  /// **JSON Format:**
  /// The JSON files should follow the same format as [asset] provider:
  /// ```json
  /// {
  ///   "Hello": "Hello",
  ///   "Goodbye": "Goodbye",
  ///   "Count": {
  ///     "param": "count",
  ///     "conditions": {
  ///       "1": "one item",
  ///       "_": "@{count} items"
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// **Parameters:**
  /// - [parentUrl] - The base URL for language files (must be a valid HTTP/HTTPS URL)
  /// - [client] - Optional HTTP client for custom network configuration (timeouts, interceptors, etc.)
  ///   If not provided, a default client is used. Useful for implementing retry logic,
  ///   custom timeouts, or request/response interceptors.
  /// - [headers] - Optional HTTP headers to send with requests (e.g., API keys, authentication).
  ///   These headers are sent with both the `codes.json` request and all language data requests.
  /// - [override] - If `true`, translations from this provider will overwrite
  ///   existing translations with the same keys. Defaults to `true`.
  ///
  /// **Error handling:** If a network request fails (network error, timeout, non-200 status),
  /// the provider will return empty data for that language code without throwing exceptions.
  /// This allows your app to continue functioning even if some translations fail to load.
  /// Consider implementing retry logic via a custom [client] for production apps.
  ///
  /// **Performance:** Network providers load data on-demand when a language is first accessed.
  /// Each language file is fetched separately, so switching languages may cause network delays.
  /// Consider implementing caching strategies for production apps to improve performance and
  /// reduce network usage.
  ///
  /// **Security:** When using authentication headers, be careful not to expose sensitive
  /// credentials in client-side code. Consider using secure storage or environment variables.
  ///
  /// Example:
  /// ```dart
  /// // Basic network provider
  /// final provider = LanguageDataProvider.network('https://api.example.com/languages');
  ///
  /// // With custom headers for authentication
  /// final authenticatedProvider = LanguageDataProvider.network(
  ///   'https://api.example.com/languages',
  ///   headers: {
  ///     'Authorization': 'Bearer token',
  ///     'X-API-Key': 'your-api-key',
  ///   },
  /// );
  ///
  /// // With custom HTTP client (for timeouts, retries, etc.)
  /// final client = http.Client();
  /// client.timeout = const Duration(seconds: 10);
  /// final customClientProvider = LanguageDataProvider.network(
  ///   'https://api.example.com/languages',
  ///   client: client,
  ///   override: true, // Overwrites existing translations
  /// );
  ///
  /// // Use in LanguageHelper
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

  /// Creates a provider from a [LanguageData] map (synchronous data).
  ///
  /// This factory is used when you have translation data already loaded in memory
  /// as a Dart map. The data is returned immediately without async operations.
  ///
  /// This is the most efficient provider type for data that's already available
  /// in your application code, such as:
  /// - Hardcoded translations
  /// - Translations generated at compile time (e.g., using code generation)
  /// - Translations loaded from other sources and converted to maps
  /// - Translations parsed from JSON at app startup
  ///
  /// **Parameters:**
  /// - [data] - A map of [LanguageCodes] to translation maps. Each translation map
  ///   contains string keys mapped to translation values (strings or [LanguageConditions]).
  /// - [override] - If `true`, translations from this provider will overwrite
  ///   existing translations with the same keys. Defaults to `true`.
  ///
  /// **Performance:** This is the fastest provider type since it requires no
  /// I/O operations and is completely synchronous. Use this for static or
  /// pre-loaded translation data when performance is critical.
  ///
  /// **Note:** When [getData] is called, the entire [data] map is returned
  /// (not just the requested language code). This is different from other
  /// provider types that return only the requested language.
  ///
  /// Example:
  /// ```dart
  /// // Basic usage with simple translations
  /// final languageData = {
  ///   LanguageCodes.en: {
  ///     'Hello': 'Hello',
  ///     'Goodbye': 'Goodbye',
  ///   },
  ///   LanguageCodes.vi: {
  ///     'Hello': 'Xin chào',
  ///     'Goodbye': 'Tạm biệt',
  ///   },
  /// };
  ///
  /// final provider = LanguageDataProvider.data(languageData);
  /// await languageHelper.initial(data: [provider]);
  ///
  /// // With LanguageConditions for plural forms
  /// final dataWithPlurals = {
  ///   LanguageCodes.en: {
  ///     'Count': LanguageConditions(
  ///       param: 'count',
  ///       conditions: {
  ///         '1': 'one item',
  ///         '_': '@{count} items',
  ///       },
  ///     ),
  ///   },
  /// };
  ///
  /// // With override disabled (preserve existing translations)
  /// final preserveProvider = LanguageDataProvider.data(
  ///   additionalData,
  ///   override: false, // Only adds new keys, preserves existing ones
  /// );
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
  /// - Memory-constrained environments where loading all languages upfront is expensive
  /// - Dynamic translations that depend on runtime conditions
  ///
  /// **Parameters:**
  /// - [data] - A map of [LanguageCodes] to functions that return translation maps.
  ///   Each function should return a `Map<String, dynamic>` containing translation
  ///   keys mapped to their values (strings or [LanguageConditions]).
  /// - [override] - If `true`, translations from this provider will overwrite
  ///   existing translations with the same keys. Defaults to `true`.
  ///
  /// **Performance:** Functions are called synchronously when data is requested.
  /// Keep the functions lightweight for best performance. If your functions perform
  /// heavy computations or I/O operations, consider pre-loading the data and using
  /// the [data] provider instead.
  ///
  /// **Note:** Each function is called once per language code when that language
  /// is first accessed. The result is not cached by the provider itself, but
  /// [LanguageHelper] caches the loaded translations internally.
  ///
  /// **Best Practices:**
  /// - Use lazy loading when you have many languages but users typically use only a few
  /// - Keep functions pure and deterministic when possible
  /// - Avoid side effects in the functions (they may be called multiple times)
  /// - Consider using [data] provider if all languages are needed at startup
  ///
  /// Example:
  /// ```dart
  /// // Lazy loading with simple functions
  /// final lazyData = {
  ///   LanguageCodes.en: () => {
  ///     'Hello': 'Hello',
  ///     'Goodbye': 'Goodbye',
  ///   },
  ///   LanguageCodes.vi: () => {
  ///     'Hello': 'Xin chào',
  ///     'Goodbye': 'Tạm biệt',
  ///   },
  /// };
  ///
  /// final provider = LanguageDataProvider.lazyData(lazyData);
  /// await languageHelper.initial(data: [provider]);
  /// // English translations loaded only when LanguageCodes.en is first used
  ///
  /// // With conditional loading based on app state
  /// final conditionalLazyData = {
  ///   LanguageCodes.en: () => isPremiumUser
  ///     ? loadPremiumEnglishTranslations()  // Load premium translations
  ///     : loadBasicEnglishTranslations(),    // Load basic translations
  /// };
  ///
  /// // With complex loading logic
  /// final complexLazyData = {
  ///   LanguageCodes.en: () {
  ///     final base = loadBaseTranslations();
  ///     final custom = loadCustomTranslations();
  ///     return {...base, ...custom};  // Merge translations
  ///   },
  /// };
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
