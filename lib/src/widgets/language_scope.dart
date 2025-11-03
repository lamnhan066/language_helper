import 'package:flutter/material.dart';

import '../../language_helper.dart';

/// A widget that provides a scoped [LanguageHelper] instance to its descendants.
///
/// [LanguageScope] is an [InheritedWidget] that makes a [LanguageHelper] instance
/// available to descendants via the widget tree. This allows you to use different
/// language helpers in different parts of your app without explicitly passing them
/// to every widget.
///
/// When a [LanguageScope] is present in the widget tree:
/// - [LanguageBuilder] and [Tr] widgets automatically inherit the scoped helper
///   (unless an explicit `languageHelper` parameter is provided)
/// - Extension methods (`tr`, `trP`, `trT`, `trF`) use the scoped helper when
///   called within a [LanguageBuilder]
/// - You can access the scoped helper directly via [of] or [maybeOf]
///
/// Priority order when resolving which helper to use:
/// 1. Explicit `languageHelper` parameter (in [LanguageBuilder] or [Tr])
/// 2. [LanguageScope] from widget tree (via [maybeOf])
/// 3. [LanguageHelper.instance] (fallback)
///
/// Example:
/// ```dart
/// final customHelper = LanguageHelper('CustomHelper');
/// await customHelper.initial(
///   data: customLanguageData,
///   initialCode: LanguageCodes.es,
/// );
///
/// LanguageScope(
///   languageHelper: customHelper,
///   child: LanguageBuilder(
///     builder: (context) => Column(
///       children: [
///         Text('Hello'.tr), // Uses customHelper via stack
///         // Access helper directly
///         Builder(
///           builder: (context) {
///             final helper = LanguageScope.of(context);
///             return Text(helper.translate('World'));
///           },
///         ),
///       ],
///     ),
///   ),
/// )
/// ```
///
/// You can nest [LanguageScope] widgets - a child scope will override the parent
/// scope for its subtree.
class LanguageScope extends InheritedWidget {
  /// Creates a [LanguageScope] that provides a [LanguageHelper] to its descendants.
  ///
  /// The [languageHelper] must not be null.
  const LanguageScope({
    required this.languageHelper,
    required super.child,
    super.key,
  });

  /// The [LanguageHelper] instance provided by this scope.
  final LanguageHelper languageHelper;

  /// Returns the [LanguageHelper] from the nearest [LanguageScope] ancestor,
  /// or [LanguageHelper.instance] if no scope is found.
  ///
  /// This method registers a dependency on the [LanguageScope], meaning the widget
  /// will rebuild when the scope changes (if the [languageHelper] instance changes).
  ///
  /// This method should be used when you need to access the scoped [LanguageHelper]
  /// instance from a [BuildContext] and want to rebuild when it changes.
  ///
  /// Example:
  /// ```dart
  /// Builder(
  ///   builder: (context) {
  ///     final helper = LanguageScope.of(context);
  ///     return Text(helper.translate('Hello'));
  ///   },
  /// )
  /// ```
  ///
  /// For accessing the helper without registering a dependency (no rebuild on change),
  /// use [maybeOf] instead.
  static LanguageHelper of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LanguageScope>();
    return scope?.languageHelper ?? LanguageHelper.instance;
  }

  /// Returns the [LanguageHelper] from the nearest [LanguageScope] ancestor,
  /// or null if no scope is found.
  ///
  /// Unlike [of], this method does not register a dependency on the [LanguageScope],
  /// which means the widget will not rebuild when the scope changes. This is useful
  /// when you only need to read the helper value without causing rebuilds.
  ///
  /// This method is used internally by [LanguageBuilder] to discover scoped helpers
  /// without creating unnecessary rebuild dependencies.
  ///
  /// Example:
  /// ```dart
  /// Builder(
  ///   builder: (context) {
  ///     final helper = LanguageScope.maybeOf(context);
  ///     if (helper != null) {
  ///       return Text(helper.translate('Hello'));
  ///     }
  ///     return Text('Fallback');
  ///   },
  /// )
  /// ```
  ///
  /// If no scope is found and you need a fallback to [LanguageHelper.instance],
  /// use [of] instead.
  static LanguageHelper? maybeOf(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<LanguageScope>();
    return scope?.languageHelper;
  }

  @override
  bool updateShouldNotify(LanguageScope oldWidget) {
    return languageHelper != oldWidget.languageHelper;
  }
}
