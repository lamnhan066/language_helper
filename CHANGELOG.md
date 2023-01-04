## 0.2.2

* Renamed from `LanguageNotifier` to `LanguageBuilder` and marked it as Deprecated.
* Improved `LanguageBuilder` behavior.

## 0.2.1

* Use the `language_code` plugin instead of the `devicelocale`.

## 0.2.0+3

* Added `isAutoSave` parameter to `initial` to allow the plugin auto save and reload the language when changed and opened in the next time.

## 0.2.0+2

* You can use `@{param}` instead of `@param` to translate text with parameters.
* Added `params` parateters to the `translate` method.

## 0.2.0+1

* [BREAKING CHANGE] the `initial` method will return `Future`, so you need to use `await` to make it equal to before.
* The app will try use `Devicelocale` as the default language code if the `initialCode` is not set.
* Added `useInitialCodeWhenUnavailable` parameter to control the `LanguageCodes` when you change to unavailable code.
* Added `trP()` extension to allow replacing specific texts by values. Ex:
  
  ``` dart
  final text = 'Hello @user'.trP({'user' : 'Vursin'}); // => Hello Vursin
  ```

* Added test.

## 0.1.0+2

* Improved the pub score.

## 0.1.0+1

* Improved function headers.
* Changed to use `debugPrint`.

## 0.1.0

* [BREAK] Rename the param from `defaultCode` to `initialCode`.
* [FEAT] Add a param `onChanged` to notify when the language is changed.

## 0.0.4

* `analyze` will be automatically called in `initial` when `isDebug` is `true`.

## 0.0.3

* [LanguageHelper] add `forceRebuild` to allow the plugin to force rebuild all the widgets intead of only root widgets.
* [LanguageNotifier] add `forceRebuild`to allow the plugin to force rebuild this specific widget or not.

## 0.0.2

* [Feat] Add method `LanguageHelper.instance.analyze()` to analyze the missing texts of all languages.
* Add headers for `LanguageCodes` enum.

## 0.0.1+1

* [LanguageNotifier] Only change the state of the root widgets to improve performance.

## 0.0.1

* Initial release.
