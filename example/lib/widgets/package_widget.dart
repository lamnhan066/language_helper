import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';

/// A widget that represents a package component with its own LanguageHelper.
///
/// This demonstrates how a package can have its own LanguageHelper instance
/// and expose a LanguageDelegate for use in MaterialApp's
/// localizationsDelegates.
class PackageWidget extends StatefulWidget {
  const PackageWidget({super.key});

  // Package's own LanguageHelper instance
  static final LanguageHelper _packageLanguageHelper =
      LanguageHelper('PackageWidget')..initial([
        LanguageDataProvider.data(PackageWidget._packageLanguageData),
      ], config: LanguageConfig(initialCode: LanguageCodes.en, isDebug: true));

  // Static LanguageDelegate exposed for use in MaterialApp
  static LanguageDelegate get delegate =>
      LanguageDelegate(_packageLanguageHelper);

  // Package-specific language data
  static final LanguageData _packageLanguageData = {
    LanguageCodes.en: {
      'Package Title': 'Package Title',
      'Package Description':
          'This is a package widget with its own LanguageHelper',
      'Package Language': 'Package Language',
      'Package Current Language': 'Package Current Language',
      'Change Package Language': 'Change Package Language',
      'Package Translation Example': 'Package Translation Example',
      'Hello from Package': 'Hello from Package',
      'Package supports multiple languages':
          'Package supports multiple languages',
    },
    LanguageCodes.vi: {
      'Package Title': 'Tiêu đề Package',
      'Package Description':
          'Đây là một widget package với LanguageHelper riêng',
      'Package Language': 'Ngôn ngữ Package',
      'Package Current Language': 'Ngôn ngữ Package hiện tại',
      'Change Package Language': 'Thay đổi ngôn ngữ Package',
      'Package Translation Example': 'Ví dụ dịch Package',
      'Hello from Package': 'Xin chào từ Package',
      'Package supports multiple languages': 'Package hỗ trợ nhiều ngôn ngữ',
    },
    LanguageCodes.es: {
      'Package Title': 'Título del Paquete',
      'Package Description':
          'Este es un widget de paquete con su propio LanguageHelper',
      'Package Language': 'Idioma del Paquete',
      'Package Current Language': 'Idioma actual del Paquete',
      'Change Package Language': 'Cambiar idioma del Paquete',
      'Package Translation Example': 'Ejemplo de traducción del Paquete',
      'Hello from Package': 'Hola desde el Paquete',
      'Package supports multiple languages': 'El paquete admite varios idiomas',
    },
    LanguageCodes.fr: {
      'Package Title': 'Titre du Package',
      'Package Description':
          'Ceci est un widget de package avec son propre LanguageHelper',
      'Package Language': 'Langue du Package',
      'Package Current Language': 'Langue actuelle du Package',
      'Change Package Language': 'Changer la langue du Package',
      'Package Translation Example': 'Exemple de traduction du Package',
      'Hello from Package': 'Bonjour du Package',
      'Package supports multiple languages':
          'Le package prend en charge plusieurs langues',
    },
  };

  @override
  State<PackageWidget> createState() => _PackageWidgetState();
}

class _PackageWidgetState extends State<PackageWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: PackageWidget._packageLanguageHelper.ensureInitialized,
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (asyncSnapshot.hasError) {
          return Center(child: Text('Error: ${asyncSnapshot.error}'));
        }

        return LanguageScope(
          languageHelper: PackageWidget._packageLanguageHelper,
          child: LanguageBuilder(
            builder: (context) {
              return Card(
                elevation: 4,
                margin: const EdgeInsets.all(16),
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
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.extension,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Package Title'.tr,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Package Description'.tr,
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow(
                        'Package Language'.tr,
                        PackageWidget._packageLanguageHelper.code.name,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Package Current Language'.tr,
                        PackageWidget._packageLanguageHelper.locale.toString(),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Package Translation Example'.tr,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Hello from Package'.tr,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Package supports multiple languages'.tr,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Change Package Language'.tr,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: PackageWidget._packageLanguageHelper.codes
                            .map((code) {
                              return ElevatedButton(
                                onPressed: () {
                                  PackageWidget._packageLanguageHelper.change(
                                    code,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      PackageWidget
                                              ._packageLanguageHelper
                                              .code ==
                                          code
                                      ? Colors.blue
                                      : Colors.grey[200],
                                  foregroundColor:
                                      PackageWidget
                                              ._packageLanguageHelper
                                              .code ==
                                          code
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                child: Text(code.name.toUpperCase()),
                              );
                            })
                            .toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
