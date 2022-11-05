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
  LanguageData data = {};

  /// Get list of [LanguageCodes]
  List<LanguageCodes> get codes => data.keys.toList();

  /// Get current code
  LanguageCodes? get currentCode => _currentCode;
  LanguageCodes? _currentCode;

  /// Print debug log
  bool _isDebug = false;

  /// Initialize the plugin with the List of [data] that you have created,
  /// you can set the [defaultCode] for this app or it will get the first
  /// language in [data]. Enable [isDebug] to show debug log.
  void initial({
    required LanguageData data,
    LanguageCodes? defaultCode,
    bool isDebug = false,
  }) {
    this.data = data;
    _isDebug = isDebug;

    if (defaultCode == null) {
      if (data.isNotEmpty) {
        _currentCode = data.keys.first;
        _print('Set current language code to $_currentCode');
      } else {
        _print('languages is empty => cannot set currentCode');
      }
    } else {
      if (data.containsKey(defaultCode)) {
        _print('Set currentCode to $defaultCode');
        _currentCode = defaultCode;
      } else {
        _print(
            'language does not contain the $defaultCode => Cannot set currentCode');
      }
    }
  }

  /// Translate this [text] to the destination language
  String translate(String text) {
    if (_currentCode == null) {
      _print(
          'Cannot translate this text because the currentLanguage is not set ($text)');
      return text;
    }

    final translated = data[_currentCode]![text];
    if (translated == null) {
      _print('This text is not contained in current language ($text)');
      return text;
    }

    return translated;
  }

  /// Change the [currentCode] to this [code]
  void change(LanguageCodes code) {
    if (data.containsKey(code)) {
      _print('Set currentCode to the code');
      _currentCode = code;
    } else {
      _print('language does not contain the code => Cannot set currentCode');
    }

    for (var state in _states) {
      _print('Change language to $code for $state');
      state._updateLanguage();
    }
  }

  /// Internal function, print debug log
  void _print(Object? object) =>
      // ignore: avoid_print
      _isDebug ? print('[Language Helper] $object') : null;
}
