Map<String, String> mockAssets = {
  'assets/language_helper/codes.json': '''
[
  "en",
  "vi"
]''',
  'assets/language_helper/languages/en.json': '''
{
  "Hello": "Hello",
  "You have @number dollars": "You have @number dollars",
  "You have @{number}, dollars": "You have @{number}, dollars",
  "You have @{number} dollar": {
    "param": "number",
    "conditions": {
      "0": "You have zero dollar",
      "1": "You have @{number} dollar",
      "2": "You have @{number} dollars",
      "default": "You have @{number} dollars"
    }
  },
  "Text is missed in vi": "Text is missed in vi",
  "There are @number people in your family": {
    "param": "number",
    "conditions": {
      "0": "There is @number people in your family",
      "1": "There is @number people in your family",
      "2": "There are @number people in your family"
    }
  },
  "You have @{number} dollar in your wallet": "You have @{number} dollar in your wallet"
}''',
  'assets/language_helper/languages/vi.json': '''
{
  "Hello": "Xin Chào",
  "You have @number dollars": "Bạn có @number đô-la",
  "You have @{number}, dollars": "Bạn có @{number}, đô-la",
  "You have @{number} dollar": "Bạn có @{number} đô-la",
  "Text is missed in en": "Text is missed in en",
  "There are @number people in your family": "Có @number người trong gia đình bạn",
  "You have @{number} dollar in your wallet": "Bạn có @{number} đô-la trong ví của bạn"
}''',
};
