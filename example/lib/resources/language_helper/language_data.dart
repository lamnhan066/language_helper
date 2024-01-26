import 'package:language_helper/language_helper.dart';

import 'languages/en.dart';
import 'languages/vi.dart';

part 'languages/_generated.dart';

LanguageData languageData = {
  LanguageCodes.en: en,
  LanguageCodes.vi: vi,
};

LanguageData languageDataAdd = {
  LanguageCodes.vi: {
    'This text will be changed when the data added':
        ' Chữ này sẽ thay đổi khi thêm data'
  }
};
