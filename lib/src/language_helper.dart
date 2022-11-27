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
  void initial({
    required LanguageData data,
    LanguageCodes? initialCode,
    bool forceRebuild = false,
    Function(LanguageCodes code)? onChanged,
    bool isDebug = false,
  }) {
    _data = data;
    _forceRebuild = forceRebuild;
    _onChanged = onChanged;
    _isDebug = isDebug;

    if (initialCode == null) {
      if (data.isNotEmpty) {
        _currentCode = data.keys.first;
        _print('Set current language code to $_currentCode');
      } else {
        _print('languages is empty => cannot set currentCode');
      }
    } else {
      if (data.containsKey(initialCode)) {
        _print('Set currentCode to $initialCode');
        _currentCode = initialCode;
      } else {
        _print(
            'language does not contain the $initialCode => Cannot set currentCode');
      }
    }

    if (_isDebug) {
      analyze();
    }
  }

  /// Translate this [text] to the destination language
  String translate(String text) {
    if (_currentCode == null) {
      _print(
          'Cannot translate this text because the currentLanguage is not set ($text)');
      return text;
    }

    final translated = _data[_currentCode]![text];
    if (translated == null) {
      _print('This text is not contained in current language ($text)');
      return text;
    }

    return translated;
  }

  /// Change the [currentCode] to this [code]
  void change(LanguageCodes code) {
    if (_data.containsKey(code)) {
      _print('Set currentCode to $code');
      _currentCode = code;
    } else {
      _print('language does not contain the code => Cannot set currentCode');

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

  /// Internal function, print debug log
  void _print(Object? object) =>
      // ignore: avoid_print
      _isDebug ? debugPrint('[Language Helper] $object') : null;
}
