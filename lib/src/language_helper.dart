import 'dart:async';

import 'package:flutter/material.dart';
import 'package:language_code/language_code.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../language_helper.dart';
import 'mixins/update_language.dart';
import 'utils/print_debug.dart';

part 'language_builder.dart';

/// Make it easier for you to control multiple languages in your app
class LanguageHelper {
  // Get the LanguageHelper instance
  static LanguageHelper instance = LanguageHelper('LanguageHelper');

  /// To control [LanguageBuilder]
  final Set<UpdateLanguage> _states = {};

  /// Create a new instance with a modified `prefix` for `SharedPreferences`.
  LanguageHelper(this.prefix);

  /// Prefix of the key to save the data to `SharedPreferences`.
  final String prefix;

  /// Get all languages
  final LanguageData _data = {};

  /// Get all languages
  late LanguageDataProvider _dataProvider;

  late Iterable<LanguageDataProvider> _dataProviders;

  /// Get the current `data` as [LanguageData].
  LanguageData get data => _data;

  /// Get all languages
  final LanguageData _dataOverrides = {};

  /// Get all languages
  late LanguageDataProvider _dataOverridesProvider;

  late Iterable<LanguageDataProvider> _dataOverridesProviders;

  /// Get the current `dataOverrides` as [LanguageData].
  LanguageData get dataOverrides => _dataOverrides;

  /// List of all the keys of text in your project.
  ///
  /// You can maintain it by yourself or using [language_helper_generator](https://pub.dev/packages/language_helper_generator).
  /// This value will be used by `analyze` method to let you know that which
  /// text is missing in your language data.
  Iterable<String> _analysisKeys = const {};

  /// Get list of [LanguageCodes] from both [data] and [dataOverrides]
  Set<LanguageCodes> get codesBoth =>
      <LanguageCodes>{...codes, ...codesOverrides}.toSet();

  /// Get list of [LanguageCodes] of the [data]
  Set<LanguageCodes> get codes => _codes;
  Set<LanguageCodes> _codes = {};

  /// Get list of [LanguageCodes] of the [dataOverrides]
  Set<LanguageCodes> get codesOverrides => _codesOverrides;
  Set<LanguageCodes> _codesOverrides = {};

  /// Get list of language as [Locale]
  Set<Locale> get locales => codesBoth.map((e) => e.locale).toSet();

  /// Get current language as [LanguageCodes]
  ///
  /// You must be `await initial()` before using this variable.
  LanguageCodes get code => _currentCode!;

  /// Get current code
  LanguageCodes? _currentCode;

  /// Get current language as [Locale]
  ///
  /// You must be `await initial()` before using this variable.
  Locale get locale => code.locale;

  /// Initial code
  LanguageCodes? _initialCode;

  /// When you change the [LanguageCodes] by using [change] method, the app will
  /// change to the [_initialCode] if the code is unavailable. If not, the app
  /// will use keep using the last code.
  bool _useInitialCodeWhenUnavailable = false;

  /// Auto save and load [LanguageCodes] from memory
  bool _isAutoSave = false;

  /// Sync with the device language
  bool _syncWithDevice = true;

  /// Force rebuilds all widgets instead of only root widget. You can try to use
  /// this value if the widgets don't rebuild as your wish.
  bool _forceRebuild = false;

  /// On changed callback
  void Function(LanguageCodes code)? _onChanged;

  /// Stream on changed. Please remember to close this stream subscription
  /// when you are done to avoid memory leaks.
  Stream<LanguageCodes> get stream => _streamController.stream;
  final StreamController<LanguageCodes> _streamController =
      StreamController.broadcast();

  /// Print debug log
  bool get isDebug => _isDebug;
  bool _isDebug = false;

  /// Language code preferences key
  @visibleForTesting
  String get codeKey => _autoSaveCodeKey;

  /// Language code preferences key
  String get _autoSaveCodeKey => '$prefix.AutoSaveCode';

  /// Language code of the device
  @visibleForTesting
  String get deviceCodeKey => _deviceCodeKey;

  /// Language code of the device
  String get _deviceCodeKey => '$prefix.DeviceCode';

