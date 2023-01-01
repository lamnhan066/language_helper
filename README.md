# Language Helper

Make it easier for you to implement multiple languages into your app.

## Usage

**Create the data:**

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

**Initialize the data:**

``` dart
LanguageHelper.instance.initialize(
    data: data,
    initialCode: LanguageCodes.en, // Optional. Default is set to the first language of [data]
    useInitialCodeWhenUnavailable: false, // Optional. Default is set to false
    forceRebuild: true, // Rebuild all the widgets instead of only root widgets
    onChanged: (code) => print(code), // Call this function if the language is changed
    isDebug: true, // Print debug log. Default is set to false
);
```

**Get text:**

``` dart
final text = LanguageHelper.instance.translate('Hello');
```

**Use extension:**

``` dart
final text = 'Hello'.tr;
```

**Use builder to rebuild the widgets automatically on change:**

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

**You can analyze the missing texts for all language with this function:**

``` dart
LanguageHelper.instance.analyze();
```

This function will be automatically called in `initial` when the `isDebug` is `true`.

Here is the result from the Example:

``` cmd
flutter: [Language Helper]
flutter: [Language Helper] ==================================================
flutter: [Language Helper]
flutter: [Language Helper] Analyze all languages to find the missing texts...
flutter: [Language Helper] Results:
flutter: [Language Helper]   LanguageCodes.en:
flutter: [Language Helper]     This text is missing in `en`
flutter: [Language Helper]
flutter: [Language Helper]   LanguageCodes.vi:
flutter: [Language Helper]     This text is missing in `vi`
flutter: [Language Helper]
flutter: [Language Helper] ==================================================
flutter: [Language Helper]
```

## Additional Information

- No matter how many `LanguageNotifier` that you use, the plugin only rebuilds the outest (the root) widget of `LanguageNotifier`, so it improves a lot performance. And all `LanguageNotifier` widgets will be rebuilt at the same time. This setting can be changed with `forceRebuild` parameter in both `initial` for global setting and `LanguageNotifier` for local setting.
- The `LanguageCodes` contains all the languages with additional information like name in English (name) and name in native language (nativeName).
- This is the very first state so it may contain bugs or issues.
