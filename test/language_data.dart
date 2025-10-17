import 'package:language_helper/language_helper.dart';

final dataList = [LanguageDataProvider.data(data)];
LanguageData data = {
  LanguageCodes.en: {
    'Hello': 'Hello',
    'You have @number dollars': 'You have @number dollars',
    'You have @{number}, dollars': 'You have @{number}, dollars',
    'You have @{number} dollar': const LanguageConditions(
      param: 'number',
      conditions: {
        '0': 'You have zero dollar',
        '1': 'You have @{number} dollar',
        '2': 'You have @{number} dollars',
        'default': 'You have @{number} dollars',
      },
    ),
    'Text is missed in vi': 'Text is missed in vi',
    'There are @number people in your family': const LanguageConditions(
      param: 'number',
      conditions: {
        '0': 'There is @number people in your family',
        '1': 'There is @number people in your family',
        '2': 'There are @number people in your family',
      },
    ),
    'You have @{number} dollar in your wallet':
        'You have @{number} dollar in your wallet',
  },
  LanguageCodes.vi: {
    'Hello': 'Xin Chào',
    'You have @number dollars': 'Bạn có @number đô-la',
    'You have @{number}, dollars': 'Bạn có @{number}, đô-la',
    'You have @{number} dollar': 'Bạn có @{number} đô-la',
    'Text is missed in en': 'Text is missed in en',
    'There are @number people in your family':
        'Có @number người trong gia đình bạn',
    'You have @{number} dollar in your wallet':
        'Bạn có @{number} đô-la trong ví của bạn',
  },
};

final dataOverrides = [LanguageDataProvider.data(_dataOverrides)];
LanguageData _dataOverrides = {
  LanguageCodes.en: {
    'Hello': 'Hello',
    'You have @{number} dollar in your wallet': const LanguageConditions(
      param: 'number',
      conditions: {
        '0': 'You have zero dollar in your wallet',
        '1': 'You have @{number} dollar in your wallet',
        '2': 'You have @{number} dollars in your wallet',
        'default': 'You have @{number} dollars in your wallet',
      },
    ),
  },
};

final dataAdds = [LanguageDataProvider.data(_dataAdd)];
final dataAdd = LanguageDataProvider.data(_dataAdd);
LanguageData _dataAdd = {
  LanguageCodes.en: {'Hello': 'HelloOverwrite', 'Hello add': 'Hello Add'},
  LanguageCodes.zh: {'Hello': '你好'},
};

Set<String> analysisMissedKeys = {
  'Hello',
  'You have @number dollars',
  'You have @{number}, dollars',
  'You have @{number} dollar',
  'This is a new key',
};

List<String> analysisRemovedKeys = ['Hello', 'You have @number dollars'];
