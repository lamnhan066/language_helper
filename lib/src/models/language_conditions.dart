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
  /// condition. There is a `default` key to let you set the default return if
  /// there is no matched condition.
  ///
  /// Eg.
  /// ``` dart
  /// LanguageData data = {
  ///   LanguageCodes.en : {
  ///     'This is @number dollar' : LanguageConditions(
  ///       param: 'number',
  ///       conditions: {
  ///         '0' : 'This is zero dollar',
  ///         '1' : 'This is one dollar',
  ///         'default' : 'This is @number dollars',
  ///       }
  ///     ),
  ///   }
  /// };
  /// ```
  LanguageConditions({
    required this.param,
    required this.conditions,
  });

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'param': param,
      'conditions': conditions,
    };
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
