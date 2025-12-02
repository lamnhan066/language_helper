import 'package:flutter/material.dart';

import '../../language_helper.dart';

/// [InheritedWidget] that provides a [LanguageHelper] to descendants.
/// Allows different helpers in different parts of the app. Helper priority:
/// explicit parameter > [LanguageScope] > [LanguageHelper.instance]. Child
/// scopes override parent scopes for their subtree.
///
/// Example:
/// ```dart
/// final customHelper = LanguageHelper('CustomHelper');
/// await customHelper.initial(data: customLanguageData);
///
/// LanguageScope(
///   languageHelper: customHelper,
///   child: LanguageBuilder(
///     builder: (context) => Text('Hello'.tr), // Uses customHelper
///   ),
/// )
/// ```
class LanguageScope extends InheritedWidget {
  /// Creates a scope that provides [languageHelper] to descendants.
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
