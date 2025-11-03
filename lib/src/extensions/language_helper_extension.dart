part of '../language_helper.dart';

extension LanguageHelperEx on String {
  /// Translates the current text with default parameters.
  ///
  /// This extension method uses the helper from the current build context:
  /// - If called within a [LanguageBuilder], it uses the helper associated with
  ///   that builder (which may come from a [LanguageScope]).
  /// - Otherwise, falls back to [LanguageHelper.instance].
  ///
  /// Note: Extension methods only work with scoped helpers when called within a
  /// [LanguageBuilder], because that's when the helper is pushed onto the stack.
  ///
  /// Example:
  /// ```dart
  /// LanguageBuilder(
  ///   builder: (context) => Text('Hello'.tr), // Uses scoped or instance helper
  /// )
  /// ```
  String get tr {
    return LanguageHelper._current.translate(this);
  }

  /// Translates with only the [params] parameter.
  ///
  /// This extension method uses the helper from the current build context:
  /// - If called within a [LanguageBuilder], it uses the helper associated with
  ///   that builder (which may come from a [LanguageScope]).
  /// - Otherwise, falls back to [LanguageHelper.instance].
  ///
  /// Example:
  /// ```dart
  /// final text = 'result is @{param}'.trP({'param': 'zero'});
  /// print(text); // -> 'result is zero'
  /// ```
  String trP(Map<String, dynamic> params) {
    return LanguageHelper._current.translate(this, params: params);
  }

  /// Translates to a specific [LanguageCodes] instead of the current language.
  ///
  /// This extension method uses the helper from the current build context:
  /// - If called within a [LanguageBuilder], it uses the helper associated with
  ///   that builder (which may come from a [LanguageScope]).
  /// - Otherwise, falls back to [LanguageHelper.instance].
  ///
  /// Example:
  /// ```dart
  /// final text = 'Hello'.trT(LanguageCodes.en); // Translates to English
  /// ```
  String trT(LanguageCodes toCode) {
    return LanguageHelper._current.translate(this, toCode: toCode);
  }

  /// Full version of the translation with all parameters.
  ///
  /// This extension method uses the helper from the current build context:
  /// - If called within a [LanguageBuilder], it uses the helper associated with
  ///   that builder (which may come from a [LanguageScope]).
  /// - Otherwise, falls back to [LanguageHelper.instance].
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

  /// Translate with custom instance of `LanguageHelper`.
  String trC(
    LanguageHelper helper, {
    Map<String, dynamic> params = const {},
    LanguageCodes? toCode,
  }) {
    return helper.translate(this, params: params, toCode: toCode);
  }
}
