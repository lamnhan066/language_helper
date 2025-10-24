import '../../language_helper.dart';

/// Data for the [LanguageHelper].
typedef LanguageData = Map<LanguageCodes, Map<String, dynamic>>;

/// Lazy data for the [LanguageHelper].
typedef LazyLanguageData = Map<LanguageCodes, Map<String, dynamic> Function()>;
