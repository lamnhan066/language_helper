import 'dart:async';

import 'package:flutter/material.dart';
import 'package:language_code/language_code.dart';
import 'package:lite_logger/lite_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../language_helper.dart';
import 'mixins/update_language.dart';

part 'extensions/language_helper_extension.dart';
part 'widgets/language_builder.dart';

/// A helper class for managing multiple languages and translations in Flutter apps.
///
/// [LanguageHelper] provides a centralized way to:
/// - Load translations from multiple sources (Dart maps, JSON assets, network)
/// - Switch between languages dynamically
/// - Translate text with parameter substitution
/// - Handle plural forms and conditional translations
/// - Persist language preferences
/// - Sync with device language settings
/// - Automatically rebuild widgets when language changes
///
/// **Basic Usage:**
/// ```dart
/// // Initialize with translation data
/// await LanguageHelper.instance.initial(
///   data: [
///     LanguageDataProvider.data(myLanguageData),
///   ],
/// );
///
/// // Translate text
/// final text = LanguageHelper.instance.translate('Hello');
///
/// // Change language
/// await LanguageHelper.instance.change(LanguageCodes.vi);
/// ```
///
/// **Using Extension Methods:**
/// ```dart
/// // Within LanguageBuilder widgets
/// LanguageBuilder(
///   builder: (context) {
///     return Text('Hello'.tr); // Automatic translation
///   },
/// )
/// ```
///
/// **Multiple Instances:**
/// You can create custom instances for different parts of your app:
/// ```dart
/// final packageHelper = LanguageHelper('PackageHelper');
/// await packageHelper.initial(data: [packageData]);
/// ```
///
/// However, prefer using [LanguageHelper.instance] when possible, as it
/// enables extension methods (`tr`, `trP`, etc.) throughout your app without
/// needing to pass the instance explicitly.
///
/// See also:
/// - [LanguageDataProvider] - For loading translations from various sources
/// - [LanguageBuilder] - Widget that rebuilds when language changes
/// - [LanguageScope] - Provides a helper to descendant widgets
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

  /// Collection of data providers.
  Iterable<LanguageDataProvider> _dataProviders = [];

  /// Gets the current language data as [LanguageData].
  ///
  /// This returns all translations for all languages currently loaded in memory.
  /// The data is organized as a map where keys are [LanguageCodes] and values
  /// are maps of translation keys to their translated values (strings or [LanguageConditions]).
  ///
  /// **Important Notes:**
  /// - This only contains data that has been loaded so far. Languages that haven't
  ///   been accessed yet may not be present until they're first used (for lazy/network providers).
  /// - The returned map is the internal storage - modifications will affect the helper's state.
  /// - Data is loaded on-demand for [LanguageDataProvider.lazyData] and [LanguageDataProvider.network]
  ///   providers when a language is first accessed via [change] or [translate].
  ///
  /// **Use Cases:**
  /// - Inspecting available translations
  /// - Exporting translations to JSON
  /// - Debugging translation issues
  /// - Programmatically modifying translations (use with caution)
  ///
  /// Example:
  /// ```dart
  /// // Access all loaded translations
  /// final allData = languageHelper.data;
  /// final englishTranslations = allData[LanguageCodes.en];
  /// print(englishTranslations?['Hello']); // Prints the English translation
  ///
  /// // Check if a language is loaded
  /// if (allData.containsKey(LanguageCodes.vi)) {
  ///   print('Vietnamese translations are loaded');
  /// }
  /// ```
  LanguageData get data => _data;

  /// Gets the list of [LanguageCodes] from all data providers.
  ///
  /// This returns all language codes that are available across all registered
  /// [LanguageDataProvider] instances. The codes are collected from all providers
  /// and combined into a single set (duplicates are automatically removed).
  ///
  /// **Important:** You must call `await initial()` before using this getter,
  /// otherwise it will return an empty set.
  ///
  /// **Use Cases:**
  /// - Displaying a language picker with available options
  /// - Validating if a language code is supported before changing
  /// - Configuring Flutter's `supportedLocales`
  ///
  /// Example:
  /// ```dart
  /// // Get all supported language codes
  /// final codes = languageHelper.codes;
  /// print('Supported languages: $codes');
  /// // Output: {LanguageCodes.en, LanguageCodes.vi, LanguageCodes.es}
  ///
  /// // Check if a language is available
  /// if (languageHelper.codes.contains(LanguageCodes.vi)) {
  ///   await languageHelper.change(LanguageCodes.vi);
  /// }
  ///
  /// // Use in MaterialApp
  /// MaterialApp(
  ///   supportedLocales: languageHelper.locales,
  ///   // ...
  /// )
  /// ```
  Set<LanguageCodes> get codes => _codes.toSet();
  Set<LanguageCodes> _codes = {};

  /// Gets the list of languages as [Locale].
  ///
  /// This returns all supported language codes converted to Flutter's [Locale]
  /// format. This is useful for configuring [MaterialApp.supportedLocales] or
  /// [CupertinoApp.supportedLocales].
  ///
  /// You must call `await initial()` before using this getter.
  ///
  /// Example:
  /// ```dart
  /// MaterialApp(
  ///   supportedLocales: languageHelper.locales,
  ///   locale: languageHelper.locale,
  ///   // ...
  /// )
  /// ```
  Set<Locale> get locales => codes.map((e) => e.locale).toSet();

  /// Gets the current language as [LanguageCodes].
  ///
  /// This returns the language code that is currently active. All translations
  /// via [translate] use this language by default.
  ///
  /// **Important:** You must call `await initial()` before using this getter,
  /// otherwise it will throw a null check error.
  ///
  /// The current code is updated when:
  /// - [initial] completes (sets the initial language)
  /// - [change] is called (switches to a new language)
  ///
  /// Example:
  /// ```dart
  /// // Get current language
  /// final currentLang = languageHelper.code;
  /// print('Current language: $currentLang'); // e.g., LanguageCodes.en
  ///
  /// // Use in conditional logic
  /// if (languageHelper.code == LanguageCodes.vi) {
  ///   // Show Vietnamese-specific UI
  /// }
  /// ```
  LanguageCodes get code => _currentCode!;

  /// The current language code being used.
  ///
  /// This is set after [initial] is called and updated when [change] is called.
  LanguageCodes? _currentCode;

  /// Gets the current language as [Locale].
  ///
  /// This returns the current language code converted to Flutter's [Locale] format.
  /// This is useful for configuring [MaterialApp.locale] or [CupertinoApp.locale].
  ///
  /// **Important:** You must call `await initial()` before using this getter,
  /// otherwise it will throw a null check error.
  ///
  /// Example:
  /// ```dart
  /// MaterialApp(
  ///   locale: languageHelper.locale,
  ///   supportedLocales: languageHelper.locales,
  ///   // ...
  /// )
  /// ```
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
  bool _forceRebuild = true;

  /// Callback function called when the language changes.
  ///
  /// This is set via the `onChanged` parameter in [initial] and is called
  /// whenever [change] successfully updates the language.
  void Function(LanguageCodes code)? _onChanged;

  /// Stream that emits events whenever the language changes.
  ///
  /// This stream emits a [LanguageCodes] value every time [change] is called
  /// successfully. You can listen to this stream to react to language changes
  /// outside of the widget tree.
  ///
  /// **Important:** Remember to cancel the stream subscription when you're done
  /// to avoid memory leaks. Use `subscription.cancel()` or dispose the listener
  /// in your widget's `dispose` method.
  ///
  /// **Note:** The stream emits the new language code after all [LanguageBuilder]
  /// widgets have been notified to rebuild.
  ///
  /// Example:
  /// ```dart
  /// // Listen to language changes
  /// final subscription = languageHelper.stream.listen((code) {
  ///   print('Language changed to: $code');
  ///   // Perform actions when language changes
  /// });
  ///
  /// // In a StatefulWidget
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   _subscription = languageHelper.stream.listen((code) {
  ///     setState(() {
  ///       // Update state based on language change
  ///     });
  ///   });
  /// }
  ///
  /// @override
  /// void dispose() {
  ///   _subscription?.cancel(); // Important: cancel to avoid leaks
  ///   super.dispose();
  /// }
  /// ```
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

  /// Returns `true` if the [initial] method has been completed.
  ///
  /// This is useful for checking whether the helper is ready to use before
  /// accessing properties like [code], [data], or [codes].
  ///
  /// Example:
  /// ```dart
  /// if (languageHelper.isInitialized) {
  ///   print('Current language: ${languageHelper.code}');
  /// } else {
  ///   print('Helper not initialized yet');
  /// }
  /// ```
  bool get isInitialized => _ensureInitialized.isCompleted;

  /// A [Future] that completes when the [initial] method finishes.
  ///
  /// You can await this future to ensure the helper is fully initialized
  /// before using it. This is particularly useful when initialization happens
  /// asynchronously and you need to wait for it to complete.
  ///
  /// **Note:** If [initial] has already completed, this future will complete
  /// immediately. If [initial] hasn't been called yet, this future will
  /// never complete (until [initial] is called).
  ///
  /// Example:
  /// ```dart
  /// // Wait for initialization
  /// await languageHelper.ensureInitialized;
  /// // Now safe to use languageHelper.code, languageHelper.translate, etc.
  ///
  /// // Or use in a widget
  /// FutureBuilder(
  ///   future: languageHelper.ensureInitialized,
  ///   builder: (context, snapshot) {
  ///     if (snapshot.connectionState == ConnectionState.done) {
  ///       return Text(languageHelper.translate('Hello'));
  ///     }
  ///     return CircularProgressIndicator();
  ///   },
  /// )
  /// ```
  Future<void> get ensureInitialized => _ensureInitialized.future;
  final _ensureInitialized = Completer<void>();

  /// Initializes the helper with language data.
  ///
  /// This method must be called before using the helper. It sets up the language
  /// data, determines the initial language, and configures various options.
  ///
  /// **Initialization Process:**
  /// 1. Registers all [LanguageDataProvider] instances
  /// 2. Loads supported language codes from all providers
  /// 3. Determines the initial language code (see priority below)
  /// 4. Loads translation data for the initial language
  /// 5. Configures logging, persistence, and device sync
  ///
  /// **Initial Language Priority:**
  /// The initial language is determined in this order:
  /// 1. [initialCode] parameter (if provided and available in [data])
  /// 2. Saved language from `SharedPreferences` (if [isAutoSave] is `true`)
  /// 3. Device language (if [syncWithDevice] is `true` and has changed since last run)
  /// 4. First language code from [data] providers
  /// 5. [LanguageCodes.en] (if [data] is empty - temporary fallback for development)
  ///
  /// **Country Code Handling:**
  /// If [isOptionalCountryCode] is `true` (default), when a full locale code
  /// (e.g., `zh_CN`) is not available, the helper will fall back to the language
  /// code only (e.g., `zh`). This provides better compatibility with device locales.
  ///
  /// **Performance:**
  /// After initialization, all [LanguageBuilder] widgets will rebuild when the
  /// language changes by default. Set [forceRebuild] to `false` to only rebuild
  /// the root widget for better performance in large widget trees.
  ///
  /// **Thread Safety:**
  /// This method is safe to call multiple times - subsequent calls after the
  /// first initialization will return immediately without re-initializing.
  ///
  /// **Error Handling:**
  /// If [data] is empty, a temporary provider with empty English translations
  /// will be added to allow development to continue. A warning will be logged.
  ///
  /// Example:
  /// ```dart
  /// // Basic initialization
  /// await languageHelper.initial(
  ///   data: [
  ///     LanguageDataProvider.data(myLanguageData),
  ///   ],
  /// );
  ///
  /// // With all options
  /// await languageHelper.initial(
  ///   data: [
  ///     LanguageDataProvider.asset('assets/languages'),
  ///     LanguageDataProvider.network('https://api.example.com/translations'),
  ///   ],
  ///   initialCode: LanguageCodes.en,
  ///   useInitialCodeWhenUnavailable: true,
  ///   forceRebuild: false, // Better performance
  ///   isAutoSave: true,
  ///   syncWithDevice: true,
  ///   isOptionalCountryCode: true,
  ///   onChanged: (code) => print('Language changed to $code'),
  ///   isDebug: !kReleaseMode,
  /// );
  /// ```
  Future<void> initial({
    /// Data of languages. If this value is empty, a temporary data ([LanguageDataProvider.data({LanguagesCode.en: {}})])
    /// will be added to let make it easier to develop the app.
    required Iterable<LanguageDataProvider> data,

    /// Firstly, the app will try to use this [initialCode]. If [initialCode] is null,
    /// the plugin will try to get the current device language. If both of them are
    /// null, the plugin will use the first language in the [data].
    LanguageCodes? initialCode,

    /// If this value is `true`, the plugin will use the [initialCode] if you [change]
    /// to the language that is not in the [data], otherwise it will do nothing
    /// (keeps the last language).
    bool useInitialCodeWhenUnavailable = false,

    /// Use this value as default for all [LanguageBuilder].
    bool forceRebuild = true,

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

    if (_isInitializing) return await ensureInitialized;
    _isInitializing = true;

    _data.clear();
    _dataProviders = data;
    _forceRebuild = forceRebuild;
    _onChanged = onChanged;
    _isDebug = isDebug;
    _useInitialCodeWhenUnavailable = useInitialCodeWhenUnavailable;
    _isAutoSave = isAutoSave;
    _syncWithDevice = syncWithDevice;
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

    LanguageCodes finalCode = _initialCode ?? LanguageCode.code;

    _codes = await _loadCodesFromProviders(_dataProviders);

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

    _data.addAll(await _loadDataFromProviders(_currentCode!, _dataProviders));

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

  /// Adds a new [LanguageDataProvider] to the list of data providers.
  ///
  /// This method allows you to dynamically add translation sources at runtime.
  /// The provider will be used for all future language changes and translation lookups.
  ///
  /// The provider's [LanguageDataProvider.override] property controls whether its
  /// translations overwrite existing ones:
  /// - `true`: New translations will overwrite existing ones with the same keys
  /// - `false`: Only new translation keys are added (existing keys preserved)
  ///
  /// The [activate] parameter controls whether widgets are updated immediately:
  /// - `true` (default): All [LanguageBuilder] widgets will rebuild automatically
  /// - `false`: Data is added but widgets won't update until [reload] or [change] is called
  ///
  /// **Warning**: When [activate] is `true`, be careful not to call this during widget
  /// build as it may cause `setState` errors. Consider setting [activate] to `false`
  /// and calling [reload] manually after the build completes.
  ///
  /// **Note**: The provider is added to the end of the providers list. If multiple
  /// providers contain the same translation key, later providers (with `override: true`)
  /// will overwrite earlier ones.
  ///
  /// Example:
  /// ```dart
  /// // Add a network provider for remote translations
  /// final networkProvider = LanguageDataProvider.network('https://api.example.com/translations');
  /// await languageHelper.addProvider(networkProvider);
  ///
  /// // Add a provider without immediate activation
  /// await languageHelper.addProvider(
  ///   additionalProvider,
  ///   activate: false,
  /// );
  /// // ... do other operations ...
  /// await languageHelper.reload(); // Activate now
  /// ```
  Future<void> addProvider(
    LanguageDataProvider provider, {
    bool activate = true,
  }) async {
    _dataProviders = [..._dataProviders, provider];

    final data = await Future.wait([
      _loadCodesFromProviders([provider]),
      _loadDataFromProviders(_currentCode!, [provider]),
    ]);

    final newCodes = data[0] as Set<LanguageCodes>?;
    final newData = data[1] as LanguageData?;

    if (newCodes != null && newCodes.isNotEmpty) {
      _codes.addAll(newCodes);
    }

    if (newData != null &&
        newData.isNotEmpty &&
        newData.containsKey(_currentCode!)) {
      for (final entry in newData[_currentCode!]!.entries) {
        if (provider.override) {
          _data[_currentCode!]![entry.key] = entry.value;
        } else {
          _data[_currentCode!]!.putIfAbsent(entry.key, () => entry.value);
        }
      }
    }
    if (activate) await reload();
    _logger?.info(
      () =>
          'The new `provider` is added and activated with override is ${provider.override}',
    );
  }

  /// Removes a [LanguageDataProvider] from the list of data providers.
  ///
  /// This method allows you to dynamically remove translation sources at runtime.
  /// After removal, translations from this provider will no longer be available.
  ///
  /// The [activate] parameter controls whether widgets are updated immediately:
  /// - `true` (default): All [LanguageBuilder] widgets will rebuild automatically
  /// - `false`: Provider is removed but widgets won't update until [reload] or [change] is called
  ///
  /// **Warning**: When [activate] is `true`, be careful not to call this during widget
  /// build as it may cause `setState` errors. Consider setting [activate] to `false`
  /// and calling [reload] manually after the build completes.
  ///
  /// **Note**: Only the exact provider instance is removed. If the same provider
  /// was added multiple times, only one instance is removed. Translations that were
  /// already loaded from this provider remain in memory until the language is changed.
  ///
  /// Example:
  /// ```dart
  /// // Remove a provider
  /// await languageHelper.removeProvider(networkProvider);
  ///
  /// // Remove without immediate activation
  /// await languageHelper.removeProvider(
  ///   oldProvider,
  ///   activate: false,
  /// );
  /// await languageHelper.reload(); // Update widgets now
  /// ```
  Future<void> removeProvider(
    LanguageDataProvider provider, {
    bool activate = true,
  }) async {
    _dataProviders = _dataProviders.where((p) => p != provider).toList();
    if (activate) await reload();
    _logger?.info(
      () =>
          'The `provider` is removed and activated with override is ${provider.override}',
    );
  }

  /// Translates [text] to the current or specified language.
  ///
  /// This method looks up the translation for [text] in the current language
  /// (or [toCode] if provided) and replaces any parameters in the translated
  /// text using [params].
  ///
  /// The translation lookup follows this priority:
  /// 1. [data] for the target language (searches all registered providers in order)
  /// 2. Returns the original [text] with parameters replaced if no translation is found
  ///
  /// When multiple providers contain the same translation key, the first provider
  /// in the list (or the one with `override: true`) takes precedence.
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

    if (!codes.contains(toCode)) {
      _logger?.warning(
        () =>
            'Cannot translate this text because $toCode is not available in `data` ($text)',
      );
      return _replaceParams(text, stringParams);
    }

    final translated = _data[toCode]?[text];
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
  /// Use this after modifying translation data (e.g., via [addProvider]) to refresh
  /// all visible text in the app without changing the language.
  ///
  /// All [LanguageBuilder] widgets in the widget tree will be notified to
  /// rebuild with the updated translations.
  ///
  /// **When to use:**
  /// - After adding new translation data with [addProvider] when `activate: false`
  /// - After manually modifying the [data] map
  /// - When you want to force a refresh of all translations without changing language
  ///
  /// Example:
  /// ```dart
  /// // Add data without immediate activation
  /// await languageHelper.addData(newDataProvider, activate: false);
  /// // ... do other operations ...
  /// await languageHelper.reload(); // Refresh all visible translations now
  /// ```
  Future<void> reload() => change(code);

  /// Changes the application language to [toCode].
  ///
  /// This method updates the current language code and triggers all
  /// [LanguageBuilder] widgets to rebuild with new translations. The change
  /// will be persisted to local storage if [isAutoSave] was enabled during
  /// [initial].
  ///
  /// **Process:**
  /// 1. Validates that [toCode] exists in [codes] (or handles fallback)
  /// 2. Loads translation data if not already cached for the new language
  ///    (for lazy/network providers, this may involve async operations)
  /// 3. Updates all [LanguageBuilder] widgets to reflect the new language
  /// 4. Saves the new language code to SharedPreferences (if [isAutoSave] is enabled)
  /// 5. Emits events via [stream] and calls [onChanged] callback
  ///
  /// **Behavior when [toCode] is unavailable:**
  /// - If [useInitialCodeWhenUnavailable] is `false` (default): The change is ignored
  ///   and the current language remains unchanged. A warning is logged.
  /// - If [useInitialCodeWhenUnavailable] is `true`: Falls back to [initialCode]
  ///   if it's available in the data. If [initialCode] is also unavailable, the
  ///   change is ignored.
  ///
  /// **Performance:**
  /// - For [LanguageDataProvider.data] and [LanguageDataProvider.lazyData]: Fast (synchronous)
  /// - For [LanguageDataProvider.asset]: Medium (async I/O, but cached after first load)
  /// - For [LanguageDataProvider.network]: Slow (async network request, depends on connection)
  ///
  /// **Widget Rebuilds:**
  /// By default, all [LanguageBuilder] widgets rebuild. If [forceRebuild] was set
  /// to `false` during [initial], only the root [LanguageBuilder] widgets rebuild
  /// (better performance for large widget trees).
  ///
  /// Returns a [Future] that completes when all updates are finished, including
  /// any async data loading operations.
  ///
  /// Example:
  /// ```dart
  /// // Change to Vietnamese
  /// await languageHelper.change(LanguageCodes.vi);
  ///
  /// // All widgets will automatically update to show Vietnamese text
  ///
  /// // Handle unavailable language
  /// try {
  ///   await languageHelper.change(LanguageCodes.zh);
  /// } catch (e) {
  ///   // Language not available, current language unchanged
  /// }
  /// ```
  Future<void> change(LanguageCodes toCode) async {
    if (!codes.contains(toCode)) {
      _logger?.warning(() => '$toCode is not available in `data`');

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
                '`useInitialCodeWhenUnavailable` is true but the `initialCode` is not available in `data` => Cannot change the language',
          );
          return;
        }
      }
    } else {
      _logger?.step(() => 'Set currentCode to $toCode');
      _currentCode = toCode;
    }

    if (!_data.containsKey(_currentCode)) {
      final data = await _loadDataFromProviders(_currentCode!, _dataProviders);
      _data.clear();
      _data.addAll(data);
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
  /// doesn't exist in [codes] will fall back to [initialCode]
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

  /// Loads codes from all providers and returns the codes.
  ///
  /// This internal method iterates through all [dataProviders] and returns the codes
  /// from the first provider that has codes for the given [code].
  ///
  /// Returns an empty [Set<LanguageCodes>] if no provider has codes.
  Future<Set<LanguageCodes>> _loadCodesFromProviders(
    Iterable<LanguageDataProvider> providers,
  ) async {
    final results = await Future.wait<Set<LanguageCodes>>(
      providers.map((provider) => provider.getSupportedCodes()),
    );
    return results.expand((codeSet) => codeSet).toSet();
  }

  /// Loads data from all providers and returns the data.
  ///
  /// This internal method iterates through all [providers] and returns the data
  /// from the first provider that has data for the given [code].
  ///
  /// Returns an empty [LanguageData] if no provider has data for the given [code].
  Future<LanguageData> _loadDataFromProviders(
    LanguageCodes code,
    Iterable<LanguageDataProvider> providers,
  ) async {
    final data = <String, dynamic>{};
    for (final provider in providers) {
      final providerData = await provider.getData(code);
      if (providerData.isNotEmpty && providerData.containsKey(code)) {
        for (final entry in providerData[code]!.entries) {
          if (provider.override) {
            data[entry.key] = entry.value;
          } else {
            data.putIfAbsent(entry.key, () => entry.value);
          }
        }
      }
    }
    return {code: data};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LanguageHelper && other.prefix == prefix;
  }

  @override
  int get hashCode => prefix.hashCode;
}
