import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';

class DartMapPage extends StatelessWidget {
  const DartMapPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Dart Map Example'.tr),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dart Map Data Source'.tr,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This page demonstrates using Dart maps as the data source for translations. The translations are defined directly in Dart code using maps and LanguageConditions.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Translation Examples'.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  _buildTranslationExample(
                    'Simple Translation'.tr,
                    'Hello @{name}'.trP({'name': 'Flutter Developer'}),
                  ),

                  _buildTranslationExample(
                    'Conditional Translation'.tr,
                    'You have @{count} item'.trP({'count': 0}),
                  ),

                  _buildTranslationExample(
                    '',
                    'You have @{count} item'.trP({'count': 1}),
                  ),

                  _buildTranslationExample(
                    '',
                    'You have @{count} item'.trP({'count': 10}),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Code Example'.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Text('''
  final Map<String, dynamic> enData = {
  'Hello @{name}': 'Hello @{name}',
  'You have @{count} item': LanguageConditions(
    param: 'count',
    conditions: {
      '0': 'You have no items',
      '1': 'You have one item',
      '_': 'You have @{count} items',
    },
  ),
  };
  
  final LazyLanguageData languageData = {
  LanguageCodes.en: () => enData,
  LanguageCodes.vi: () => viData,
  };''', style: TextStyle(fontFamily: 'monospace', fontSize: 12),),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildTranslationExample(String title, String example) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Text(example, style: const TextStyle(fontFamily: 'monospace')),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}
