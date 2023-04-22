import 'package:language_helper/language_helper.dart';

LanguageData data = {
  LanguageCodes.en: {
    'Hello': 'Hello',
    'You have @number dollars': 'You have @number dollars',
    'You have @{number}, dollars': 'You have @{number}, dollars',
    'You have @{number} dollar': LanguageConditions(
      param: 'number',
      conditions: {
        '0': 'You have zero dollar',
        '1': 'You have @{number} dollar',
        '2': 'You have @{number} dollars',
        'default': 'You have @{number} dollars',
      },
    ),
    'Text is missed in vi': 'Text is missed in vi',
    'There are @number people in your family': LanguageConditions(
      param: 'number',
      conditions: {
        '0': 'There is @number people in your family',
        '1': 'There is @number people in your family',
        '2': 'There are @number people in your family',
      },
    ),
  },
  LanguageCodes.vi: {
    'Hello': 'Xin Chào',
    'You have @number dollars': 'Bạn có @number đô-la',
    'You have @{number}, dollars': 'Bạn có @{number}, đô-la',
    'You have @{number} dollar': 'Bạn có @{number} đô-la',
    'Text is missed in en': 'Text is missed in en',
    'There are @number people in your family':
        'Có @number người trong gia đình bạn',
  }
};

List<String> analysisMissedKeys = [
  'Hello',
  'You have @number dollars',
  'You have @{number}, dollars',
  'You have @{number} dollar',
  'This is a new key',
  'This is a new key',
];

List<String> analysisRemovedKeys = [
  'Hello',
  'You have @number dollars',
];
