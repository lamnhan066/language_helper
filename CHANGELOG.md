## 0.11.2+1

* Support the web platform (only improve the list on pub.dev).

## 0.11.2

* Support a wider range of dependency versions.

## 0.11.1+1

* Bump `language_helper_generator` to `0.5.1`:
  * Change the generated path in Map from `'@path_1': '.lib/to/file.dart'` to `"@path_.lib/to/file.dart": ''`
* Bump dependencies.

## 0.11.0

* Release to stable.

## 0.11.0-rc.8

* Add `trC` to translate with the custom instance of LanguageHelper.
* The default instance is now set to final to avoid modifying.
* Improve Tr builder.
* Update example and tests.
* Bump `language_helper_generator` to support `trC`.

## 0.11.0-rc.7

* Able to use the custom `LanguageHelper` in `LanguageBuilder` and `Tr`.

## 0.11.0-rc.6

* Add topics.

## 0.11.0-rc.5

* Add `isInitialized` (bool) and `ensureInitialized` (Future<void>) to check whether the `initial` is run.
* Update tests.

## 0.11.0-rc.4

* Improve README.
* Improve example.

## 0.11.0-rc.3

* Improve the logic of using the temporary data while developing.
  * Right:

  ```dart
  languageHelper.initial(
    data: []
  );
  ```

  * Wrong:

  ```dart
  languageHelper.initial(
    data: [LanguageDataProvider.data({})],
  );
  ```

* `assets` data is preferred between `assets` and `network` because we still haven't a way to cache it.

## 0.11.0-rc.2

* The `language_helper` in `.asset` and `.network` of `LanguageDataProvider` are now required. So we don't need to add it into the input path:
  * Before:

  ```dart
  LanguageDataProvider.asset('assets/resources/language_helper');
  LanguageDataProvider.network('https://example.com/resources/language_helper');
  ```

  * Now:

  ```dart
  LanguageDataProvider.asset('assets/resources');
  LanguageDataProvider.network('https://example.com/resources');  
  ```

* Generator:
  * Change the default path of the Dart Map generator:
    * Before:

    ```txt
    |-- .lib
    |   |--- resources
    |   |    |--- language_helper
    |   |    |    |--- _language_data_abstract.g.dart   ; This file will be overwritten when generating
    |   |    |    |--- language_data.dart
    ```

    * Now:

    ```txt
    |-- .lib
    |   |--- resources
    |   |    |--- language_helper
    |   |    |    |--- language_data.dart
    |   |    |    |--- languages
    |   |    |    |    |--- _generated.dart   ; This will be overwritten when re-generating
    ```

  * Change the default path of the Dart Map generator:
    * Before:

    ```txt
    |-- assets
    |   |--- language_helper
    |   |    |--- codes.json   ; List of supported language code
    |   |    |--- languages
    |   |    |    |--- _generated.json ; Each language will be stored in 1 files
    ```

    * Now:

    ```txt
    |-- assets
    |   |--- resources
    |   |    |--- language_helper
    |   |    |    |--- codes.json
    |   |    |    |--- languages
    |   |    |    |   |--- _generated.json ; This file will be overwritten when re-generating
    ```

  * JSON generator will not overwrite the `codes.json` when re-generating.

## 0.11.0-rc.1

* Bump min sdk to `3.0.0`.
* Able to create a new `LanguageHelper` instance.
* Change from `LanguageData` to `LanguageDataProvider` to support the data from `data` (the default `LanguageData`), `asset` (JSON from the local assets) and `network` (JSON from the URL).
* Multiple `LanguageDataProvider` inputs are supported.
* Able export JSONs from the current `LanguageData` (for the migration).
* Remove deprecated features.
* Improve README.

## 0.10.0

* Promote to stable.
* This release includes the **BREAKING CHANGE**.

## 0.10.0-rc.2

* Improve the `forceRebuild` logic.

## 0.10.0-rc.1

* Improve the `LanguageBuilder` behavior to avoid the dupplicated state issue.

## 0.10.0-rc

