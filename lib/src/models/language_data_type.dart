import '../../language_helper.dart';

/// Translation data structure for [LanguageHelper].
///
/// This type represents the core data structure for storing translations.
/// It's a map where:
/// - **Keys**: [LanguageCodes] representing the target language
/// - **Values**: Maps of translation keys to their translated values
///
/// Translation values can be:
/// - `String` - Simple translation text
/// - [LanguageConditions] - Conditional translations based on parameter values
///
/// Example:
/// ```dart
/// LanguageData data = {
///   LanguageCodes.en: {
///     'Hello': 'Hello',
///     'Count': LanguageConditions(
///       param: 'count',
///       conditions: {'1': 'one', '_': 'many'},
///     ),
///   },
///   LanguageCodes.vi: {
///     'Hello': 'Xin chào',
///     'Count': LanguageConditions(
///       param: 'count',
///       conditions: {'1': 'một', '_': 'nhiều'},
///     ),
///   },
/// };
/// ```
typedef LanguageData = Map<LanguageCodes, Map<String, dynamic>>;

/// Lazy-loaded translation data structure for [LanguageHelper].
///
/// Similar to [LanguageData], but with lazy evaluation. Each language's
/// translations are provided as a function that's called only when needed.
///
/// This is useful for:
/// - Large translation datasets that shouldn't all be loaded at once
/// - Performance optimization by deferring data loading
/// - Conditional loading based on app state or user preferences
///
/// The functions are called when translations are requested for a specific
/// language code, allowing on-demand loading.
///
/// Example:
/// ```dart
/// LazyLanguageData lazyData = {
///   LanguageCodes.en: () => loadEnglishTranslations(), // Called when LanguageCodes.en is used
///   LanguageCodes.vi: () => loadVietnameseTranslations(),
/// };
///
/// // Use with LanguageDataProvider
/// final provider = LanguageDataProvider.lazyData(lazyData);
/// ```
typedef LazyLanguageData = Map<LanguageCodes, Map<String, dynamic> Function()>;
