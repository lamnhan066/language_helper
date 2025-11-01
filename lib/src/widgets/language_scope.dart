import 'package:flutter/material.dart';

import '../../language_helper.dart';

/// A widget that provides a scoped [LanguageHelper] instance to its descendants.
///
/// When a [LanguageScope] is present in the widget tree, child widgets using
/// `tr`, `trP`, `LanguageBuilder`, and `Tr` will automatically inherit the
/// scoped instance instead of always using [LanguageHelper.instance].
///
/// Example:
/// ```dart
/// LanguageScope(
///   languageHelper: myCustomHelper,
///   child: MyWidget(),
/// )
/// ```
///
/// You can nest [LanguageScope] widgets - a child scope will override the parent scope
/// for its subtree.
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
  /// This method should be used when you need to access the scoped [LanguageHelper]
  /// instance from a [BuildContext].
  ///
  /// Example:
  /// ```dart
  /// final helper = LanguageScope.of(context);
  /// final translated = helper.translate('Hello');
  /// ```
  static LanguageHelper of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LanguageScope>();
    return scope?.languageHelper ?? LanguageHelper.instance;
  }

  /// Returns the [LanguageHelper] from the nearest [LanguageScope] ancestor,
  /// or null if no scope is found.
  ///
  /// Unlike [of], this method does not register a dependency on the [LanguageScope],
  /// which means the widget will not rebuild when the scope changes.
  ///
  /// If no scope is found and you need a fallback, use [of] instead.
  static LanguageHelper? maybeOf(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<LanguageScope>();
    return scope?.languageHelper;
  }

  @override
  bool updateShouldNotify(LanguageScope oldWidget) {
    return languageHelper != oldWidget.languageHelper;
  }
}
