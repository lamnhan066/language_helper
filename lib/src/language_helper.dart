import 'dart:async';

import 'package:flutter/material.dart';
import 'package:language_code/language_code.dart';
import 'package:language_helper/language_helper.dart';
import 'package:language_helper/src/mixins/update_language.dart';
import 'package:lite_logger/lite_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'extensions/language_helper_extension.dart';
part 'widgets/language_builder.dart';

/// Manages translations and language switching in Flutter apps.
///
/// Supports multiple data sources (Dart maps, JSON assets, network),
/// parameter substitution, plural forms, persistence, and device language
/// sync.
///
/// **Basic Usage:**
/// ```dart
/// await LanguageHelper.instance.initial(
///   LanguageConfig(
///     data: [LanguageDataProvider.data(myLanguageData)],
///   ),
/// );
/// final text = LanguageHelper.instance.translate('Hello');
/// await LanguageHelper.instance.change(LanguageCodes.vi);
/// ```
///
/// Prefer [LanguageHelper.instance] to enable extension methods (`tr`,
/// `trP`, etc.) throughout your app. Custom instances require explicit
/// passing or [LanguageBuilder].
///
/// See also: [LanguageDataProvider], [LanguageBuilder], [LanguageScope]
class LanguageHelper {
  /// Creates a custom helper instance. Prefer [LanguageHelper.instance] when
  /// possible to enable extension methods (`tr`, `trP`, etc.) throughout
  /// your app.
  ///
  /// Custom instances can be used with:
  /// - `.trC(helper)` extension method (always available)
  /// - [LanguageBuilder] or [LanguageScope] (enables `tr`, `trP`, etc.
  ///   within scope)
  /// - Direct `translate()` calls
  ///
  LanguageHelper(this.prefix);

  /// The default LanguageHelper instance.
  static final LanguageHelper instance = LanguageHelper('LanguageHelper');

  /// Stack of [LanguageHelper] instances used by [LanguageBuilder] to make
  /// helpers available to extension methods during build. The most recent
  /// builder's helper is on top.
  static final List<LanguageHelper> _stack = [];

  /// Gets the current helper from the stack, or [LanguageHelper.instance] if
  /// none is active.
  static LanguageHelper get _current =>
      _stack.lastOrNull ?? LanguageHelper.instance;

  /// Pushes a helper onto the stack. Called by [LanguageBuilder] during build.
  static void _push(LanguageHelper helper) => _stack.add(helper);

  /// Pops a helper from the stack. Called by [LanguageBuilder] after build
  /// completes.
  static void _pop() {
    if (_stack.isNotEmpty) _stack.removeLast();
  }

