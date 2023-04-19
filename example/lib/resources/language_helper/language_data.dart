import 'package:language_helper/language_helper.dart';

part '_language_data_abstract.g.dart';

LanguageData languageData = {
  // TODO: You can use this data as your main language, remember to change this code to your base language code
  LanguageCodes.en: {
    ///==============================================
    /// Path: main.dart
    ///==============================================
    'This is @number dollar': LanguageConditions(param: 'number', conditions: {
      '0': 'This is zero dollar',
      '1': 'This is one dollar',
      'default': 'This is @number dollars',
    }),
    // 'This is @number dollar': 'This is @number dollar',  // Duplicated
    // 'This is @number dollar': 'This is @number dollar',  // Duplicated
    'Hello': 'Hello',
    // 'Hello': 'Hello',  // Duplicated
    // 'Hello': 'Hello',  // Duplicated
    'Change language': 'Change language',
    'Analyze languages': 'Analyze languages',
    // 'Hello': 'Hello',  // Duplicated
    // 'Hello': 'Hello',  // Duplicated
    'Other Page': 'Other Page',
    'Text will be changed': 'Text will be changed',
    'Text will be not changed': 'Text will be not changed',
    // 'Change language': 'Change language',  // Duplicated,
  },
  LanguageCodes.vi: {
    'This is @number dollar': 'Đây là @number đô-la',
    'Hello': 'Xin Chào',
    'Change language': 'Thay đổi ngôn ngữ',
    'Other Page': 'Trang Khác',
    'Text will be changed': 'Chữ sẽ thay đổi',
    'Text will be not changed': 'Chữ không thay đổi',
    'This text is missing in `en`': 'Chữ này sẽ thiếu ở ngôn ngữ `en`',
  }
};
