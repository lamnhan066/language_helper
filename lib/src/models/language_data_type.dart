import 'package:language_helper/language_helper.dart';

/// Translation data structure: map of [LanguageCodes] to translation maps.
/// Values can be `String` or [LanguageConditions] for conditional translations.
typedef LanguageData = Map<LanguageCodes, Map<String, dynamic>>;

/// Lazy-loaded translation data: map of [LanguageCodes] to functions that
/// return translation maps. Functions are called only when translations are
/// requested for a specific language code.
typedef LazyLanguageData = Map<LanguageCodes, Map<String, dynamic> Function()>;
