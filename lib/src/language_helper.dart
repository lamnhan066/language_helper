import 'dart:async';

import 'package:flutter/material.dart';
import 'package:language_code/language_code.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../language_helper.dart';
import 'mixins/update_language.dart';
import 'utils/print_debug.dart';

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
    return scope?.languageHelper ?? LanguageHelper.instance;
  }

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

  /// Get list of [LanguageCodes] of the [data] and [dataOverrides]
  Set<LanguageCodes> get codes => {..._codes, ..._codesOverrides}.toSet();
  Set<LanguageCodes> _codes = {};

  /// Get list of [LanguageCodes] of the [dataOverrides]
  Set<LanguageCodes> get codesOverrides => _codesOverrides;
  Set<LanguageCodes> _codesOverrides = {};

  /// Get list of language as [Locale]
  Set<Locale> get locales => codes.map((e) => e.locale).toSet();

  /// Get current language as [LanguageCodes]
  ///
  /// You must be `await initial()` before using this variable.
  LanguageCodes get code => _currentCode!;

  /// The current language code being used.
  ///
  /// This is set after [initial] is called and updated when [change] is called.
  LanguageCodes? _currentCode;

  /// Get current language as [Locale]
  ///
  /// You must be `await initial()` before using this variable.
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
  /// translation lookups, and other operations to the console.
  bool get isDebug => _isDebug;
  bool _isDebug = false;

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

  /// Return `true` if the `initial` method is completed.
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

    /// List of all the keys of text in your project.
    ///
    /// You can maintain it by yourself or using [language_helper_generator](https://pub.dev/packages/language_helper_generator).
    /// This value will be used by `analyze` method to let you know that which
    /// text is missing in your language data.
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

    /// Print the debug log.
    bool isDebug = false,
  }) async {
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

    // When the `data` is empty, a temporary data will be added.
    if (_dataProviders.isEmpty) {
      printDebug(
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
        printDebug(
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
          printDebug(() => 'Sync with device applied the new device language');
        } else {
          printDebug(() => 'Sync with device used the current app language');
        }
      }
    }

    if (!codes.contains(finalCode)) {
      LanguageCodes? tempCode;
      if (isOptionalCountryCode && finalCode.locale.countryCode != null) {
        // Try to use the `languageCode` only if the `languageCode_countryCode`
        // is not available
        printDebug(
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
        printDebug(
          () =>
              'Unable to use the `languageCode` only => Change the code to ${codes.first}',
        );
      } else {
        printDebug(
          () =>
              'Able to use the `languageCode` only => Change the code to $tempCode',
        );
      }

      finalCode = tempCode ?? codes.first;
    }

    printDebug(() => 'Set `currentCode` to $finalCode');
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

  /// Dispose all the controllers
  void dispose() {
    _streamController.close();
  }

  /// Add new data to the current [data].
  ///
  /// If [overwrite] is `true`, the available translation will be overwritten.
  ///
  /// If the [activate] is `true`, all the visible [LanguageBuilder]s will be rebuilt
  /// automatically, **notice that you may get the `setState` issue
  /// because of the rebuilding of the [LanguageBuilder] when it's still building.**
  Future<void> addData(
    LanguageDataProvider data, {
    bool overwrite = true,
    bool activate = true,
  }) async {
    final getData = await data.getData(_currentCode!);
    _addData(data: getData, database: _data, overwrite: overwrite);
    _codes.addAll(await data.getSupportedCodes());
    if (activate) change(code);
    printDebug(
      () =>
          'The new `data` is added and activated with overwrite is $overwrite',
    );
  }

  /// Add new data to the current [dataOverrides].
  ///
  /// If [overwrite] is `true`, the available translation will be overwritten.
  ///
  /// If the [activate] is `true`, all the visible [LanguageBuilder]s will be rebuilt
  /// automatically, **notice that you may get the `setState` issue
  /// because of the rebuilding of the [LanguageBuilder] when it's still building.**
  Future<void> addDataOverrides(
    LanguageDataProvider dataOverrides, {
    bool overwrite = true,
    bool activate = true,
  }) async {
    final getData = await dataOverrides.getData(_currentCode!);
    _addData(data: getData, database: _dataOverrides, overwrite: overwrite);
    _codesOverrides.addAll(await dataOverrides.getSupportedCodes());
    if (activate) change(code);
    printDebug(
      () =>
          'The new `dataOverrides` is added and activated with overwrite is $overwrite',
    );
  }

  /// Translate this [text] to the destination language
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
      printDebug(
        () =>
            'Cannot translate this text because $toCode is not available in `data` and `dataOverrides` ($text)',
      );
      return _replaceParams(text, stringParams);
    }

    final translated = _dataOverrides[toCode]?[text] ?? _data[toCode]?[text];
    if (translated == null) {
      printDebug(() => 'This text is not contained in current $toCode ($text)');
      return _replaceParams(text, stringParams);
    }

    if (translated is LanguageConditions) {
      return _replaceParamsCondition(translated, stringParams, text);
    }

    return _replaceParams(translated, stringParams);
  }

  /// Reload all the `LanguageBuilder` to apply the new data.
  Future<void> reload() => change(code);

  /// Change the language to this [code]
  Future<void> change(LanguageCodes toCode) async {
    if (!codes.contains(toCode)) {
      printDebug(() => '$toCode is not available in `data` or `dataOverrides`');

      if (!_useInitialCodeWhenUnavailable) {
        printDebug(
          () =>
              'Does not allow using the initial code => Cannot change the language.',
        );
        return;
      } else {
        if (codes.contains(_initialCode)) {
          printDebug(
            () =>
                '`useInitialCodeWhenUnavailable` is true => Change the language to $_initialCode',
          );
          _currentCode = _initialCode;
        } else {
          printDebug(
            () =>
                '`useInitialCodeWhenUnavailable` is true but the `initialCode` is not available in `data` or `dataOverrides` => Cannot change the language',
          );
          return;
        }
      }
    } else {
      printDebug(() => 'Set currentCode to $toCode');
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

    printDebug(() => 'Change language to $toCode for ${_states.length} states');
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

    printDebug(() => 'Need to update ${needToUpdate.length} states');

    for (var state in needToUpdate) {
      state.updateLanguage();
    }

    _streamController.sink.add(toCode);
    if (_onChanged != null) {
      _onChanged!(toCode);
    }

    // Save to local memory
    if (_isAutoSave) {
      printDebug(() => 'Save this $toCode to local memory');
      SharedPreferences.getInstance().then((pref) {
        pref.setString(_autoSaveCodeKey, toCode.code);
      });
    }

    printDebug(() => 'Changing completed!');
  }

  /// Change the [useInitialCodeWhenUnavailable] value
  void setUseInitialCodeWhenUnavailable(bool newValue) {
    _useInitialCodeWhenUnavailable = newValue;
  }

  /// Analyze the [_data] so you can know which ones are missing what text.
  /// The results will be print in the console log with the below format:

  ///
  /// Result:
  ///   LanguageCodes.en:
  ///     some thing 1
  ///     some thing 2
  ///   LanguageCodes.vi:
  ///     some thing 3
  ///     some thing 4
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

    printDebug(() => buffer.toString());

    return buffer.toString();
  }

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

  /// Replace @{param} or @param with the real text
  String _replaceParams(dynamic input, Map<String, dynamic> params) {
    if (params.isEmpty) return '$input';

    params.forEach((key, value) {
      // @param and end with space, end of line, new line.
      input = '$input'.replaceAll('@{$key}', '$value');
      input = '$input'.replaceAll(RegExp('@$key(?=\\s|\$|\\n)'), '$value');
    });

    return input as String;
  }

  /// Add the [data] to the [database] with [overwrite] option.
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

  /// Replace @{param} or @param with the real text with [LanguageConditions]
  String _replaceParamsCondition(
    LanguageConditions translateCondition,
    Map<String, dynamic> params,
    String fallback,
  ) {
    if (!params.containsKey(translateCondition.param)) {
      printDebug(
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
      printDebug(
        () =>
            'There is no result for key $param of condition ${translateCondition.param}',
      );
      return _replaceParams(fallback, params);
    }

    return _replaceParams(translated, params);
  }

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
