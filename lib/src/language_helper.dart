part of '../language_helper.dart';

/// Make it easier for you to control multiple languages in your app
class LanguageHelper {
  // Get LanguageHelper instance
  static LanguageHelper instance = LanguageHelper._();

  /// To control [LanguageNotifier]
  final List<_LanguageNotifierState> _states = [];

  /// Private instance
  LanguageHelper._();

  /// Get all languages
  LanguageData _data = {};

  /// Get list of [LanguageCodes]
  List<LanguageCodes> get codes => _data.keys.toList();

  /// Get current code
  LanguageCodes? get currentCode => _currentCode;
  LanguageCodes? _currentCode;

  /// Initial code
  LanguageCodes? _initialCode;

  /// When you change the [LanguageCodes] by using [change] method, the app will
  /// change to the [initialCode] if the code is unavailable. If not, the app
  /// will use keep using the last code.
  bool _useInitialCodeWhenUnavailable = false;

  /// Force rebuilds all widgets instead of only root widget. You can try to use
  /// this value if the widgets don't rebuild as your wish.
  bool _forceRebuild = false;

  Function(LanguageCodes code)? _onChanged;

  /// Print debug log
  bool _isDebug = false;

  /// Initialize the plugin with the List of [data] that you have created,
  /// you can set the [initialCode] for this app or it will get the first
  /// language in [data]. You can also set the [forceRebuild] to `true` if
  /// you want to rebuild all the [LanguageNotifier] widgets, not only the
  /// root widget (it will decreases the performance of the app).
  /// The [onChanged] callback will be called when the language is changed.
  /// Set the [isDebug] to `true` to show debug log.
  ///
  /// [useInitialCodeWhenUnavailable]: If `true`, when you change the [LanguageCodes] by
  /// using [change] method, the app will change to the [initialCode] if
  /// the new code is unavailable. If `false`, the app will use keep using the last code.
  Future<void> initial({
    required LanguageData data,
    LanguageCodes? initialCode,
    bool useInitialCodeWhenUnavailable = false,
    bool forceRebuild = false,
    Function(LanguageCodes code)? onChanged,
    bool isDebug = false,
  }) async {
    _data = data;
    _forceRebuild = forceRebuild;
    _onChanged = onChanged;
    _isDebug = isDebug;
    _initialCode = initialCode;
    _useInitialCodeWhenUnavailable = useInitialCodeWhenUnavailable;

    if (initialCode == null) {
      // Try to set by the default code from device
      final locale = await Devicelocale.currentAsLocale;
      if (locale != null) {
        _initialCode = LanguageCodes.fromLocale(locale);
        _print('Set current language code to $_initialCode by device locale');
      } else if (data.isNotEmpty) {
        _initialCode = data.keys.first;
        _print('Set current language code to $_initialCode');
      } else {
        _print('languages is empty => cannot set currentCode');
      }
    } else {
      _initialCode = initialCode;
    }

    if (data.containsKey(_initialCode)) {
      _print('Set currentCode to $_initialCode');
      _currentCode = _initialCode;
    } else {
      _print(
          'language does not contain the $_initialCode => Cannot set currentCode');
      _initialCode = null;
    }

    if (_isDebug) {
      analyze();
    }
  }

  /// Translate this [text] to the destination language
  String translate(String text, {Map<String, dynamic> params = const {}}) {
    if (_currentCode == null) {
      _print(
          'Cannot translate this text because the currentLanguage is not set ($text)');
      return _replaceParams(text, params);
    }

    final translated = _data[_currentCode]![text];
    if (translated == null) {
      _print('This text is not contained in current language ($text)');
      return _replaceParams(text, params);
    }

    return _replaceParams(translated, params);
  }

  /// Change the [currentCode] to this [code]
  void change(LanguageCodes code) {
    if (_data.containsKey(code)) {
      _print('Set currentCode to $code');
      _currentCode = code;
    } else {
      if (_initialCode != null && _useInitialCodeWhenUnavailable) {
        _print('language does not contain the code => Use the initialCode');
        _currentCode = _initialCode;
      } else {
        _print('language does not contain the code => Cannot set currentCode');
      }
      return;
    }

    _print('Change language to $code for ${_states.length} states');
    for (var state in _states) {
      state._updateLanguage();
    }

    if (_onChanged != null) {
      _onChanged!(code);
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
    _print('Analyze all languages to find the missing texts...');

    // Add all keys to [keys]
    for (final code in codes) {
      for (final key in _data[code]!.keys) {
        if (!keys.contains(key)) keys.add(key);
      }
    }

    _print('Results:\n');

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
  String _replaceParams(String input, Map<String, dynamic> params) {
    if (params.isEmpty) return input;

    params.forEach((key, value) {
      // @param and end with space, end of line, new line.
      input = input.replaceAll('@{$key}', '$value');
      input = input.replaceAll(RegExp('@$key(?=\\s|\$|\\n)'), '$value');
    });

    return input;
  }

  /// Internal function, print debug log
  void _print(Object? object) =>
      // ignore: avoid_print
      _isDebug ? debugPrint('[Language Helper] $object') : null;
}
