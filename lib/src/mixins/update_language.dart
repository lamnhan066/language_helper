import 'package:language_helper/language_helper.dart'
    show LanguageBuilder, LanguageHelper;
import 'package:language_helper/src/language_helper.dart'
    show LanguageBuilder, LanguageHelper;

/// Mixin that provides a contract for widgets that need to update when the
/// language changes.
///
/// Used internally by [LanguageBuilder] to register widgets with
/// [LanguageHelper] and trigger rebuilds when [LanguageHelper.change] is
/// called. The [updateLanguage] method is invoked by [LanguageHelper] to
/// notify registered widgets of language changes.
///
/// **Implementation:**
/// - Override [updateLanguage] to perform the update (typically calling
///   `setState`).
/// - Widgets using this mixin are automatically registered with
///   [LanguageHelper] and will receive update notifications.
///
/// **Example:**
/// ```dart
/// class MyLanguageWidget extends StatefulWidget {
///   @override
///   State<MyLanguageWidget> createState() => _MyLanguageWidgetState();
/// }
///
/// class _MyLanguageWidgetState extends State<MyLanguageWidget>
///     with UpdateLanguage {
///   @override
///   void updateLanguage() {
///     if (mounted) {
///       setState(() {
///         // Trigger rebuild when language changes
///       });
///     }
///   }
/// }
/// ```
mixin UpdateLanguage {
  /// Called by [LanguageHelper] when the language changes. Override this method
  /// to handle the update (typically by calling `setState` to trigger
  /// a rebuild).
  ///
  /// **Important:** Always check `mounted` before calling `setState` in Flutter
  /// widgets to avoid calling setState on a disposed widget.
  void updateLanguage() {}
}
