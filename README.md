# Language Helper

Make it easier for you to implement multiple languages into your app.

## Usage

Create the data:

``` dart
LanguageData data = {
  LanguageCodes.en: {
    'Hello': 'Hello',
    'Change language': 'Change language',
  },
  LanguageCodes.vi: {
    'Hello': 'Xin Chào',
    'Change language': 'Thay đổi ngôn ngữ',
  }
};
```

Initialize the data:

``` dart
LanguageHelper.instance.initial(
    data: data,
    defaultCode: LanguageCodes.en, // Optional. Default is set to the first language of [data]
    isDebug: true, // Print debug log. Default is set to false
);
```

Translate text:

``` dart
final text = LanguageHelper.instance.translate('Hello');
```

Use extension:

``` dart
final text = 'Hello'.tr;
```

Use builder to rebuild the widgets automatically on change:

- For all widget in your app:

``` dart
  @override
  Widget build(BuildContext context) {
    return LanguageNotifier(builder: (context) {
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: Text('Hello'.tr),
          ),
          body: Center(
            child: Column(
              children: [
                Text('Hello'.tr),
                ElevatedButton(
                  onPressed: () {
                    LanguageHelper.instance.change(LanguageCodes.vi);
                  },
                  child: Text('Change language'.tr),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
```

- For specific widget:

``` dart
LanguageNotifier(
    builder: (context) {
        return Text('Hello'.tr);
    },
),
```

*No matter how many `LanguageNotifier` that you use, the plugin only rebuilds the outest (the root) widget of `LanguageNotifier`, so it improves a lot performance. And all `LanguageNotifier` widgets will be rebuilt at the same time.*

## Additional Information

- The `LanguageCodes` contains all the languages with additional information like name in English (name) and name in native language (nativeName).
- This is the very first state so it may contain issues.
