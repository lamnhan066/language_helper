import 'package:language_helper/language_helper.dart';

final en = {
  ///===========================================================================
  /// Path: ./lib/page_asset.dart
  ///===========================================================================
  '@path_0': './lib/page_asset.dart',
  'Asset': 'Asset',
  'This is the line 1': 'This is the line 1',
  'This is the line 2': 'This is the line 2',

  ///===========================================================================
  /// Path: ./lib/main.dart
  ///===========================================================================
  '@path_1': './lib/main.dart',
  'Hello': 'Hello',
  // 'Hello': 'Hello',  // Duplicated
  // 'Hello': 'Hello',  // Duplicated
  'Change language': 'Change language',
  'Analyze languages': 'Analyze languages',
  // 'Hello': 'Hello',  // Duplicated
  // 'Hello': 'Hello',  // Duplicated
  'This is @number dollar':
      const LanguageConditions(param: 'number', conditions: {
    '0': 'This is zero dollar',
    '1': 'This is one dollar',
    '_': 'This is @number dollars',
  }),
  // 'This is @number dollar': 'This is @number dollar',  // Duplicated
  // 'This is @number dollar': 'This is @number dollar',  // Duplicated
  // 'This is a contains variable line $mounted': 'This is a contains variable line $mounted',  // Contains variable
  'Other Page': 'Other Page',
  'Text will be changed': 'Text will be changed',
  'Text will be not changed': 'Text will be not changed',
  // 'Change language': 'Change language',  // Duplicated,
};
