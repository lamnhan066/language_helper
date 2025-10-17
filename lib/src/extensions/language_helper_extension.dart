import '../../language_helper.dart';

extension LanguageHelperEx on String {
  /// Translate the current text wih default parameters.
  String get tr => LanguageHelper.instance.translate(this);

  /// Translate with only [params] parammeter
  /// ``` dart
  /// final text = 'result is @{param}'.trP({'param' : 'zero'});
  /// print(text); // -> 'result is zero'
  /// ```
  String trP(Map<String, dynamic> params) {
    return LanguageHelper.instance.translate(this, params: params);
  }

  /// Translate with only [toCode] parammeter
  /// ``` dart
  /// final text = 'result is something'.trT(LanguageCodes.en);
  /// ```
  String trT(LanguageCodes toCode) {
    return LanguageHelper.instance.translate(this, toCode: toCode);
  }

  /// Full version of the translation, includes all parameters.
  String trF({Map<String, dynamic> params = const {}, LanguageCodes? toCode}) {
    return LanguageHelper.instance.translate(
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
