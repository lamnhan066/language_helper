part of '../language_helper.dart';

/// Extension on [String] to translate text using the helper.
extension LanguageHelperEx on String {
  /// Translates text using the helper from current build context. Uses scoped
  /// helper within [LanguageBuilder], otherwise [LanguageHelper.instance].
  ///
  /// Example:
  /// ```dart
  /// LanguageBuilder(
  ///   builder: (context) => Text('Hello'.tr),
  /// )
  /// ```
  String get tr {
    return LanguageHelper._current.translate(this);
  }

  /// Translates with parameters. Uses scoped helper within [LanguageBuilder],
  /// otherwise [LanguageHelper.instance].
  ///
  /// Example:
  /// ```dart
  /// final text = 'result is @{param}'.trP({'param': 'zero'});
  /// print(text); // -> 'result is zero'
  /// ```
  String trP(Map<String, dynamic> params) {
    return LanguageHelper._current.translate(this, params: params);
  }

  /// Translates to [toCode] instead of current language. Uses scoped helper
  /// within [LanguageBuilder], otherwise [LanguageHelper.instance]. Only
  /// works reliably with `LanguageData`; `LazyLanguageData` may not be loaded
  /// yet.
  ///
  /// Example:
  /// ```dart
  /// final text = 'Hello'.trT(LanguageCodes.en); // Translates to English
  /// ```
  String trT(LanguageCodes toCode) {
    return LanguageHelper._current.translate(this, toCode: toCode);
  }

  /// Full translation with all parameters. Uses scoped helper within
  /// [LanguageBuilder], otherwise [LanguageHelper.instance].
  ///
  /// Example:
  /// ```dart
  /// final text = 'Welcome @{name}'.trF(
  ///   params: {'name': 'John'},
  ///   toCode: LanguageCodes.es,
  /// );
  /// ```
  String trF({Map<String, dynamic> params = const {}, LanguageCodes? toCode}) {
    return LanguageHelper._current.translate(
      this,
      params: params,
      toCode: toCode,
    );
  }

  /// Translates with a custom [LanguageHelper] instance. Always available,
  /// doesn't rely on helper stack or [LanguageScope].
  ///
  /// Example:
  /// ```dart
  /// final customHelper = LanguageHelper('CustomHelper');
  /// await customHelper.initial(
  ///   LanguageConfig(
  ///     data: myData,
  ///   ),
  /// );
  /// final text = 'Hello'.trC(customHelper);
  /// ```
  String trC(
    LanguageHelper helper, {
    Map<String, dynamic> params = const {},
    LanguageCodes? toCode,
  }) {
    return helper.translate(this, params: params, toCode: toCode);
  }
}
