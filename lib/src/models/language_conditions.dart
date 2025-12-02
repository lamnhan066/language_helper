import 'dart:convert';

import 'package:flutter/foundation.dart';

class LanguageConditions {
  /// Conditional translations based on parameter values. [param] must match
  /// the parameter in the text (specified by @ or @{}). Use `'_'` (recommended)
  /// or `'default'` (legacy) for fallback.
  ///
  /// Example:
  /// ```dart
  /// LanguageData data = {
  ///   LanguageCodes.en: {
  ///     'You have @{count} item': LanguageConditions(
  ///       param: 'count',
  ///       conditions: {
  ///         '0': 'You have 0 items',
  ///         '1': 'You have one item',
  ///         '_': 'You have @{count} items',
  ///       },
  ///     ),
  ///   },
  /// };
  /// ```
  const LanguageConditions({required this.param, required this.conditions});

  /// Creates from a map (typically from JSON). Map must contain `param` and
  /// `conditions` keys. Defaults to empty string if `param` is missing.
  ///
  /// Example:
  /// ```dart
  /// final map = {'param': 'count', 'conditions': {'1': 'one', '_': 'many'}};
  /// final condition = LanguageConditions.fromMap(map);
  /// ```
  factory LanguageConditions.fromMap(Map<String, dynamic> map) {
    return LanguageConditions(
      param: map['param'] as String? ?? '',
      conditions: map['conditions'] as Map<String, dynamic>,
    );
  }

  /// Creates from a JSON string. Inverse of [toJson]. JSON must contain
  /// `param` and `conditions` keys.
  ///
  /// Example:
  /// ```dart
  /// final jsonString =
  ///     '{"param":"count","conditions":{"1":"one","_":"many"}}';
  /// final condition = LanguageConditions.fromJson(jsonString);
  /// ```
  factory LanguageConditions.fromJson(String source) =>
      LanguageConditions.fromMap(json.decode(source) as Map<String, dynamic>);

  /// The parameter that you want to use the conditions.
  final String param;

  /// Map of conditions
  final Map<String, dynamic> conditions;

  /// Converts to a serializable map with `param` and `conditions` keys. Used
  /// for JSON serialization.
  ///
  /// Example:
  /// ```dart
  /// final condition = LanguageConditions(
  ///   param: 'count',
  ///   conditions: {'1': 'one', '_': 'many'},
  /// );
  /// final map = condition.toMap();
  /// // map = {'param': 'count', 'conditions': {'1': 'one', '_': 'many'}}
  /// ```
  Map<String, dynamic> toMap() {
    return {'param': param, 'conditions': conditions};
  }

  /// Converts to a JSON string. Inverse of [fromJson].
  String toJson() => json.encode(toMap());

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
