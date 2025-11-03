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

  /// Converts this [LanguageConditions] to a serializable map.
  ///
  /// Returns a map with `param` and `conditions` keys, suitable for JSON
  /// serialization or storage.
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

  /// Creates a [LanguageConditions] instance from a map structure.
  ///
  /// This factory method deserializes a map (typically from JSON) back into
  /// a [LanguageConditions] object. The map must contain `param` and `conditions`
  /// keys.
  ///
  /// If `param` is missing from the map, it defaults to an empty string.
  ///
  /// Example:
  /// ```dart
  /// final map = {'param': 'count', 'conditions': {'1': 'one', '_': 'many'}};
  /// final condition = LanguageConditions.fromMap(map);
  /// ```
  factory LanguageConditions.fromMap(Map<String, dynamic> map) {
    return LanguageConditions(
      param: map['param'] ?? '',
      conditions: Map<String, dynamic>.from(map['conditions']),
    );
  }

  /// Converts this [LanguageConditions] to a JSON string.
  ///
  /// Serializes the condition to a JSON string representation. This is the
  /// inverse operation of [fromJson].
  ///
  /// Example:
  /// ```dart
  /// final condition = LanguageConditions(param: 'count', conditions: {'1': 'one'});
  /// final json = condition.toJson();
  /// // json = '{"param":"count","conditions":{"1":"one"}}'
  /// ```
  String toJson() => json.encode(toMap());

  /// Creates a [LanguageConditions] instance from a JSON string.
  ///
  /// Parses a JSON string and converts it to [LanguageConditions]. This is
  /// the inverse operation of [toJson].
  ///
  /// **JSON format:**
  /// ```json
  /// {
  ///   "param": "count",
  ///   "conditions": {
  ///     "1": "one",
  ///     "_": "many"
  ///   }
  /// }
  /// ```
  ///
  /// Example:
  /// ```dart
  /// final jsonString = '{"param":"count","conditions":{"1":"one","_":"many"}}';
  /// final condition = LanguageConditions.fromJson(jsonString);
  /// ```
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
