import 'package:language_helper/language_helper.dart';

void main() {
  for (final lang in LanguageCodes.values) {
    print('''
/// code: "${lang.code}", name: "${lang.name}", nativeName "${lang.nativeName}"
${lang.code}("${lang.code}", "${lang.name}", "${lang.nativeName}"),
''');
  }
}
