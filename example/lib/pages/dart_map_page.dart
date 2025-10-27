import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';

class DartMapPage extends StatelessWidget {
  const DartMapPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Dart Map Example'.tr),
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card with gradient
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.map, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Dart Map Data Source'.tr,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Define translations directly in Dart using maps and LanguageConditions.'
                      .tr,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Features Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Key Features'.tr,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem('✓ Simple to define and maintain'),
                  _buildFeatureItem('✓ Full type safety in Dart'),
                  _buildFeatureItem('✓ Supports conditional translations'),
                  _buildFeatureItem('✓ No external file dependencies'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Translation Examples
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.translate, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Translation Examples'.tr,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
          const SizedBox(height: 20),

          // Code Example
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.code, color: Colors.purple),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Code Example'.tr,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: Text(
                      '''
final Map<String, dynamic> enData = {
  'Hello @{name}': 'Hello @{name}',
  'You have @{count} item': 
    LanguageConditions(
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
};''',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.grey[300],
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildFeatureItem(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, height: 1.5)),
        ),
      ],
    ),
  );

  Widget _buildTranslationExample(String title, String example) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Text(
            example,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
