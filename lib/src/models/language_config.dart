import 'package:language_code/language_code.dart';

/// Configuration used to initialize a LanguageHelper.
class LanguageConfig {
  /// Creates a configuration for LanguageHelper.initial.
  const LanguageConfig({
    this.initialCode,
    this.useInitialCodeWhenUnavailable = false,
    this.forceRebuild = true,
    this.isAutoSave = true,
    this.syncWithDevice = true,
    this.isOptionalCountryCode = true,
    this.onChanged,
    this.isDebug = false,
  });

  /// Initial language code. Falls back to device language or first provider
  /// language if null.
  final LanguageCodes? initialCode;

  /// Use [initialCode] as fallback when changing to unavailable languages.
  final bool useInitialCodeWhenUnavailable;

  /// Default forceRebuild value for all LanguageBuilder widgets.
  final bool forceRebuild;

  /// Automatically save/restore language preference to SharedPreferences.
  final bool isAutoSave;

  /// Update app language when device language changes.
  final bool syncWithDevice;

  /// Fall back to language code only when full locale (e.g., `zh_CN`) is
  /// unavailable.
  final bool isOptionalCountryCode;

  /// Callback invoked when language changes.
  final void Function(LanguageCodes code)? onChanged;

  /// Enable debug logging. Defaults to false.
  final bool isDebug;
}
