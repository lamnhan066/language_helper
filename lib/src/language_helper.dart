import 'dart:async';

import 'package:flutter/material.dart';
import 'package:language_code/language_code.dart';
import 'package:lite_logger/lite_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../language_helper.dart';
import 'mixins/update_language.dart';

part 'extensions/language_helper_extension.dart';
part 'widgets/language_builder.dart';

/// Make it easier for you to control multiple languages in your app
class LanguageHelper {
  // Get the LanguageHelper instance
  static final LanguageHelper instance = LanguageHelper('LanguageHelper');

  /// Stack of [LanguageHelper] instances, with the most recent one on top.
  ///
  /// This stack is used by [LanguageBuilder] to make helpers available to extension
  /// methods (`tr`, `trP`, etc.) during the build phase. Since extension methods
  /// don't have [BuildContext], they rely on this stack to find the current helper.
  ///
  /// The helper pushed onto the stack comes from [LanguageBuilder], which may be:
  /// - An explicit `languageHelper` parameter
  /// - A helper from [LanguageScope] (via [of])
  /// - [LanguageHelper.instance] (fallback)
  ///
  /// The stack allows nested [LanguageBuilder] widgets to work correctly, with each
  /// builder pushing its helper during build and popping it after.
  static final List<LanguageHelper> _stack = [];

  /// Gets the current scoped [LanguageHelper] from the stack, or [LanguageHelper.instance]
  /// if none is active.
  ///
  /// This is used by extension methods to find which helper to use. The helper at the
  /// top of the stack is the one from the most recently built [LanguageBuilder].
  static LanguageHelper get _current =>
      _stack.lastOrNull ?? LanguageHelper.instance;

  /// Pushes a [LanguageHelper] onto the stack.
  ///
  /// Called by [LanguageBuilder] during its build method to make the helper available
  /// to extension methods during the synchronous build phase.
  static void _push(LanguageHelper helper) => _stack.add(helper);

  /// Pops a [LanguageHelper] from the stack.
  ///
  /// Called by [LanguageBuilder] after its build completes to clean up the stack.
  static void _pop() {
    if (_stack.isNotEmpty) _stack.removeLast();
  }

