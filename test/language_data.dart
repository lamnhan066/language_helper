import 'package:language_helper/language_helper.dart';
import 'package:language_helper/src/models/translate_condition.dart';

LanguageData data = {
  LanguageCodes.en: {
    'Hello': 'Hello',
    'You have @number dollars': 'You have @number dollars',
    'You have @{number}, dollars': 'You have @{number}, dollars',
    'You have @{number} dollar': LanguageCondition((params) {
      final param = params['number'];
      switch (param) {
        case 0:
          return 'You have zero dollar';
        case 1:
          return 'You have @{number} dollar';
        default:
          return 'You have @{number} dollars';
      }
    }),
  },
  LanguageCodes.vi: {
    'Hello': 'Xin Chào',
    'You have @number dollars': 'Bạn có @number đô-la',
    'You have @{number}, dollars': 'Bạn có @{number}, đô-la',
    'You have @{number} dollar': 'Bạn có @{number} đô-la',
  }
};
