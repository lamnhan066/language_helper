import 'package:language_helper/language_helper.dart';

part '_language_data_abstract.g.dart';

LanguageData languageData = {
  // TODO: You can use this data as your main language, remember to change this code to your base language code
  LanguageCodes.en: analysisLanguageData,
  LanguageCodes.vi: {
    'Hello': 'Xin Chào',
    'Change language': 'Thay đổi ngôn ngữ',
    'Other Page': 'Trang Khác',
    'Text will be changed': 'Chữ sẽ thay đổi',
    'Text will be not changed': 'Chữ không thay đổi',
    'This text is missing in `en`': 'Chữ này sẽ thiếu ở ngôn ngữ `en`',
  }
};