  /// Returns the [LanguageHelper] from the nearest [LanguageScope] ancestor,
  /// or [LanguageHelper.instance] if no scope is found.
  ///
  /// This method does not register a dependency on the [LanguageScope], which means
  /// the widget will not automatically rebuild when the scope changes. This is intentional
  /// because [LanguageBuilder] widgets handle rebuilds through their own mechanism when
  /// the helper's language changes via the [change] method.
  ///
  /// Since [LanguageHelper.instance] is always available, this method always returns
  /// a valid helper (either from scope or the default instance).
  ///
  /// **Note**: If you need to automatically rebuild when the scope changes (i.e., when
  /// a different helper instance is provided), wrap your widget in a [LanguageBuilder]
  /// instead of using this method directly.
  ///
  /// When no [LanguageScope] is found in the widget tree, this method logs an informational
  /// message (if debug logging is enabled) to help developers understand that the default
  /// [LanguageHelper.instance] is being used.
  ///
  /// Example:
  /// ```dart
  /// Builder(
  ///   builder: (context) {
  ///     final helper = LanguageHelper.of(context);
  ///     return Text(helper.translate('Hello'));
  ///   },
  /// )
  /// ```
  static LanguageHelper of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<LanguageScope>();
    if (scope == null) {
      // Log once per context to avoid spam
      final contextId = identityHashCode(context);
      if (!_noScopeLoggedContexts.contains(contextId)) {
        _noScopeLoggedContexts.add(contextId);

        LiteLogger(
          name: 'LanguageHelper',
          enabled: true,
          minLevel: LogLevel.debug,
          usePrint: false,
        ).warning(() {
          final message =
              'No LanguageScope found in widget tree. Using default LanguageHelper.instance. '
              'Wrap your app with LanguageScope to provide a custom helper.';
          return message;
        });
      }
      return LanguageHelper.instance;
    }
    return scope.languageHelper;
  }

  /// Tracks contexts where we've already logged the "no scope" message.
  /// Uses context identity hash codes to prevent duplicate logs.
  static final Set<int> _noScopeLoggedContexts = {};

  /// To control [LanguageBuilder]
  final Set<_LanguageBuilderState> _states = {};

  @visibleForTesting
  Set<UpdateLanguage> get states => _states;

  /// Prefer using the built-in instance of `LanguageHelper` when possible instead of creating a custom one.
  /// Utilizing the built-in instance allows access to all extension methods (such as `tr`, `trP`, `trT`, `trF`)
  /// and builder widgets (like `LanguageBuilder` and `Tr`) without the need to pass the instance explicitly to each.
  /// This approach simplifies usage and ensures consistency across your application.
  ///
  /// When creating a custom instance of `LanguageHelper`, you can use it in several ways:
  ///
  /// 1. **With `.trC()` extension method** (always available):
  /// ```dart
  /// final helper = LanguageHelper('CustomLanguageHelper');
  /// await helper.initial(data: myData);
  ///
  /// // String
  /// final translated = 'Translate this text'.trC(helper);
  ///
  /// // Widget
  /// final text = Text('Translate this text'.trC(helper));
  /// ```
  ///
  /// 2. **With `LanguageBuilder` or `LanguageScope`** (extension methods work):
  /// When a custom helper is used with [LanguageBuilder] or [LanguageScope], the convenience
  /// extensions (`tr`, `trP`, `trT`, `trF`) become available within that builder/scope:
  /// ```dart
  /// final helper = LanguageHelper('CustomLanguageHelper');
  /// await helper.initial(data: myData);
  ///
  /// // Using LanguageBuilder with explicit helper
  /// LanguageBuilder(
  ///   languageHelper: helper,
  ///   builder: (context) {
  ///     return Text('Hello'.tr), // Works! Uses helper
  ///   },
  /// )
  ///
  /// // Using LanguageScope
  /// LanguageScope(
  ///   languageHelper: helper,
  ///   child: LanguageBuilder(
  ///     builder: (context) {
  ///       return Text('Hello'.tr), // Works! Uses helper from scope
  ///     },
  ///   ),
  /// )
  /// ```
  ///
  /// 3. **Direct translation** (always available):
  /// ```dart
  /// final translated = helper.translate('Hello');
  /// ```
  ///
  /// **Note**: Extension methods (`tr`, `trP`, etc.) only work with custom instances when called
  /// within a [LanguageBuilder] that uses that instance (either explicitly or via [LanguageScope]).
  /// Outside of [LanguageBuilder], extension methods fall back to [LanguageHelper.instance].
  ///
  LanguageHelper(this.prefix);

  /// Prefix of the key to save the data to `SharedPreferences`.
  final String prefix;

  /// Storage for all language data.
  final LanguageData _data = {};

  /// Provider for language data.
  late LanguageDataProvider _dataProvider;

  /// Collection of data providers.
  Iterable<LanguageDataProvider> _dataProviders = [];

  /// Gets the current language data as [LanguageData].
  ///
  /// This returns all translations for all languages currently loaded.
  LanguageData get data => _data;

  /// Storage for language data overrides.
  ///
  /// Overrides take precedence over regular [data] when both contain
  /// the same translation key.
  final LanguageData _dataOverrides = {};

  /// Provider for language data overrides.
  late LanguageDataProvider _dataOverridesProvider;

  /// Collection of data override providers.
  Iterable<LanguageDataProvider> _dataOverridesProviders = [];

  /// Gets the current language data overrides as [LanguageData].
  ///
  /// Overrides take precedence over regular [data] when both contain
  /// the same translation key.
  LanguageData get dataOverrides => _dataOverrides;

  /// List of all the keys of text in your project.
  ///
  /// You can maintain it by yourself or using [language_helper_generator](https://pub.dev/packages/language_helper_generator).
  /// This value will be used by `analyze` method to let you know that which
  /// text is missing in your language data.
  Iterable<String> _analysisKeys = const {};

  /// Gets the list of [LanguageCodes] from both [data] and [dataOverrides].
  Set<LanguageCodes> get codes => {..._codes, ..._codesOverrides}.toSet();
  Set<LanguageCodes> _codes = {};

  /// Gets the list of [LanguageCodes] from [dataOverrides].
  Set<LanguageCodes> get codesOverrides => _codesOverrides;
  Set<LanguageCodes> _codesOverrides = {};

  /// Gets the list of languages as [Locale].
  Set<Locale> get locales => codes.map((e) => e.locale).toSet();

  /// Gets the current language as [LanguageCodes].
  ///
  /// You must call `await initial()` before using this getter.
  LanguageCodes get code => _currentCode ?? LanguageCode.code;

  /// The current language code being used.
  ///
  /// This is set after [initial] is called and updated when [change] is called.
  LanguageCodes? _currentCode;

  /// Gets the current language as [Locale].
  ///
  /// You must call `await initial()` before using this getter.
  Locale get locale => code.locale;

  /// The initial language code specified during initialization.
  ///
  /// This is used as a fallback when [useInitialCodeWhenUnavailable] is `true`
  /// and an unavailable language code is requested.
  LanguageCodes? _initialCode;

  /// Whether to fall back to the initial code when an unavailable language is requested.
  ///
  /// When `true`, if [change] is called with a language code that's not in [codes],
  /// the helper will change to [initialCode] instead of keeping the current language.
  /// When `false`, the helper will keep using the current language if the requested
  /// code is unavailable.
  ///
  /// This can be changed at runtime using [setUseInitialCodeWhenUnavailable].
  bool _useInitialCodeWhenUnavailable = false;

  /// Whether to automatically save and restore the current language code.
  ///
  /// When `true`, the current language code is saved to `SharedPreferences` whenever
  /// it changes, and restored when [initial] is called.
  bool _isAutoSave = false;

  /// Whether to sync with the device language when it changes.
  ///
  /// When `true`, the app language will automatically update when the device
  /// language changes. When `false`, the app language remains independent of
  /// the device language.
  bool _syncWithDevice = true;

  /// Whether to force rebuild all [LanguageBuilder] widgets instead of only the root.
  ///
  /// When `true`, all [LanguageBuilder] widgets rebuild when the language changes.
  /// When `false`, only the root [LanguageBuilder] rebuilds (better performance).
  ///
  /// You can override this per-widget using the `forceRebuild` parameter in
  /// [LanguageBuilder] or [Tr].
  bool _forceRebuild = false;

  /// Callback function called when the language changes.
  ///
  /// This is set via the `onChanged` parameter in [initial] and is called
  /// whenever [change] successfully updates the language.
  void Function(LanguageCodes code)? _onChanged;

  /// Stream on changed. Please remember to close this stream subscription
  /// when you are done to avoid memory leaks.
  Stream<LanguageCodes> get stream => _streamController.stream;
  final StreamController<LanguageCodes> _streamController =
      StreamController.broadcast();

  /// Whether debug logging is enabled.
  ///
  /// When `true`, the helper prints debug information about language changes,
  /// translation lookups, and other operations to the console using [lite_logger].
  ///
  /// Debug logs include:
  /// - Language initialization and changes
  /// - Translation lookups and missing translations
  /// - Data synchronization with device language
  /// - Analysis results when enabled
  ///
  /// The logger is configured with colored output and timestamps for better
  /// readability during development and debugging.
  bool get isDebug => _isDebug;
  bool _isDebug = false;

  /// Internal logger instance for debug logging.
  ///
  /// Uses [lite_logger] for formatted, colored debug output. The logger is
  /// initialized when [initial] is called and is configured based on the
  /// [isDebug] parameter. Logs are only emitted when [isDebug] is `true`.
  ///
  /// This logger instance is shared across all debug logging within this
  /// [LanguageHelper] instance and respects the instance's [isDebug] setting.
  LiteLogger? _logger;

  /// The SharedPreferences key used to store the saved language code.
  ///
  /// Visible for testing purposes.
  @visibleForTesting
  String get codeKey => _autoSaveCodeKey;

  /// The SharedPreferences key used to store the saved language code.
  ///
  /// Format: `$prefix.AutoSaveCode`
  String get _autoSaveCodeKey => '$prefix.AutoSaveCode';

  /// The SharedPreferences key used to store the device language code.
  ///
  /// Visible for testing purposes.
  @visibleForTesting
  String get deviceCodeKey => _deviceCodeKey;

  /// The SharedPreferences key used to store the device language code.
  ///
  /// Format: `$prefix.DeviceCode`
  String get _deviceCodeKey => '$prefix.DeviceCode';

  /// Whether the LanguageHelper is initializing.
  bool _isInitializing = false;

  /// Returns `true` if the `initial` method has been completed.
  bool get isInitialized => _ensureInitialized.isCompleted;

  /// Wait until the `initial` method is completed.
  Future<void> get ensureInitialized => _ensureInitialized.future;
  final _ensureInitialized = Completer<void>();

  /// Initializes the helper with language data.
  ///
  /// This method must be called before using the helper. It sets up the language
  /// data, determines the initial language, and configures various options.
  ///
  /// The initial language is determined in this order:
  /// 1. [initialCode] parameter (if provided)
  /// 2. Saved language from `SharedPreferences` (if [isAutoSave] is `true`)
  /// 3. Device language (if [syncWithDevice] is `true` and has changed)
  /// 4. First language in [data]
  /// 5. [LanguageCodes.en] (if [data] is empty)
  ///
  /// After initialization, all [LanguageBuilder] widgets will rebuild when the
  /// language changes. Set [forceRebuild] to `true` to force all builders to
  /// rebuild (may decrease performance).
  Future<void> initial({
    /// Data of languages. If this value is empty, a temporary data ([LanguageDataProvider.data({LanguagesCode.en: {}})])
    /// will be added to let make it easier to develop the app.
    required Iterable<LanguageDataProvider> data,

    /// Data of the languages that you want to override the [data]. This feature
    /// will helpful when you want to change just some translations of the language
    /// that are already available in the [data].
    ///
    /// Common case is that you're using the generated [languageData] as your [data]
    /// but you want to change some translations (mostly with [LanguageConditions]).
    Iterable<LanguageDataProvider> dataOverrides = const [
      LanguageDataProvider.empty(),
    ],

    /// Keys to analyze for missing translations.
    ///
    /// List of all the keys of text in your project. You can maintain it by
    /// yourself or using [language_helper_generator](https://pub.dev/packages/language_helper_generator).
    ///
    /// When provided, the [analyze] method will compare these keys against
    /// the keys in your [data] to identify:
    /// - Missing keys: in [analysisKeys] but not in [data]
    /// - Deprecated keys: in [data] but not in [analysisKeys]
    ///
    /// These keys are typically extracted from your source code using the
    /// language_helper generator, which scans for `.tr`, `.trP`, `.trT`, and
    /// `.translate()` usage.
    ///
    /// If empty (default), the analyzer will only check for missing translations
    /// across different languages without checking against a reference set.
    ///
    /// Example:
    /// ```dart
    /// await languageHelper.initial(
    ///   data: [myData],
    ///   analysisKeys: {'Hello', 'Goodbye', 'Welcome'}, // Your app's text keys
    /// );
    /// ```
    Iterable<String> analysisKeys = const {},

    /// Firstly, the app will try to use this [initialCode]. If [initialCode] is null,
    /// the plugin will try to get the current device language. If both of them are
    /// null, the plugin will use the first language in the [data].
    LanguageCodes? initialCode,

    /// If this value is `true`, the plugin will use the [initialCode] if you [change]
    /// to the language that is not in the [data], otherwise it will do nothing
    /// (keeps the last language).
    bool useInitialCodeWhenUnavailable = false,

    /// Use this value as default for all [LanguageBuilder].
    bool forceRebuild = false,

    /// Auto save the current change of the language. The app will use the new
    /// language in the next open instead of [initialCode].
    bool isAutoSave = true,

    /// TODO(lamnhan066): Make sure (add test) the caching feature this feature worked before publishing
    ///
    /// Caches the valid data for later use. Useful when using data from `network`.
    // bool cachesData = true,

    /// Apply the device language when it's changed.
    /// If this value is `true`, update the app language when the device language changes.
    /// Otherwise, keep the current app language even if the device language changes.
    bool syncWithDevice = true,

    /// Attempts to handle Locale codes with optional country specification.
    /// When a full Locale code (including country code) is not available in the data,
    /// this method will fallback to using just the language code.
    ///
    /// For example, if 'zh_CN' (Chinese, China) is not available,
    /// it will try using 'zh' (Chinese) to set the language.
    /// Set 'isOptionalCountryCode' to true to enable this behavior.
    bool isOptionalCountryCode = true,

    /// Callback on language changed.
    void Function(LanguageCodes code)? onChanged,

    /// Enable debug logging.
    ///
    /// When `true`, debug information is printed to the console using [lite_logger]
    /// with colored output and timestamps. Debug logs include:
    /// - Language initialization and code changes
    /// - Translation lookups and missing text warnings
    /// - Device language synchronization events
    /// - Data provider operations
    /// - Analysis results when [analysisKeys] are provided
    ///
    /// Defaults to `false` to avoid console noise in production.
    ///
    /// Example:
    /// ```dart
    /// await languageHelper.initial(
    ///   data: [myData],
    ///   isDebug: !kReleaseMode, // Enable in debug builds only
    /// );
    /// ```
    bool isDebug = false,
  }) async {
    if (isInitialized) return;

    if (_isInitializing) return ensureInitialized;
    _isInitializing = true;

    _data.clear();
    _dataOverrides.clear();
    _dataProviders = data;
    _dataOverridesProviders = dataOverrides;
    _forceRebuild = forceRebuild;
    _onChanged = onChanged;
    _isDebug = isDebug;
    _useInitialCodeWhenUnavailable = useInitialCodeWhenUnavailable;
    _isAutoSave = isAutoSave;
    _syncWithDevice = syncWithDevice;
    _analysisKeys = analysisKeys;
    _initialCode = initialCode;
    _logger ??= LiteLogger(
      name: prefix,
      enabled: isDebug,
      minLevel: LogLevel.debug,
      usePrint: false,
    );

    // When the `data` is empty, a temporary data will be added.
    if (_dataProviders.isEmpty) {
      _logger?.info(
        () =>
            'The `data` is empty, we will use a temporary `data` for the developing state',
      );
      _dataProviders = [
        LanguageDataProvider.data({LanguageCodes.en: {}}),
      ];
    }

    _dataProvider = await _chooseTheBestDataProvider(_dataProviders, false);
    _dataOverridesProvider = await _chooseTheBestDataProvider(
      _dataOverridesProviders,
      true,
    );

    LanguageCodes finalCode = _initialCode ?? LanguageCode.code;

    _codes = await _dataProvider.getSupportedCodes();
    _codesOverrides = await _dataOverridesProvider.getSupportedCodes();

    assert(
      _codes.isNotEmpty,
      'The LanguageData in the `data` must be not empty',
    );

    // Try to reload from memory if `isAutoSave` is `true`
    if (_isAutoSave) {
      final prefs = await SharedPreferences.getInstance();

      if (prefs.containsKey(_autoSaveCodeKey)) {
        final code = prefs.getString(_autoSaveCodeKey);

        if (code != null && code.isNotEmpty) {
          finalCode = LanguageCodes.fromCode(code);
        }
      }
    }

    // Try to get the device language code if `syncWithDevice` is `true`
    if (_syncWithDevice) {
      final prefs = await SharedPreferences.getInstance();
      final prefCodeCode = prefs.getString(_deviceCodeKey);
      final currentCode = LanguageCode.code;

      if (prefCodeCode == null) {
        // Sync with device only track the changing of the device language,
        // so it will not use the device language for the app at the first time.
        prefs.setString(_deviceCodeKey, currentCode.code);
        _logger?.info(
          () =>
              'Sync with device saved the current language to local database.',
        );
      } else {
        // We only consider to change the app language when the device language
        // is changed. So it will not affect the app language that is set by the user.
        final prefCode = LanguageCodes.fromCode(prefCodeCode);
        if (currentCode != prefCode) {
          finalCode = currentCode;
          prefs.setString(_deviceCodeKey, currentCode.code);
          _logger?.step(
            () => 'Sync with device applied the new device language',
          );
        } else {
          _logger?.debug(
            () => 'Sync with device used the current app language',
          );
        }
      }
    }

    if (!codes.contains(finalCode)) {
      LanguageCodes? tempCode;
      if (isOptionalCountryCode && finalCode.locale.countryCode != null) {
        // Try to use the `languageCode` only if the `languageCode_countryCode`
        // is not available
        _logger?.info(
          () =>
              'language does not contain the $finalCode => Try to use the `languageCode` only..',
        );
        try {
          tempCode = LanguageCodes.fromCode(finalCode.locale.languageCode);
          if (!codes.contains(tempCode)) {
            tempCode = null;
          }
        } catch (_) {}
      }

      if (tempCode == null) {
        _logger?.info(
          () =>
              'Unable to use the `languageCode` only => Change the code to ${codes.first}',
        );
      } else {
        _logger?.info(
          () =>
              'Able to use the `languageCode` only => Change the code to $tempCode',
        );
      }

      finalCode = tempCode ?? codes.first;
    }

    _logger?.step(() => 'Set `currentCode` to $finalCode');
    _currentCode = finalCode;

    _data.addAll(await _dataProvider.getData(code));
    _dataOverrides.addAll(await _dataOverridesProvider.getData(code));

    if (_isDebug) {
      analyze();
    }

    if (!_ensureInitialized.isCompleted) {
      _ensureInitialized.complete();
    }
  }

  /// Disposes all resources used by this [LanguageHelper] instance.
  ///
  /// Closes the [stream] controller, which will cancel all active stream
  /// subscriptions. After calling this method, the helper should not be used
  /// for language changes or translations.
  ///
  /// **Important**: Only call this method when you're certain the helper
  /// instance will no longer be used, typically when the app is shutting down
  /// or when removing a scoped helper that's no longer needed.
  ///
  /// Example:
  /// ```dart
  /// // Only dispose custom instances, not LanguageHelper.instance
  /// final helper = LanguageHelper('CustomHelper');
  /// // ... use helper ...
  /// helper.dispose();
  /// ```
  void dispose() {
    _streamController.close();
  }

  /// Adds new translation data to the current [data].
  ///
  /// This method allows you to dynamically add translations from a [LanguageDataProvider]
  /// at runtime, useful for loading translations from a network source, user-generated
  /// content, or A/B testing scenarios.
  ///
  /// The [overwrite] parameter controls whether existing translations are replaced:
  /// - `true` (default): New translations will overwrite existing ones with the same keys
  /// - `false`: Existing translations are preserved, only new keys are added
  ///
  /// The [activate] parameter controls whether widgets are updated immediately:
  /// - `true` (default): All [LanguageBuilder] widgets will rebuild automatically
  /// - `false`: Data is added but widgets won't update until [reload] or [change] is called
  ///
  /// **Warning**: When [activate] is `true`, be careful not to call this during widget
  /// build as it may cause `setState` errors. Consider setting [activate] to `false`
  /// and calling [reload] manually after the build completes.
  ///
  /// Example:
  /// ```dart
  /// // Load translations from network
  /// final networkProvider = LanguageDataProvider.network('https://api.example.com/translations');
  /// await languageHelper.addData(networkProvider);
  ///
  /// // Add translations without overwriting existing ones
  /// await languageHelper.addData(
  ///   LanguageDataProvider.data(newTranslations),
  ///   overwrite: false,
  /// );
  ///
  /// // Add data without triggering rebuilds immediately
  /// await languageHelper.addData(
  ///   additionalData,
  ///   activate: false,
  /// );
  /// // ... do other operations ...
  /// await languageHelper.reload(); // Update widgets now
  /// ```
  Future<void> addData(
    LanguageDataProvider data, {
    bool overwrite = true,
    bool activate = true,
  }) async {
    final getData = await data.getData(_currentCode!);
    _addData(data: getData, database: _data, overwrite: overwrite);
    _codes.addAll(await data.getSupportedCodes());
    if (activate) change(code);
    _logger?.info(
      () =>
          'The new `data` is added and activated with overwrite is $overwrite',
    );
  }

  /// Adds new translation data to the current [dataOverrides].
  ///
  /// Override data takes precedence over regular [data] when both contain the same
  /// translation key. This is useful for:
  /// - User-customized translations
  /// - A/B testing different translation variants
  /// - Temporarily overriding translations for specific contexts
  ///
  /// The [overwrite] parameter controls whether existing overrides are replaced:
  /// - `true` (default): New overrides will overwrite existing ones with the same keys
  /// - `false`: Existing overrides are preserved, only new keys are added
  ///
  /// The [activate] parameter controls whether widgets are updated immediately:
  /// - `true` (default): All [LanguageBuilder] widgets will rebuild automatically
  /// - `false`: Data is added but widgets won't update until [reload] or [change] is called
  ///
  /// **Warning**: When [activate] is `true`, be careful not to call this during widget
  /// build as it may cause `setState` errors. Consider setting [activate] to `false`
  /// and calling [reload] manually after the build completes.
  ///
  /// Example:
  /// ```dart
  /// // Add user customizations that override default translations
  /// await languageHelper.addDataOverrides(
  ///   LanguageDataProvider.data(userCustomizations),
  /// );
  ///
  /// // Add test translations without affecting widgets immediately
  /// await languageHelper.addDataOverrides(
  ///   testTranslations,
  ///   activate: false,
  /// );
  /// ```
  Future<void> addDataOverrides(
    LanguageDataProvider dataOverrides, {
    bool overwrite = true,
    bool activate = true,
  }) async {
    final getData = await dataOverrides.getData(_currentCode!);
    _addData(data: getData, database: _dataOverrides, overwrite: overwrite);
    _codesOverrides.addAll(await dataOverrides.getSupportedCodes());
    if (activate) change(code);
    _logger?.info(
      () =>
          'The new `dataOverrides` is added and activated with overwrite is $overwrite',
    );
  }

  /// Translates [text] to the current or specified language.
  ///
  /// This method looks up the translation for [text] in the current language
  /// (or [toCode] if provided) and replaces any parameters in the translated
  /// text using [params].
  ///
  /// The translation lookup follows this priority:
  /// 1. [dataOverrides] for the target language
  /// 2. [data] for the target language
  /// 3. Returns the original [text] with parameters replaced if no translation is found
  ///
  /// If the translation is a [LanguageConditions], it will evaluate the condition
  /// based on the parameter value and select the appropriate translation.
  ///
  /// Parameter replacement supports two formats:
  /// - `@{paramName}` - Recommended format (e.g., "Hello @{name}")
  /// - `@paramName` - Legacy format (must be followed by space, end of line, or newline)
  ///
  /// Returns the translated text with parameters replaced, or the original
  /// text if no translation is found.
  ///
  /// Example:
  /// ```dart
  /// // Simple translation
  /// final text = languageHelper.translate('Hello');
  ///
  /// // Translation with parameters
  /// final text = languageHelper.translate(
  ///   'Hello @{name}',
  ///   params: {'name': 'John'},
  /// );
  ///
  /// // Translation to specific language
  /// final text = languageHelper.translate(
  ///   'Hello',
  ///   toCode: LanguageCodes.vi,
  /// );
  /// ```
  String translate(
    /// Text that you want to translate
    String text, {

    /// Translate with parameters
    ///
    /// Ex: Your translated text is "Current number is @currentNumber"
    ///
    /// Your params = {'currentNumber' : '3'}
    ///
    /// => Result: "Current number is 3"
    Map<String, dynamic> params = const {},

    /// To specific [LanguageCodes] instead of the current [code]
    LanguageCodes? toCode,
  }) {
    toCode ??= _currentCode;
    final stringParams = params.map((key, value) => MapEntry(key, '$value'));

    if (!codes.contains(toCode) && !codesOverrides.contains(toCode)) {
      _logger?.warning(
        () =>
            'Cannot translate this text because $toCode is not available in `data` and `dataOverrides` ($text)',
      );
      return _replaceParams(text, stringParams);
    }

    final translated = _dataOverrides[toCode]?[text] ?? _data[toCode]?[text];
    if (translated == null) {
      _logger?.warning(
        () => 'This text is not contained in current $toCode ($text)',
      );
      return _replaceParams(text, stringParams);
    }

    if (translated is LanguageConditions) {
      return _replaceParamsCondition(translated, stringParams, text);
    }

    return _replaceParams(translated, stringParams);
  }

  /// Reloads all [LanguageBuilder] widgets to apply updated translation data.
  ///
  /// This is a convenience method that calls [change] with the current [code].
  /// Use this after modifying translation data (e.g., via [addData] or
  /// [addDataOverrides]) to refresh all visible text in the app without
  /// changing the language.
  ///
  /// All [LanguageBuilder] widgets in the widget tree will be notified to
  /// rebuild with the updated translations.
  ///
  /// Example:
  /// ```dart
  /// await languageHelper.addData(newDataProvider);
  /// await languageHelper.reload(); // Refresh all visible translations
  /// ```
  Future<void> reload() => change(code);

  /// Changes the application language to [toCode].
  ///
  /// This method updates the current language code and triggers all
  /// [LanguageBuilder] widgets to rebuild with new translations. The change
  /// will be persisted to local storage if [isAutoSave] was enabled during
  /// [initial].
  ///
  /// **Behavior when [toCode] is unavailable:**
  /// - If [useInitialCodeWhenUnavailable] is `false`: The change is ignored
  ///   and the current language remains unchanged.
  /// - If [useInitialCodeWhenUnavailable] is `true`: Falls back to [initialCode]
  ///   if it's available in the data.
  ///
  /// The method will:
  /// 1. Validate that [toCode] exists in [codes] or [codesOverrides]
  /// 2. Load translation data if not already cached for the new language
  /// 3. Update all [LanguageBuilder] widgets to reflect the new language
  /// 4. Save the new language code to SharedPreferences (if [isAutoSave] is enabled)
  /// 5. Emit events via [stream] and call [onChanged] callback
  ///
  /// Returns a [Future] that completes when all updates are finished.
  ///
  /// Example:
  /// ```dart
  /// // Change to Vietnamese
  /// await languageHelper.change(LanguageCodes.vi);
  ///
  /// // All widgets will automatically update to show Vietnamese text
  /// ```
  Future<void> change(LanguageCodes toCode) async {
    if (!codes.contains(toCode)) {
      _logger?.warning(
        () => '$toCode is not available in `data` or `dataOverrides`',
      );

      if (!_useInitialCodeWhenUnavailable) {
        _logger?.info(
          () =>
              'Does not allow using the initial code => Cannot change the language.',
        );
        return;
      } else {
        if (codes.contains(_initialCode)) {
          _logger?.step(
            () =>
                '`useInitialCodeWhenUnavailable` is true => Change the language to $_initialCode',
          );
          _currentCode = _initialCode;
        } else {
          _logger?.warning(
            () =>
                '`useInitialCodeWhenUnavailable` is true but the `initialCode` is not available in `data` or `dataOverrides` => Cannot change the language',
          );
          return;
        }
      }
    } else {
      _logger?.step(() => 'Set currentCode to $toCode');
      _currentCode = toCode;
    }

    if (!_data.containsKey(_currentCode)) {
      _dataProvider = await _chooseTheBestDataProvider(_dataProviders, false);
      _dataOverridesProvider = await _chooseTheBestDataProvider(
        _dataOverridesProviders,
        true,
      );

      final data = await _dataProvider.getData(code);
      final dataOverrides = await _dataOverridesProvider.getData(code);
      _data.addAll(data);
      _dataOverrides.addAll(dataOverrides);
    }

    _logger?.step(
      () => 'Change language to $toCode for ${_states.length} states',
    );
    Set<_LanguageBuilderState> needToUpdate = {};
    for (var state in _states) {
      if (state._forceRebuild) {
        needToUpdate.add(state);
        continue;
      }

      final root = state._of();
      if (root != null) {
        needToUpdate.add(root);
      } else {
        needToUpdate.add(state);
      }
    }

    _logger?.debug(() => 'Need to update ${needToUpdate.length} states');

    for (var state in needToUpdate) {
      state.updateLanguage();
    }

    _streamController.sink.add(toCode);
    if (_onChanged != null) {
      _onChanged!(toCode);
    }

    // Save to local memory
    if (_isAutoSave) {
      _logger?.debug(() => 'Save this $toCode to local memory');
      SharedPreferences.getInstance().then((pref) {
        pref.setString(_autoSaveCodeKey, toCode.code);
      });
    }

    _logger?.step(() => 'Changing completed!');
  }

  /// Updates whether to use [initialCode] when an unavailable language is requested.
  ///
  /// When [newValue] is `true`, calling [change] with a language code that
  /// doesn't exist in [codes] or [codesOverrides] will fall back to [initialCode]
  /// if it's available.
  ///
  /// When `false` (default), requests to change to unavailable languages are
  /// ignored and the current language remains unchanged.
  ///
  /// This can be changed at runtime to provide more or less strict language
  /// switching behavior.
  ///
  /// Example:
  /// ```dart
  /// // Allow fallback to initial code
  /// languageHelper.setUseInitialCodeWhenUnavailable(true);
  ///
  /// // User tries to change to unavailable language
  /// await languageHelper.change(LanguageCodes.zh);
  /// // Falls back to initialCode (e.g., LanguageCodes.en) if available
  ///
  /// // Disable fallback
  /// languageHelper.setUseInitialCodeWhenUnavailable(false);
  /// await languageHelper.change(LanguageCodes.zh);
  /// // Change is ignored, current language unchanged
  /// ```
  void setUseInitialCodeWhenUnavailable(bool newValue) {
    _useInitialCodeWhenUnavailable = newValue;
  }

  /// Analyze the [_data] to identify missing or deprecated translation keys.
  ///
  /// Compares the keys in your [data] with the [analysisKeys] provided during
  /// [initial] to identify:
  /// - Missing keys: keys in [analysisKeys] but not in any language's [data]
  /// - Deprecated keys: keys in [data] but not in [analysisKeys]
  /// - Missing translations: keys present in one language but missing in others
  ///
  /// When [isDebug] is `true`, the analysis results are automatically logged
  /// to the console using the debug logger with colored output.
  ///
  /// Returns a formatted string with the analysis results. The output format:
  ///
  /// ```
  /// ==================================================
  /// Analyze all languages...
  /// Missing keys:
  ///   >> Key name 1
  ///   >> Key name 2
  /// Deprecated keys:
  ///   >> Old key name 1
  /// Specific text missing results:
  ///   >> LanguageCodes.en:
  ///       >> Text is missed in vi
  ///   >> LanguageCodes.vi:
  ///       >> Text is missed in en
  /// ==================================================
  /// ```
  ///
  /// Note: This method only works with data from [LanguageDataProvider.data].
  /// It cannot analyze data from assets or network providers.
  ///
  /// Example:
  /// ```dart
  /// final result = languageHelper.analyze();
  /// print(result);
  /// ```
  String analyze() {
    final List<String> keys = [];
    StringBuffer buffer = StringBuffer('');

    buffer.write('\n\n');
    buffer.write('==================================================');
    buffer.write('\n');
    buffer.write('Analyze all languages...');
    buffer.write('\n');

    // Add all keys to [keys]
    for (final code in codes) {
      if (!_data.containsKey(code)) {
        return 'Can analyze the data from `LanguageDataProvider.data` only';
      }
      for (final key in _data[code]!.keys) {
        if (!keys.contains(key)) keys.add(key);
      }
    }

    final List<String> missedKeys = [];
    final List<String> removedKeys = [];
    if (_analysisKeys.isNotEmpty) {
      // Analyze which keys are in [analysisKeys] but not in [data].
      for (final key in _analysisKeys) {
        if (!keys.contains(key)) {
          missedKeys.add(key);
        }
      }

      // Analyze which keys are in [data] but not in [analysisKeys]
      for (final key in keys) {
        if (!_analysisKeys.contains(key)) {
          removedKeys.add(key);
        }
      }
    }

    if (missedKeys.isNotEmpty) {
      buffer.write(
        'The below keys were missing ([analysisKeys]: yes, [data]: no):\n',
      );
      for (final key in missedKeys) {
        buffer.write('  >> ${_removeNewline(key)}\n');
      }
      buffer.write('\n');
    }

    if (removedKeys.isNotEmpty) {
      buffer.write(
        'The below keys were deprecated ([analysisKeys]: no, [data]: yes):\n',
      );
      for (final key in removedKeys) {
        buffer.write('  >> ${_removeNewline(key)}\n');
      }
      buffer.write('\n');
    }

    buffer.write('Specific text missing results:\n');

    // Analyze the results
    for (final code in codes) {
      buffer.write('  >> $code:\n');
      for (final key in keys) {
        if (!_data[code]!.keys.contains(key)) {
          buffer.write('      >> ${_removeNewline(key)}\n');
        }
      }

      // Don't need to add \n for the last element
      if (code != codes.last) buffer.write('\n');
    }

    buffer.write('==================================================');
    buffer.write('\n');

    _logger?.debug(() => buffer.toString());

    return buffer.toString();
  }

  /// Selects the first available data provider from [providers] that has translations.
  ///
  /// This internal method iterates through [providers] and returns the first one
  /// that supports at least one language code. Used during [initial] to select
  /// which provider to use for loading translation data.
  ///
  /// Returns an empty [LanguageDataProvider] if no provider has available data.
  ///
  /// The [isOverrides] parameter is used for logging purposes to distinguish
  /// between regular data providers and override providers.
  Future<LanguageDataProvider> _chooseTheBestDataProvider(
    Iterable<LanguageDataProvider> providers,
    bool isOverrides,
  ) async {
    LanguageDataProvider? result;
    for (final provider in providers) {
      Set<LanguageCodes> codes = await provider.getSupportedCodes();

      if (codes.isNotEmpty) {
        result = provider;
        break;
      }
    }

    return result ?? LanguageDataProvider.data({});
  }

  /// Replaces parameter placeholders in [input] with values from [params].
  ///
  /// Supports two placeholder formats:
  /// - `@{paramName}` - Recommended format (e.g., "Hello @{name}" → "Hello John")
  /// - `@paramName` - Legacy format (must be followed by space, end of line, or newline)
  ///
  /// This is an internal method used by [translate] to process parameterized
  /// translation strings.
  ///
  /// Returns [input] as a string with all matching parameters replaced, or
  /// the original string if [params] is empty.
  String _replaceParams(dynamic input, Map<String, dynamic> params) {
    if (params.isEmpty) return '$input';

    params.forEach((key, value) {
      // @param and end with space, end of line, new line.
      input = '$input'.replaceAll('@{$key}', '$value');
      input = '$input'.replaceAll(RegExp('@$key(?=\\s|\$|\\n)'), '$value');
    });

    return input as String;
  }

  /// Merges [data] into [database] with optional overwrite behavior.
  ///
  /// This internal method handles merging translation data from multiple sources.
  /// When [overwrite] is `true`, existing translations for the same keys will
  /// be replaced with new values. When `false`, existing translations are preserved.
  ///
  /// The merging process:
  /// 1. Adds new language codes to [database] if they don't exist
  /// 2. Adds new translation keys within existing languages
  /// 3. Optionally overwrites existing keys based on [overwrite] parameter
  ///
  /// This is used internally by [addData] and [addDataOverrides] to manage
  /// translation data from multiple providers.
  void _addData({
    required LanguageData data,
    required LanguageData database,
    required bool overwrite,
  }) {
    for (final element in data.entries) {
      final code = element.key;
      final data = element.value;

      /// If the code isn't in the database -> just add it
      if (!database.containsKey(code)) {
        database[code] = data;
        continue;
      }

      final copy = {...database[code]!};
      final current = database[code]!;
      for (final adding in data.entries) {
        // If the adding key isn't in the language data -> just add it
        if (!current.containsKey(adding.key)) {
          copy[adding.key] = adding.value;
          continue;
        }

        // If it's duplicated, only adds when overwrite is true
        if (overwrite) {
          copy[adding.key] = adding.value;
        }
      }
      database[code] = copy;
    }
  }

  /// Evaluates [LanguageConditions] and replaces parameters in the selected translation.
  ///
  /// This internal method handles translations that use conditional logic based
  /// on parameter values. It:
  /// 1. Extracts the condition parameter value from [params]
  /// 2. Looks up the matching condition in [translateCondition.conditions]
  /// 3. Falls back to 'default' or '_' if the exact value isn't found
  /// 4. Replaces all parameters in the selected translation string
  /// 5. Returns [fallback] with parameters replaced if no condition matches
  ///
  /// Used internally by [translate] when processing [LanguageConditions] translations.
  String _replaceParamsCondition(
    LanguageConditions translateCondition,
    Map<String, dynamic> params,
    String fallback,
  ) {
    if (!params.containsKey(translateCondition.param)) {
      _logger?.warning(
        () =>
            'The params does not contain the condition param: ${translateCondition.param}',
      );
      return _replaceParams(fallback, params);
    }

    final param = params[translateCondition.param];
    final conditions = translateCondition.conditions;
    final translated =
        conditions[param] ?? conditions['default'] ?? conditions['_'];

    if (translated == null) {
      _logger?.warning(
        () =>
            'There is no result for key $param of condition ${translateCondition.param}',
      );
      return _replaceParams(fallback, params);
    }

    return _replaceParams(translated, params);
  }

  /// Replaces newline characters in [text] with a visible symbol for analysis output.
  ///
  /// This internal utility method converts newlines to ' ⏎ ' (space-return-arrow-space)
  /// to make multi-line translation keys visible in analysis reports. Used by [analyze]
  /// to format output when translation keys contain line breaks.
  String _removeNewline(String text) {
    return text.replaceAll('\n', ' ⏎ ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LanguageHelper && other.prefix == prefix;
  }

  @override
  int get hashCode => prefix.hashCode;
}
