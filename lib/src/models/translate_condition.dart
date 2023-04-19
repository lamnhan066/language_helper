import 'dart:convert';

import 'package:flutter/foundation.dart';

class LanguageCondition {
  final String param;
  final Map<String, dynamic> conditions;

  LanguageCondition({
    required this.param,
    required this.conditions,
  });

  LanguageCondition copyWith({
    String? param,
    Map<String, dynamic>? conditions,
  }) {
    return LanguageCondition(
      param: param ?? this.param,
      conditions: conditions ?? this.conditions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'param': param,
      'conditions': conditions,
    };
  }

  factory LanguageCondition.fromMap(Map<String, dynamic> map) {
    return LanguageCondition(
      param: map['param'] ?? '',
      conditions: Map<String, dynamic>.from(map['conditions']),
    );
  }

  String toJson() => json.encode(toMap());

  factory LanguageCondition.fromJson(String source) =>
      LanguageCondition.fromMap(json.decode(source));

  @override
  String toString() =>
      'LanguageCondition(param: $param, conditions: $conditions)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LanguageCondition &&
        other.param == param &&
        mapEquals(other.conditions, conditions);
  }

  @override
  int get hashCode => param.hashCode ^ conditions.hashCode;
}
