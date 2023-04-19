part of '../language_helper.dart';

/// Make it easier for you to control multiple languages in your app
class LanguageHelper {
  // Get LanguageHelper instance
  static LanguageHelper instance = LanguageHelper._();

  /// To control [LanguageBuilder]
  final List<UpdateLanguage> _states = [];

  /// Private instance
  LanguageHelper._();

  /// Get all languages
  LanguageData _data = {};

  /// List of all the keys of text in your project.
  ///
  /// You can maintain it by yourself or using [language_helper_generator](https://pub.dev/packages/language_helper_generator).
  /// This value will be used by `analyze` method to let you know that which
  /// text is missing in your language data.
  Iterable<String> _analysisKeys = const [];

  /// Get list of [LanguageCodes]
  List<LanguageCodes> get codes => _data.keys.toList();

  /// Get list of language as [Locale]
  List<Locale> get locales => _data.keys.map((e) => e.locale).toList();

  /// Get current language as [LanguageCodes]
  ///
  /// You must be `await initial()` before using this variable.
  LanguageCodes get code => _currentCode!;

  /// Get current code
  @Deprecated('Use [code] insteads')
  LanguageCodes? get currentCode => _currentCode;
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
  bool _isDebug = false;

  /// Language code preferences key
  final _codeKey = 'LanguageHelper.AutoSaveCode';

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
    required LanguageData data,

    /// List of all the keys of text in your project.
    ///
    /// You can maintain it by yourself or using [language_helper_generator](https://pub.dev/packages/language_helper_generator).
    /// This value will be used by `analyze` method to let you know that which
    /// text is missing in your language data.
    Iterable<String> analysisKeys = const [],

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

    /// Callback on language changed.
    void Function(LanguageCodes code)? onChanged,

    /// Print the debug log.
    bool isDebug = false,
  }) async {
    assert(data.isNotEmpty, 'Data must be not empty');

    _data = data;
    _forceRebuild = forceRebuild;
    _onChanged = onChanged;
    _isDebug = isDebug;
    _useInitialCodeWhenUnavailable = useInitialCodeWhenUnavailable;
    _isAutoSave = isAutoSave;
    _analysisKeys = analysisKeys;

    // Try to reload from memory if `isAutoSave` is `true`
    if (_isAutoSave) {
      final prefs = await SharedPreferences.getInstance();

      if (prefs.containsKey(_codeKey)) {
        final code = prefs.getString(_codeKey);

        if (code != null && code.isNotEmpty) {
          initialCode = LanguageCodes.fromCode(code);
        }
      }
    }

    if (initialCode == null) {
      // Try to set by the default code from device
      final currentCode = LanguageCode.code;
      if (data.containsKey(currentCode)) {
        _initialCode = currentCode;
        _print('Set current language code to $_initialCode by device locale');
      } else if (data.isNotEmpty) {
        _initialCode = data.keys.first;
        _print('Set current language code to $_initialCode');
      }
    } else {
      _initialCode = initialCode;
    }

    if (data.containsKey(_initialCode)) {
      _print('Set currentCode to $_initialCode');
      _currentCode = _initialCode!;
    } else {
      _currentCode = data.keys.first;
      _print(
          'language does not contain the $_initialCode => Change the code to $_currentCode');
    }

    if (_isDebug) {
      analyze();
    }
  }

  @visibleForTesting
  void changeData(LanguageData newData) {
    _data = newData;
  }

  /// Dispose all the controllers
  void dispose() {
    _streamController.close();
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

    if (!codes.contains(toCode)) {
      _print(
          'Cannot translate this text because $toCode is not available in `data` ($text)');
      return _replaceParams(text, stringParams);
    }

    final translated = _data[toCode]![text];
    if (translated == null) {
      _print('This text is not contained in current $toCode ($text)');
      return _replaceParams(text, stringParams);
    }

    if (translated is LanguageCondition) {
      return _replaceParamsCondition(translated, stringParams, text);
    }

    return _replaceParams(translated, stringParams);
  }

  /// Change the language to this [code]
  void change(LanguageCodes toCode) {
    if (!codes.contains(toCode)) {
      _print(
          'Cannot translate this text because $toCode is not available in `data`');

      if (!_useInitialCodeWhenUnavailable) {
        _print('Does not allow using initial code => Cannot change language.');
        return;
      }
    }

    _print('Set currentCode to $toCode');
    _currentCode = toCode;

    _print('Change language to $toCode for ${_states.length} states');
    for (var state in _states) {
      state.updateLanguage();
    }

    _streamController.sink.add(toCode);
    if (_onChanged != null) {
      _onChanged!(toCode);
    }

    // Save to local memory
    if (_isAutoSave) {
      _print('Save this $toCode to local memory');
      SharedPreferences.getInstance().then((pref) {
        pref.setString(_codeKey, toCode.code);
      });
    }

    _print('Changing completed!');
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
  void analyze() {
    final List<String> keys = [];

    _print('\n');
    _print('==================================================');
    _print('\n');
    _print('Analyze all languages...');
    _print('\n');

    // Add all keys to [keys]
    for (final code in codes) {
      for (final key in _data[code]!.keys) {
        if (!keys.contains(key)) keys.add(key);
      }
    }

    final List<String> removedKeys = [];
    final List<String> missingKeys = [];
    if (_analysisKeys.isNotEmpty) {
      // Analyze which keys are in [analysisKeys] but not in [data].
      for (final key in _analysisKeys) {
        if (!keys.contains(key)) {
          removedKeys.add(key);
        }
      }

      // Analyze which keys are in [data] but not in [analysisKeys]
      for (final key in keys) {
        if (!_analysisKeys.contains(key)) {
          missingKeys.add(key);
        }
      }
    }

    if (removedKeys.isNotEmpty) {
      _print('The below keys were missing ([analysisKeys]: yes, [data]: no):');
      for (final key in removedKeys) {
        _print('    $key');
      }
      _print('\n');
    }

    if (missingKeys.isNotEmpty) {
      _print(
          'The below keys were deprecated ([analysisKeys]: no, [data]: yes):');
      for (final key in missingKeys) {
        _print('    $key');
      }
      _print('\n');
    }

    _print('Specific text missing results:\n');

    // Analyze the results
    for (final code in codes) {
      _print('  $code:\n');
      for (final key in keys) {
        if (!_data[code]!.keys.contains(key)) {
          _print('    $key\n');
        }
      }
      _print('\n');
    }

    _print('==================================================');
    _print('\n');
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

  /// Replace @{param} or @param with the real text with [LanguageCondition]
  String _replaceParamsCondition(
    LanguageCondition translateCondition,
    Map<String, dynamic> params,
    String fallback,
  ) {
    if (!params.containsKey(translateCondition.param)) {
      _print(
          'The params does not contain the condition param: ${translateCondition.param}');
      return _replaceParams(fallback, params);
    }

    final param = params[translateCondition.param];
    final conditions = translateCondition.conditions;
    final translated = conditions[param] ?? conditions['default'];

    if (translated == null) {
      _print(
          'There is no result for key $param of condition ${translateCondition.param}');
      return _replaceParams(fallback, params);
    }

    return _replaceParams(translated, params);
  }

  /// Internal function, print debug log
  void _print(Object? object) =>
      // ignore: avoid_print
      _isDebug ? debugPrint('[Language Helper] $object') : null;
}
