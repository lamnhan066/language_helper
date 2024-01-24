import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:language_helper/language_helper.dart';
import 'package:language_helper/src/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageDataProvider {
  static Future<LanguageData> _asset({
    required Uri uri,
    required LanguageCodes code,
  }) async {
    String json = await File.fromUri(uri).readAsString();
    if (json.isNotEmpty) {
      return {code: LanguageDataSerializer.valuesFromJson(json)};
    } else {
      return {};
    }
  }

  static Future<LanguageData> _network({
    required Uri uri,
    required LanguageCodes code,
    required Client? client,
    required Map<String, String>? headers,
  }) async {
    String json = await Utils.getUrl(uri, client: client, headers: headers);
    if (json.isNotEmpty) {
      return {code: LanguageDataSerializer.valuesFromJson(json)};
    } else {
      return {};
    }
  }

  /// Get saved `LanguageData` from `SharedPreferences`.
  static Future<LanguageData> getSavedData(
    LanguageCodes code,
    String prefix,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final key = '$prefix.CachedLanguageData.${code.code}';
    final json = prefs.getString(key);

    if (json != null && json.isNotEmpty) {
      return {code: LanguageDataSerializer.valuesFromJson(json)};
    }
    return {};
  }

  /// Save `LanguageData` to `SharedPreferences`.
  static Future<void> saveData(
    LanguageCodes code,
    String prefix,
    LanguageData data,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final key = '$prefix.CachedLanguageData.${code.code}';

    if (data.isNotEmpty) {
      await prefs.setString(key, data.toJson());
    }
  }

  /// Get saved `LanguageData` from `SharedPreferences`.
  static Future<Set<LanguageCodes>> getSavedCodes(String prefix) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final key = '$prefix.CachedLanguageCode';
    final list = prefs.getStringList(key);

    if (list != null && list.isNotEmpty) {
      return list.map((e) => LanguageCodes.fromCode(e)).toSet();
    }
    return {};
  }

  /// Save `LanguageData` to `SharedPreferences`.
  static Future<void> saveCodes(
    String prefix,
    Set<LanguageCodes> codes,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final key = '$prefix.CachedLanguageCode';

    if (codes.isNotEmpty) {
      await prefs.setStringList(key, codes.map((e) => e.code).toList());
    }
  }

  /// Get the `LanguageData` based on the `code`.
  FutureOr<LanguageData> Function(LanguageCodes code) get getData =>
      _getData == null ? (code) => Future.value({}) : _getData!;
  final FutureOr<LanguageData> Function(LanguageCodes code)? _getData;

  /// Get all supported `LanguageCodes`.
  FutureOr<Set<LanguageCodes>> Function() get getSupportedCodes =>
      _getSupportedCodes == null ? () => Future.value({}) : _getSupportedCodes!;
  final FutureOr<Set<LanguageCodes>> Function()? _getSupportedCodes;

  /// Check whether the current `LanguageDataProvider` this `empty`.
  bool get isEmpty => _getData == null || _getSupportedCodes == null;

  const LanguageDataProvider._(this._getData, this._getSupportedCodes);

  /// Create an empty `LanguageDataProvider`
  const LanguageDataProvider.empty() : this._(null, null);

  /// Create an instance of data from `asset`.
  ///
  /// The `parentPath` is a path that point to `codes.json` file but not includes
  /// it.
  ///
  /// Ex: `assets/resources/language_data/codes.json` and your languages is in
  ///     `assets/resources/language_data/languages/en.json`...
  /// The `parentPath` will be `assets/resources/language_data`.
  factory LanguageDataProvider.asset(String parentPath) {
    return LanguageDataProvider._((code) {
      String path = Utils.removeLastSlash(parentPath);
      final uri = Uri.tryParse('$path/languages/${code.code}.json');
      if (uri != null) {
        return _asset(uri: uri, code: code);
      }
      return {};
    }, () async {
      String path = Utils.removeLastSlash(parentPath);
      final uri = Uri.tryParse('$path/codes.json');
      if (uri != null) {
        final json = await File.fromUri(uri).readAsString();
        final decoded = jsonDecode(json).cast<String>() as List<String>;
        final set = decoded.map((e) => LanguageCodes.fromCode(e)).toSet();
        return Future.value(set);
      }
      return {};
    });
  }

  /// Create an instance of data from `network`.
  ///
  /// The `parentPath` is a path that point to `codes.json` file but not includes
  /// it.
  ///
  /// Ex: `https://example.com/assets/resources/language_data/codes.json` and your languages is in
  ///     `https://example.com/assets/resources/language_data/languages/en.json`...
  /// The `parentPath` will be `ahttps://example.com/ssets/resources/language_data`.
  factory LanguageDataProvider.network(
    String parentUrl, {
    Client? client,
    Map<String, String>? headers,
  }) {
    return LanguageDataProvider._((code) {
      String path = Utils.removeLastSlash(parentUrl);
      final uri = Uri.tryParse('$path/languages/${code.code}.json');
      if (uri != null) {
        return _network(uri: uri, code: code, client: client, headers: headers);
      }
      return {};
    }, () async {
      String path = Utils.removeLastSlash(parentUrl);
      final uri = Uri.tryParse('$path/codes.json');
      if (uri != null) {
        final json = await Utils.getUrl(uri, client: client, headers: headers);
        final decoded = jsonDecode(json).cast<String>() as List<String>;
        final set = decoded.map((e) => LanguageCodes.fromCode(e)).toSet();
        return Future.value(set);
      }
      return {};
    });
  }

  /// Create an instance of data from [LanguageData].
  factory LanguageDataProvider.data(LanguageData data) {
    return LanguageDataProvider._((code) {
      return data;
    }, () {
      return data.keys.toSet();
    });
  }
}