  /// Initialize the plugin with the List of [data] that you have created,
  /// you can set the [initialCode] for this app or it will get the first
  /// language in [data], so **[data] must be not empty**. You can also set
  /// the [forceRebuild] to `true` if you want to rebuild all the [LanguageBuilder]
  /// widgets, not only the root widget (it will decreases the performance of the app).
  /// The [onChanged] callback will be called when the language is changed.
  /// Set the [isDebug] to `true` to show debug log.
  ///
  /// [analysisKeys] is the List of keys of the [LanguageData]. This data will
  /// be used by [analyze] to get the missing text of the specified language.
  ///
  /// [useInitialCodeWhenUnavailable] : If `true`, when you change the [LanguageCodes] by
  /// using [change] method, the app will change to the [initialCode] if
  /// the new code is unavailable. If `false`, the app will use keep using the last code.
  ///
  /// The plugin also supports auto save the [LanguageCodes] when changed and
  /// reload it from memory in the next opening.
  Future<void> initial({
    /// Data of languages. The [data] must be not empty.
    required Iterable<LanguageDataProvider> data,

    /// Data of the languages that you want to override the [data]. This feature
    /// will helpful when you want to change just some translations of the language
    /// that are already available in the [data].
    ///
    /// Common case is that you're using the generated [languageData] as your [data]
    /// but you want to change some translations (mostly with [LanguageConditions]).
    Iterable<LanguageDataProvider> dataOverrides = const [
      LanguageDataProvider.empty()
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
    assert(data.isNotEmpty, 'Data must be not empty');

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

    LanguageCodes finalCode = _initialCode ?? LanguageCode.code;

    _dataProvider = await _chooseTheBestDataProvider(_dataProviders, false);
    _dataOverridesProvider =
        await _chooseTheBestDataProvider(_dataOverridesProviders, true);

    _codes = await _getSupportedCode(
      provider: _dataProvider,
      isOverrides: false,
    );
    _codesOverrides = await _getSupportedCode(
      provider: _dataOverridesProvider,
      isOverrides: true,
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
            'Sync with device saved the current language to local database.');
      } else {
        // We only consider to change the app language when the device language
        // is changed. So it will not affect the app language that is set by the user.
        final prefCode = LanguageCodes.fromCode(prefCodeCode);
        if (currentCode != prefCode) {
          finalCode = currentCode;
          prefs.setString(_deviceCodeKey, currentCode.code);
          printDebug('Sync with device applied the new device language');
        } else {
          printDebug('Sync with device used the current app language');
        }
      }
    }

    if (!codesBoth.contains(finalCode)) {
      LanguageCodes? tempCode;
      if (isOptionalCountryCode && finalCode.locale.countryCode != null) {
        // Try to use the `languageCode` only if the `languageCode_countryCode`
        // is not available
        printDebug(
            'language does not contain the $finalCode => Try to use the `languageCode` only..');
        try {
          tempCode = LanguageCodes.fromCode(finalCode.locale.languageCode);
          if (!codesBoth.contains(tempCode)) {
            tempCode = null;
          }
        } catch (_) {}
      }

      if (tempCode == null) {
        printDebug(
            'Unable to use the `languageCode` only => Change the code to ${codes.first}');
      } else {
        printDebug(
            'Able to use the `languageCode` only => Change the code to $tempCode');
      }

      finalCode = tempCode ?? codes.first;
    }

    printDebug('Set `currentCode` to $finalCode');
    _currentCode = finalCode;

    _data.addAll(await _getData(
      provider: _dataProvider,
      code: code,
      isOverrides: false,
    ));
    _dataOverrides.addAll(await _getData(
      provider: _dataOverridesProvider,
      code: code,
      isOverrides: true,
    ));

    if (_isDebug) {
      analyze();
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
    _saveData(isOverrides: false);
    _saveSupportedCodes(isOverrides: false);
    if (activate) change(code);
    printDebug(
        'The new `data` is added and activated with overwrite is $overwrite');
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
    _saveData(isOverrides: true);
    _saveSupportedCodes(isOverrides: true);
    if (activate) change(code);
    printDebug(
        'The new `dataOverrides` is added and activated with overwrite is $overwrite');
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
          'Cannot translate this text because $toCode is not available in `data` and `dataOverrides` ($text)');
      return _replaceParams(text, stringParams);
    }

