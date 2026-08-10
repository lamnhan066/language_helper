import 'package:language_helper/language_helper.dart';

/// Configuration used to initialize a LanguageHelper.
class LanguageConfig {
  /// Creates a configuration for LanguageHelper.initial.
  const LanguageConfig({
    this.initialCode,
    bool fallbackToInitialCode = true,
    @Deprecated('Use fallbackToInitialCode instead.')
    bool? useInitialCodeWhenUnavailable,
    this.forceRebuild = true,
    this.isAutoSave = true,
    this.syncWithDevice = true,
    @Deprecated(
      'isOptionalCountryCode is always true. If you want to change fallback '
      'behavior, create a custom `resolveFallbackCode` callback instead.',
    )
    this.isOptionalCountryCode = true,
    this.onChanged,
    this.resolveFallbackCode = defaultFallbackCodeResolver,
    this.isDebug = false,
  }) : fallbackToInitialCode =
           useInitialCodeWhenUnavailable ?? fallbackToInitialCode;

  /// Initial language code. Falls back to device language or first provider
  /// language if null.
  final LanguageCodes? initialCode;

  /// Use [initialCode] as fallback when changing to unavailable languages.
  /// When `true`, falls back to `initialCode` if available. When `false`, the
  /// change is silently ignored.
  final bool fallbackToInitialCode;

  /// Default forceRebuild value for all LanguageBuilder widgets.
  final bool forceRebuild;

  /// Automatically save/restore language preference to SharedPreferences.
  final bool isAutoSave;

  /// Update app language when device language changes.
  final bool syncWithDevice;

  @Deprecated(
    'isOptionalCountryCode is always true. If you want to change fallback '
    'behavior, create a custom `resolveFallbackCode` callback instead.',
  )
  /// Fall back to language code only when full locale (e.g., `zh_CN`) is
  /// unavailable. This field is deprecated and always true.
  final bool isOptionalCountryCode;

  /// Callback invoked when language changes.
  final void Function(LanguageCodes code)? onChanged;

  /// When change fails due to unavailable language, callback receives the
  /// helper and the code that was attempted. Returns a fallback code or null.
  /// The default resolver tries to find a matching language-only code first,
  /// then falls back to `initialCode` if `fallbackToInitialCode` is true.
  final LanguageCodes? Function(LanguageHelper helper, LanguageCodes code)?
  resolveFallbackCode;

  /// Enable debug logging. Defaults to false.
  final bool isDebug;
}