  /// Returns the helper from the nearest [LanguageScope] ancestor, or
  /// [LanguageHelper.instance] if none is found. Does not register a
  /// dependency, so widgets won't rebuild when the scope changes. Use
  /// [LanguageBuilder] if you need automatic rebuilds.
  static LanguageHelper of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<LanguageScope>();
    if (scope == null) {
      assert(() {
        const LiteLogger(
          name: 'LanguageHelper',
          minLevel: LogLevel.debug,
        ).warning(() {
          const message =
              'No LanguageScope found in widget tree. '
              'Using default LanguageHelper.instance. '
              'Wrap your app with LanguageScope to provide a custom helper.';
          return message;
        });
        return true;
      }(), 'No LanguageScope found in widget tree');

      return LanguageHelper.instance;
    }
    return scope.languageHelper;
  }

  /// To control [LanguageBuilder]
  final Set<_LanguageBuilderState> _states = {};

  @visibleForTesting
  /// The states of the [LanguageBuilder] widgets.
  Set<UpdateLanguage> get states => _states;

  /// Prefix of the key to save the data to `SharedPreferences`.
  final String prefix;

  /// Storage for all language data.
  LanguageData _data = {};

  /// Collection of data providers.
  Iterable<LanguageDataProvider> _dataProviders = [];

  /// All translations currently loaded in memory, organized by [LanguageCodes].
  /// Only contains data that has been loaded so far (lazy/network providers
  /// load on-demand). Modifying the returned map affects the helper's state.
  LanguageData get data => _data;

  /// All available language codes from all registered providers. Must call
  /// `initial()` first.
  Set<LanguageCodes> get codes => _codes.toSet();
  var _codes = <LanguageCodes>{};

  /// All supported language codes as Flutter [Locale] objects. Must call
  /// `initial()` first.
  Set<Locale> get locales => codes.map((e) => e.locale).toSet();

  /// The currently active language code. Must call `initial()` first. Updated
  /// by [initial] and [change].
  LanguageCodes get code => _currentCode!;

  /// The current language code. Set by [initial] and updated by [change].
  LanguageCodes? _currentCode;

  /// The current language as a Flutter [Locale]. Must call `initial()` first.
  Locale get locale => code.locale;

  /// The initial language code, used as fallback when
  /// `useInitialCodeWhenUnavailable` is true.
  LanguageCodes? _initialCode;

  /// Whether to fall back to `_initialCode` when an unavailable language is
  /// requested.
  bool _useInitialCodeWhenUnavailable = false;

  /// Whether to automatically save/restore the language code to/from
  /// SharedPreferences.
  bool _isAutoSave = false;

  /// Whether to automatically update the app language when the device language
  /// changes.
  bool _syncWithDevice = true;

  /// Whether to rebuild all [LanguageBuilder] widgets (true) or only the root
  /// (false, better performance).
  bool _forceRebuild = true;

  /// Callback called when the language changes. Set via `onChanged` in
  /// [initial].
  void Function(LanguageCodes code)? _onChanged;

  /// Stream that emits the new language code whenever [change] is called
  /// successfully. Remember to cancel subscriptions to avoid memory leaks.
  Stream<LanguageCodes> get stream => _streamController.stream;
  final StreamController<LanguageCodes> _streamController =
      StreamController.broadcast();

  /// Whether debug logging is enabled. When true, logs language changes,
  /// translation lookups, and other operations using `lite_logger`.
  bool get isDebug => _isDebug;
  bool _isDebug = false;

  /// Internal logger instance for debug logging. Initialized by [initial]
  /// based on [isDebug].
  LiteLogger? _logger;

  /// The SharedPreferences key for the saved language code.
  /// Format: `$prefix.AutoSaveCode`
  @visibleForTesting
  String get codeKey => _autoSaveCodeKey;
  String get _autoSaveCodeKey => '$prefix.AutoSaveCode';

  /// The SharedPreferences key for the device language code.
  /// Format: `$prefix.DeviceCode`
  @visibleForTesting
  String get deviceCodeKey => _deviceCodeKey;
  String get _deviceCodeKey => '$prefix.DeviceCode';

  /// Whether the LanguageHelper is initializing.
  bool _isInitializing = false;

  /// Returns `true` if [initial] has completed. Check this before accessing
  /// [code], [data], or [codes].
  bool get isInitialized => _ensureInitialized.isCompleted;

  /// A [Future] that completes when [initial] finishes. Await this to
  /// ensure the helper is ready. Completes immediately if already initialized,
  /// or never if [initial] hasn't been called.
  Future<void> get ensureInitialized => _ensureInitialized.future;
  final _ensureInitialized = Completer<void>();

  /// Initializes the helper with the provided [config]. Must be called before
  /// using the helper.
  ///
  /// **Initial Language Priority:**
  /// 1. [LanguageConfig.initialCode] when provided and available
  /// 2. Saved language from SharedPreferences when
  ///    [LanguageConfig.isAutoSave] is true
  /// 3. Device language when [LanguageConfig.syncWithDevice] is true and
  ///    the device language has changed
  /// 4. First language from providers
  /// 5. [LanguageCodes.en] (fallback if data is empty)
  ///
  /// If [LanguageConfig.isOptionalCountryCode] is true, falls back to language
  /// code only when the full locale (e.g., `zh_CN`) is unavailable. Safe to
  /// call multiple times.
  Future<void> initial(LanguageConfig config) async {
    if (isInitialized) return;

    if (_isInitializing) return ensureInitialized;
    _isInitializing = true;

    _data.clear();
    _dataProviders = config.data;
    _forceRebuild = config.forceRebuild;
    _onChanged = config.onChanged;
    _isDebug = config.isDebug;
    _useInitialCodeWhenUnavailable = config.useInitialCodeWhenUnavailable;
    _isAutoSave = config.isAutoSave;
    _syncWithDevice = config.syncWithDevice;
    _initialCode = config.initialCode;
    _logger ??= LiteLogger(
      name: prefix,
      enabled: config.isDebug,
      minLevel: LogLevel.debug,
    );
    final isOptionalCountryCode = config.isOptionalCountryCode;

    // When the `data` is empty, a temporary data will be added.
    if (_dataProviders.isEmpty) {
      _logger?.info(
        () =>
            'The `data` is empty, we will use a temporary `data` '
            'for the developing state',
      );
      _dataProviders = [
        LanguageDataProvider.data({LanguageCodes.en: {}}),
      ];
    }

    var finalCode = _initialCode ?? LanguageCode.code;

    _codes = await _loadCodesFromProviders(_dataProviders);

    if (_codes.isEmpty) {
      _logger?.error(() => 'The LanguageData in the `data` is empty');
      return;
    }

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
        // so it will not use the device language for the app at the first
        // time.
        await prefs.setString(_deviceCodeKey, currentCode.code);
        _logger?.info(
          () =>
              'Sync with device saved the current language to local database.',
        );
      } else {
        // We only consider to change the app language when the device
        // language is changed. So it will not affect the app language that
        // is set by the user.
        final prefCode = LanguageCodes.fromCode(prefCodeCode);
        if (currentCode != prefCode) {
          finalCode = currentCode;
          await prefs.setString(_deviceCodeKey, currentCode.code);
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
        // Try to use the `languageCode` only if the
        // `languageCode_countryCode` is not available
        _logger?.info(
          () =>
              'language does not contain the $finalCode => '
              'Try to use the `languageCode` only..',
        );
        try {
          tempCode = LanguageCodes.fromCode(finalCode.locale.languageCode);
          if (!codes.contains(tempCode)) {
            tempCode = null;
          }
          // Catch the error when the language code is not valid.
          // ignore: avoid_catches_without_on_clauses
        } catch (_) {}
      }

      if (tempCode == null) {
        _logger?.info(
          () =>
              'Unable to use the `languageCode` only => '
              'Change the code to ${codes.first}',
        );
      } else {
        _logger?.info(
          () =>
              'Able to use the `languageCode` only => '
              'Change the code to $tempCode',
        );
      }

      finalCode = tempCode ?? codes.first;
    }

    _logger?.step(() => 'Set `currentCode` to $finalCode');
    _currentCode = finalCode;

    _data = await _loadDataFromProviders(_currentCode!, _dataProviders);

    if (!_ensureInitialized.isCompleted) {
      _ensureInitialized.complete();
    }
  }

  /// Disposes resources and closes the [stream] controller. Only call when the
  /// helper will no longer be used. Do not dispose [LanguageHelper.instance].
  ///
  /// **Important:** This method should only be called on custom
  /// [LanguageHelper] instances that are no longer needed. Never call this
  /// on [LanguageHelper.instance] as it is a singleton used throughout
  /// the app lifecycle.
  ///
  /// After calling [dispose], the helper should not be used anymore.
  /// Any attempts to use it may result in errors.
  Future<void> dispose() async {
    // StreamController.close() returns a Future but we don't need to await
    // it since we're disposing the controller and won't use it anymore.
    await _streamController.close();
  }

  /// Adds a provider dynamically at runtime. If [activate] is true (default),
  /// widgets rebuild immediately. Set to false during widget build to avoid
  /// setState errors, then call [reload]. Provider's `override` property
  /// controls whether translations overwrite existing keys.
  Future<void> addProvider(
    LanguageDataProvider provider, {
    bool activate = true,
  }) async {
    _dataProviders = [..._dataProviders, provider];

    final result = await Future.wait([
      _loadCodesFromProviders([provider]),
      _loadDataFromProviders(_currentCode!, [provider]),
    ]);

    _codes.addAll(result[0] as Iterable<LanguageCodes>);
    final data = result[1] as LanguageData;

    if (data.isNotEmpty && data.containsKey(_currentCode)) {
      for (final entry in data[_currentCode!]!.entries) {
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
          'The new `provider` is added and activated with override is '
          '${provider.override}',
    );
  }

  /// Removes a provider from the list. If [activate] is true (default),
  /// widgets rebuild immediately. Set to false during widget build to avoid
  /// setState errors, then call [reload].
  Future<void> removeProvider(
    LanguageDataProvider provider, {
    bool activate = true,
  }) async {
    _dataProviders = _dataProviders.where((p) => p != provider).toList();

    final result = await Future.wait([
      _loadCodesFromProviders(_dataProviders),
      _loadDataFromProviders(_currentCode!, _dataProviders),
    ]);

    _codes = result[0] as Set<LanguageCodes>;
    _data = result[1] as LanguageData;

    if (activate) await reload();
    _logger?.info(
      () =>
          'The `provider` is removed and activated with override is '
          '${provider.override}',
    );
  }

  /// Translates [text] to the current language (or [toCode] if provided) and
  /// replaces parameters using [params]. Supports `@{paramName}` (recommended)
  /// and `@paramName` formats. Returns original text with params replaced if
  /// translation not found. [LanguageConditions] are evaluated based on
  /// parameter values.
  String translate(
    /// Text to translate
    String text, {

    /// Parameters to replace in the translated text (e.g., `{'name': 'John'}`)
    Map<String, dynamic> params = const {},

    /// Target language code. Only works reliably with `LanguageData`;
    /// `LazyLanguageData` may not be loaded yet.
    LanguageCodes? toCode,
  }) {
    toCode ??= _currentCode;
    final stringParams = params.map((key, value) => MapEntry(key, '$value'));

    if (!codes.contains(toCode)) {
      _logger?.warning(
        () =>
            'Cannot translate this text because $toCode is not available '
            'in `data` ($text)',
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

  /// Reloads all [LanguageBuilder] widgets to apply updated translation data
  /// without changing language. Equivalent to `change(code)`.
  Future<void> reload() => change(code);

  /// Switches to [toCode] and reloads translations. Falls back to
  /// `_initialCode` if [toCode] is unavailable and
  /// `useInitialCodeWhenUnavailable` is true.
  ///
  /// **Note:** This method will always reload the translations from all
  /// providers even if the translations were previously loaded or `toCode`
  /// is the same as the current language.
  ///
  /// [reload] can be used instead of [change] as a shortcut of reloading the
  /// translations without changing the language.
  Future<void> change(LanguageCodes toCode) async {
    if (!codes.contains(toCode)) {
      _logger?.warning(() => '$toCode is not available in `data`');

      if (!_useInitialCodeWhenUnavailable) {
        _logger?.info(
          () =>
              'Does not allow using the initial code => '
              'Cannot change the language.',
        );
        return;
      } else {
        if (codes.contains(_initialCode)) {
          _logger?.step(
            () =>
                '`useInitialCodeWhenUnavailable` is true => '
                'Change the language to $_initialCode',
          );
          _currentCode = _initialCode;
        } else {
          _logger?.warning(
            () =>
                '`useInitialCodeWhenUnavailable` is true but the '
                '`initialCode` is not available in `data` => '
                'Cannot change the language',
          );
          return;
        }
      }
    } else {
      _logger?.step(() => 'Set currentCode to $toCode');
      _currentCode = toCode;
    }

    _data = await _loadDataFromProviders(_currentCode!, _dataProviders);

    _logger?.step(
      () => 'Change language to $toCode for ${_states.length} states',
    );
    final needToUpdate = <_LanguageBuilderState>{};
    for (final state in _states.toList()) {
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

    for (final state in needToUpdate) {
      state.updateLanguage();
    }

    _streamController.sink.add(toCode);
    _onChanged?.call(toCode);

    // Save to local memory
    if (_isAutoSave) {
      _logger?.debug(() => 'Save this $toCode to local memory');
      final pref = await SharedPreferences.getInstance();
      await pref.setString(_autoSaveCodeKey, toCode.code);
    }

    _logger?.step(() => 'Changing completed!');
  }

  /// Sets whether to fall back to `_initialCode` when changing to unavailable
  /// languages.
  ///
  /// Parameters:
  /// - [value]: If `true`, when [change] is called with an unavailable
  ///   language code, the helper will fall back to `_initialCode` (if it's
  ///   available). If `false`, [change] will fail silently when an
  ///   unavailable language is requested.
  ///
  /// This setting can also be configured during [initial] via the
  /// `useInitialCodeWhenUnavailable` parameter.
  // ignore: avoid_positional_boolean_parameters, use_setters_to_change_properties
  void setUseInitialCodeWhenUnavailable(bool value) {
    _useInitialCodeWhenUnavailable = value;
  }

  /// Replaces parameter placeholders (`@{paramName}` or `@paramName`) in
  /// [input] with [params]. Internal method used by [translate].
  String _replaceParams(dynamic input, Map<String, dynamic> params) {
    if (params.isEmpty) return '$input';

    var result = '$input';
    params.forEach((key, value) {
      // @param and end with space, end of line, new line.
      result = result.replaceAll('@{$key}', '$value');
      result = result.replaceAll(RegExp('@$key(?=\\s|\$|\\n)'), '$value');
    });

    return result;
  }

  /// Evaluates [LanguageConditions] based on [params] and replaces parameters
  /// in the selected translation. Falls back to 'default' or '_' if exact
  /// value not found. Internal method used by [translate].
  String _replaceParamsCondition(
    LanguageConditions translateCondition,
    Map<String, dynamic> params,
    String fallback,
  ) {
    if (!params.containsKey(translateCondition.param)) {
      _logger?.warning(
        () =>
            'The params does not contain the condition param: '
            '${translateCondition.param}',
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
            'There is no result for key $param of condition '
            '${translateCondition.param}',
      );
      return _replaceParams(fallback, params);
    }

    return _replaceParams(translated, params);
  }

  /// Loads language codes from all providers. Returns empty set if none found.
  Future<Set<LanguageCodes>> _loadCodesFromProviders(
    Iterable<LanguageDataProvider> providers,
  ) async {
    final results = await Future.wait<Set<LanguageCodes>>(
      providers.map((provider) => provider.getSupportedCodes()),
    );
    return results.expand((codeSet) => codeSet).toSet();
  }

  /// Loads translation data for [code] from all [providers]. Providers with
  /// `override: true` overwrite existing keys; `override: false` only adds
  /// new keys. Returns empty map if no data found.
  Future<LanguageData> _loadDataFromProviders(
    LanguageCodes code,
    Iterable<LanguageDataProvider> providers,
  ) async {
    final data = <LanguageCodes, Map<String, dynamic>>{};

    for (final provider in providers) {
      final providerData = await provider.getData(code);
      for (final entry in providerData.entries) {
        data.putIfAbsent(entry.key, () => {});
        for (final language in entry.value.entries) {
          if (provider.override) {
            data[entry.key]![language.key] = language.value;
          } else {
            data[entry.key]!.putIfAbsent(language.key, () => language.value);
          }
        }
      }
    }

    return data;
  }

  @override
  // LanguageHelper instances are compared by prefix for equality, which is
  // stable even though the class is mutable.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LanguageHelper && other.prefix == prefix;
  }

  @override
  // LanguageHelper instances use prefix for hashCode, which is stable even
  // though the class is mutable.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => prefix.hashCode;
}