    final translated = _dataOverrides[toCode]?[text] ?? _data[toCode]![text];
    if (translated == null) {
      printDebug('This text is not contained in current $toCode ($text)');
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
    if (!codesBoth.contains(toCode)) {
      printDebug('$toCode is not available in `data` or `dataOverrides`');

      if (!_useInitialCodeWhenUnavailable) {
        printDebug(
            'Does not allow using the initial code => Cannot change the language.');
        return;
      } else {
        if (codesBoth.contains(_initialCode)) {
          printDebug(
              '`useInitialCodeWhenUnavailable` is true => Change the language to $_initialCode');
          _currentCode = _initialCode;
        } else {
          printDebug(
              '`useInitialCodeWhenUnavailable` is true but the `initialCode` is not available in `data` or `dataOverrides` => Cannot change the language');
          return;
        }
      }
    } else {
      printDebug('Set currentCode to $toCode');
      _currentCode = toCode;
    }

    _dataProvider = await _chooseTheBestDataProvider(_dataProviders, false);
    _dataOverridesProvider =
        await _chooseTheBestDataProvider(_dataOverridesProviders, true);

    if (!_data.containsKey(_currentCode)) {
      _data.clear();
      _dataOverrides.clear();
      _data.addAll(await _getData(
        provider: _dataProvider,
        code: code,
        isOverrides: false,
      ));
      _dataOverrides.addAll(await _getData(
        provider: _dataOverridesProvider,
        code: code,
        isOverrides: true,
      ));
    }

    printDebug('Change language to $toCode for ${_states.length} states');
    for (var state in _states) {
      state.updateLanguage();
    }

    _streamController.sink.add(toCode);
    if (_onChanged != null) {
      _onChanged!(toCode);
    }

    // Save to local memory
    if (_isAutoSave) {
      printDebug('Save this $toCode to local memory');
      SharedPreferences.getInstance().then((pref) {
        pref.setString(_autoSaveCodeKey, toCode.code);
      });
    }

    printDebug('Changing completed!');
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
          'The below keys were missing ([analysisKeys]: yes, [data]: no):\n');
      for (final key in missedKeys) {
        buffer.write('  >> ${_removeNewline(key)}\n');
      }
      buffer.write('\n');
    }

    if (removedKeys.isNotEmpty) {
      buffer.write(
          'The below keys were deprecated ([analysisKeys]: no, [data]: yes):\n');
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

    printDebug(buffer.toString());

    return buffer.toString();
  }

  Future<LanguageDataProvider> _chooseTheBestDataProvider(
    Iterable<LanguageDataProvider> providers,
    bool isOverrides,
  ) async {
    LanguageDataProvider? result;
    for (final provider in providers) {
      Set<LanguageCodes> codes = await _getSupportedCode(
        provider: provider,
        isOverrides: isOverrides,
      );

      if (codes.isNotEmpty) {
        result = provider;
        break;
      }
    }

    return result ?? LanguageDataProvider.data({});
  }

  Future<Set<LanguageCodes>> _getSupportedCode({
    required LanguageDataProvider provider,
    required bool isOverrides,
  }) async {
    final p = '$prefix.${isOverrides ? 'DataOverrides' : 'Data'}';

    var codes = await provider.getSupportedCodes();
    if (codes.isEmpty) {
      codes = await LanguageDataProvider.getSavedCodes(p);
    } else {
      LanguageDataProvider.saveCodes(p, codes);
    }

    return codes;
  }

  Future<void> _saveSupportedCodes({required bool isOverrides}) async {
    final p = '$prefix.${isOverrides ? 'DataOverrides' : 'Data'}';
    LanguageDataProvider.saveCodes(p, codesBoth);
  }

  Future<LanguageData> _getData({
    required LanguageDataProvider provider,
    required LanguageCodes code,
    required bool isOverrides,
  }) async {
    final p = '$prefix.${isOverrides ? 'DataOverrides' : 'Data'}';

    var data = await provider.getData(code);
    if (data.isEmpty) {
      data = await LanguageDataProvider.getSavedData(code, p);
    } else {
      LanguageDataProvider.saveData(code, p, data);
    }

    return data;
  }

  Future<void> _saveData({required bool isOverrides}) async {
    final p = '$prefix.${isOverrides ? 'DataOverrides' : 'Data'}';
    LanguageDataProvider.saveData(code, p, data);
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
          'The params does not contain the condition param: ${translateCondition.param}');
      return _replaceParams(fallback, params);
    }

    final param = params[translateCondition.param];
    final conditions = translateCondition.conditions;
    final translated =
        conditions[param] ?? conditions['default'] ?? conditions['_'];

    if (translated == null) {
      printDebug(
          'There is no result for key $param of condition ${translateCondition.param}');
      return _replaceParams(fallback, params);
    }

    return _replaceParams(translated, params);
  }

  String _removeNewline(String text) {
    return text.replaceAll('\n', ' ⏎ ');
  }
}
