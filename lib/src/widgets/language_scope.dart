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
/// - You can access the scoped helper directly via [LanguageHelper.of] or [LanguageHelper.maybeOf]
///
/// Priority order when resolving which helper to use:
/// 1. Explicit `languageHelper` parameter (in [LanguageBuilder] or [Tr])
/// 2. [LanguageScope] from widget tree (via [LanguageHelper.maybeOf])
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
///             final helper = LanguageHelper.of(context);
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

  @override
  bool updateShouldNotify(LanguageScope oldWidget) {
    return languageHelper != oldWidget.languageHelper;
  }
}
