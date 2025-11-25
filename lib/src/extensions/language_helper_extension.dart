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
  /// **Note:** The [toCode] parameter only works reliably when using `LanguageData`.
  /// If you are using `LazyLanguageData`, the data for [toCode] may not yet be loaded,
  /// so the translation may not be available unless it has already been fetched.
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

  /// Translates with a custom instance of [LanguageHelper].
  ///
  /// Unlike other extension methods (`tr`, `trP`, etc.), this method requires you to
  /// explicitly pass a [LanguageHelper] instance. This is useful when you want to use
  /// a specific helper outside of a [LanguageBuilder] context.
  ///
  /// This method is always available and does not rely on the helper stack or
  /// [LanguageScope]. It uses the provided [helper] directly.
  ///
  /// Example:
  /// ```dart
  /// final customHelper = LanguageHelper('CustomHelper');
  /// await customHelper.initial(data: myData);
  ///
  /// // Use trC outside of LanguageBuilder
  /// final text = 'Hello'.trC(customHelper);
  ///
  /// // With parameters
  /// final text2 = 'Welcome @{name}'.trC(
  ///   customHelper,
  ///   params: {'name': 'John'},
  /// );
  ///
  /// // Translate to specific language
  /// final text3 = 'Hello'.trC(customHelper, toCode: LanguageCodes.es);
  /// ```
  String trC(
    LanguageHelper helper, {
    Map<String, dynamic> params = const {},
    LanguageCodes? toCode,
  }) {
    return helper.translate(this, params: params, toCode: toCode);
  }
}
