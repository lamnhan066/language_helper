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