* Bump `language_code` to 0.4.0 to support country code.
  * **BREAKING CHANGE NOTE:** The method `.fromEnglishName` and `.fromNativeName` may be broken in this version with this [Changelog](https://pub.dev/packages/language_code/changelog).
* Add an instruction for the `Language Helper Translator` with custom Chat GPT-4 in README.
* Add `isOptionalCountryCode` paramenter to the `initial` method to control the country code behavior.
* Deprecates `LanguageHelper.instance.delegate` -> `LanguageHelper.instance.delegates`.
* Add tests.

## 0.9.0+2

* Improve README.

## 0.9.0+1

* Improve the pub score.

## 0.9.0

* Update [language_helper_generator](https://pub.dev/packages/language_helper_generator) to `0.4.1`:
  * Completely rewritten using dart analyzer to improve reliability.
* Improve README.

## 0.8.0

* Update [language_helper_generator](https://pub.dev/packages/language_helper_generator) to `0.3.0`:
  * Convert to single quote when possible to avoid duplicated text issue.
  * Able to parse a text with `r` raw text tag.
* Improve README.

## 0.7.3

* Beside using 'default' in `LanguageCondition` to set the default value, we can use '_' from this version.

## 0.7.2

* Update homepage URL.

## 0.7.1

* Bump dependencies.
* Update codecov URL.

## 0.7.0

* Add `syncWithDevice` parameter to sync the language with the device language, auto apply on changed.
* The `initialCode` will keeps its value correctly. In the past version, the `initialCode` maybe changed to the local code (from SharedPreferences).
* The `useInitialCodeWhenUnavailable` now works correcly.
* Add more test cases.

## 0.6.0

* Automatically run `dart format` for the generated files when running `dart run language_helper:generate`.

## 0.5.5

* Add the flutter default localizations and how to use it.
* Increase code coverage to 100.

## 0.5.4

* Fix the error when adding the new language data to the unmodifiable Map.

## 0.5.3

* Support adding the new language data outside the `initial`.

## 0.5.2

* Support changing the generating path when using the generator.

## 0.5.0

* Bump dependencies

## 0.4.6

* Add `codesBoth` to `LanguageHelper` in order to get the `LanguageCodes`s from both `data` and `dataOverrides` (No duplicated).
* Update dependencies.
* `language_helper_generator`:
  
  * Improve the commented text.
  * Improve TODO text.

## 0.4.5

* Add `dataOverrides` to `initial` to help you override some translations that are already available in the `data`.

## 0.4.4

* Update dependencies.
* Update README.

## 0.4.3

* Update dependencies.

## 0.4.2

* Improve formatting of the analysis results.

## 0.4.1

* Remove deprecated methods.
* Update `language_helper_generator` to `0.1.1`.

## 0.3.0

* Bump min sdk to 2.18.0.
* Bump flutter version to 3.3.0.
* Update dependencies.

## 0.2.7

* Improve test coverage (reach 99.1%).
* Set the sdk version: `">=2.17.0 <4.0.0"`
* Bring the release candidate to stable.

## 0.2.7-rc.5

* Fixes issues of the `LanguageData` serializer.
* Improves test coverage.

## 0.2.7-rc.4

* Add `LanguageConditions` to be able to use the plural translation in `LanguageData`.
* Add serialization for `LanguageData`:
  * Use `data.toJson()` to convert the data to JSON.
  * Use `LanguageDataSerializer.fromJson(json)` to convert the JSON data back to the `LanguageData`.
* Update command to `dart run language_helper:generate`.
* Update test for `LanguageConditions` and `LanguageDataSerializer`.
* Update README.

## 0.2.7-rc.3

* Mark `Lhb` as deprecated, use `Tr` instead.
* Improve README.

## 0.2.7-rc.2

* Add more details to README.

## 0.2.7-rc.1

* Add `language_helper_generator` as a build-in function. Using by command `flutter pub run language_helper:generate`.

## 0.2.6

* Bring the release candidate to stable.

## 0.2.6-rc.4

* Change from `currentCode` to `code`, add `locale` to get the current Locale.
* Add `locales` to get the current list of language as Locale.
* The `data` is now asserted as must be not empty.
* `initial()` must be run before calling `code` or `locale`, so `code` and `locale` are non-null.
* Add `Lhb` as a short version of `LanguageBuilder`.
* `trP` and `trT`'s parameter are now required.
* Add more tests.
* Update example.

## 0.2.6-rc.3

* `stream` now will works even when the `onChanged` is not set.

## 0.2.6-rc.2

* Add `stream` to LanguageHelper, you can listen for language change events.

## 0.2.6-rc.1

* Supports early state of [language_helper_generator](https://pub.dev/packages/language_helper_generator).
* Improves `onChanged` return type.
* Add `analysisKeys` parameter to `initial` (mostly used for `language_helper_generator` I think).
* Improves description for the result of `analyze` method.
* Update README.

## 0.2.5+1

* Improve pub scores.

## 0.2.5

* Add `.trT` extension to use only `toCode` parameter.
* Refactor internal code.

## 0.2.4

* Add `LanguageCodes.fromName` and `LanguageCodes.fromNativeName`.
* Add `orElse` parameter to `LanguageCodes.fromCode`, `.fromName` and `.fromNativeName`.

## 0.2.3

* Add `toCode` parameter to `translate` method to translate the current text to a specific code instead of the currentCode.
* Add `.trF` extension to use full version of `translate`.
* Update README.

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
