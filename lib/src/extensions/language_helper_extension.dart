import '../../language_helper.dart';
import '../language_helper.dart' show LanguageHelperScope, LanguageHelper;

extension LanguageHelperEx on String {
  /// Translate the current text wih default parameters.
  ///
  /// If called within a [LanguageBuilder] that uses a scoped [LanguageHelper]
  /// (from [LanguageScope]), that helper will be used. Otherwise, falls back
  /// to [LanguageHelper.instance].
  String get tr {
    final scope = LanguageHelperScope().current;
    return (scope ?? LanguageHelper.instance).translate(this);
  }

  /// Translate with only [params] parammeter
  ///
  /// If called within a [LanguageBuilder] that uses a scoped [LanguageHelper]
  /// (from [LanguageScope]), that helper will be used. Otherwise, falls back
  /// to [LanguageHelper.instance].
  /// ``` dart
  /// final text = 'result is @{param}'.trP({'param' : 'zero'});
  /// print(text); // -> 'result is zero'
  /// ```
  String trP(Map<String, dynamic> params) {
    final scope = LanguageHelperScope().current;
    return (scope ?? LanguageHelper.instance).translate(this, params: params);
  }

  /// Translate with only [toCode] parammeter
  ///
  /// If called within a [LanguageBuilder] that uses a scoped [LanguageHelper]
  /// (from [LanguageScope]), that helper will be used. Otherwise, falls back
  /// to [LanguageHelper.instance].
  /// ``` dart
  /// final text = 'result is something'.trT(LanguageCodes.en);
  /// ```
  String trT(LanguageCodes toCode) {
    final scope = LanguageHelperScope().current;
    return (scope ?? LanguageHelper.instance).translate(this, toCode: toCode);
  }

  /// Full version of the translation, includes all parameters.
  ///
  /// If called within a [LanguageBuilder] that uses a scoped [LanguageHelper]
  /// (from [LanguageScope]), that helper will be used. Otherwise, falls back
  /// to [LanguageHelper.instance].
  String trF({Map<String, dynamic> params = const {}, LanguageCodes? toCode}) {
    final scope = LanguageHelperScope().current;
    return (scope ?? LanguageHelper.instance).translate(
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
