import 'dart:convert';

import 'package:flutter/foundation.dart';

class LanguageConditions {
  /// The parameter that you want to use the conditions.
  final String param;

  /// Map of conditions
  final Map<String, dynamic> conditions;

  /// Conditions of the language that you want to translate into.
  ///
  /// You have to specify the [param] that matches the parameter in the text
  /// (which is specified by the @ or @{}).
  ///
  /// [conditions] is a Map of key and value that you want to apply for each
  /// condition. There are two keys for the default return value when there is
  /// no matched condition:
  /// - `'default'` - Legacy key for backward compatibility
  /// - `'_'` - Recommended key for the default case
  ///
  /// Example:
  /// ```dart
  /// LanguageData data = {
  ///   LanguageCodes.en : {
  ///     'You have @{count} item' : LanguageConditions(
  ///       param: 'count',
  ///       conditions: {
  ///         '0' : 'You have 0 items',
  ///         '1' : 'You have one item',
  ///         '_' : 'You have @{count} items', // Default case
  ///       }
  ///     ),
  ///   }
  /// };
  /// ```
  const LanguageConditions({required this.param, required this.conditions});

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {'param': param, 'conditions': conditions};
  }

  /// Convert to LanguageConditions from Map
  factory LanguageConditions.fromMap(Map<String, dynamic> map) {
    return LanguageConditions(
      param: map['param'] ?? '',
      conditions: Map<String, dynamic>.from(map['conditions']),
    );
  }

  /// Convert to JSON
  String toJson() => json.encode(toMap());

  /// Convert to LanguageConditions from JSON
  factory LanguageConditions.fromJson(String source) =>
      LanguageConditions.fromMap(json.decode(source));

  @override
  String toString() =>
      'LanguageConditions(param: $param, conditions: $conditions)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LanguageConditions &&
        other.param == param &&
        mapEquals(other.conditions, conditions);
  }

  @override
  int get hashCode => param.hashCode ^ conditions.hashCode;
}
