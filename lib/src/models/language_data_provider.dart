import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:language_helper/language_helper.dart';
import 'package:language_helper/src/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageDataProvider {
  final String? parentPath;
  final String? parentUrl;
  final LanguageData? data;
  final Map<String, String>? headers;
  final Client? client;

  bool get isEmpty =>
      parentPath == null &&
      parentUrl == null &&
      (data == null || data!.isEmpty);

  const LanguageDataProvider.asset(this.parentPath)
      : data = null,
        parentUrl = null,
        headers = null,
        client = null;

  const LanguageDataProvider.network(this.parentUrl,
      {this.client, this.headers})
      : data = null,
        parentPath = null;

  const LanguageDataProvider.data(this.data)
      : parentPath = null,
        parentUrl = null,
        headers = null,
        client = null;

  const LanguageDataProvider.empty()
      : data = null,
        parentPath = null,
        parentUrl = null,
        headers = null,
        client = null;

  Future<Set<LanguageCodes>> getSupportedCodes() async {
    if (data != null) {
      return Future.value(data!.keys.toSet());
    } else if (parentPath != null) {
      String path = Utils.removeLastSlash(parentPath!);
      final uri = Uri.tryParse('$path/codes.json');
      if (uri != null) {
        final json = await File.fromUri(uri).readAsString();
        final decoded = jsonDecode(json).cast<String>() as List<String>;
        final set = decoded.map((e) => LanguageCodes.fromCode(e)).toSet();
        return Future.value(set);
      }
    } else if (parentUrl != null) {
      String path = Utils.removeLastSlash(parentUrl!);
      final uri = Uri.tryParse('$path/codes.json');
      if (uri != null) {
        final json = await Utils.getUrl(uri, client: client, headers: headers);
        final decoded = jsonDecode(json).cast<String>() as List<String>;
        final set = decoded.map((e) => LanguageCodes.fromCode(e)).toSet();
        return Future.value(set);
      }
    }

    return {};
  }

  Future<LanguageData> get(LanguageCodes code) async {
    if (data != null) {
      return Future.value(data);
    } else if (parentPath != null) {
      String path = Utils.removeLastSlash(parentPath!);
      final uri = Uri.tryParse('$path/languages/${code.code}.json');
      if (uri != null) {
        return _asset(uri: uri, code: code);
      }
    } else if (parentUrl != null) {
      String path = Utils.removeLastSlash(parentUrl!);
      final uri = Uri.tryParse('$path/languages/${code.code}.json');
      if (uri != null) {
        return _network(uri: uri, code: code);
      }
    }

    return {};
  }

  Future<LanguageData> _asset({
    required Uri uri,
    required LanguageCodes code,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final key = 'CachedLanguageData.${code.code}';
    String json = await File.fromUri(uri).readAsString();
    if (json.isEmpty) {
      json = prefs.getString(key) ?? '';
    } else {
      prefs.setString(key, json);
    }
    if (json.isNotEmpty) {
      return LanguageDataSerializer.fromJson(json);
    } else {
      return {};
    }
  }

  Future<LanguageData> _network({
    required Uri uri,
    required LanguageCodes code,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final key = 'CachedLanguageData.${code.code}';
    String json = await Utils.getUrl(uri, client: client, headers: headers);

    if (json.isEmpty) {
      json = prefs.getString(key) ?? '';
    } else {
      prefs.setString(key, json);
    }
    if (json.isNotEmpty) {
      return LanguageDataSerializer.fromJson(json);
    } else {
      return {};
    }
  }
}
