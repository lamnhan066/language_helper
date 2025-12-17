import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';

import '../widgets/package_widget.dart';

/// A page that demonstrates using a package widget's LanguageDelegate
/// in MaterialApp's localizationsDelegates.
///
/// This page has its own LanguageHelper instance and uses the PackageWidget's
/// LanguageDelegate in the MaterialApp to demonstrate how packages can
/// provide their own localization delegates.
class PackageDelegatePage extends StatefulWidget {
  const PackageDelegatePage({super.key});

  @override
  State<PackageDelegatePage> createState() => _PackageDelegatePageState();
}

class _PackageDelegatePageState extends State<PackageDelegatePage> {
  // Main page's own LanguageHelper instance
  final LanguageHelper _mainLanguageHelper =
      LanguageHelper('PackageDelegatePage')..initial(
        LanguageConfig(
          data: [LanguageDataProvider.data(_mainLanguageData)],
          initialCode: LanguageCodes.en,
          isDebug: true,
        ),
      );

  // Main page's language data
  static final Map<LanguageCodes, Map<String, dynamic>> _mainLanguageData = {
    LanguageCodes.en: {
      'Package Delegate Example': 'Package Delegate Example',
      'Main Page Title': 'Main Page Title',
      'Main Page Description':
          'This page has its own LanguageHelper and uses '
          "PackageWidget's LanguageDelegate",
      'Main Language': 'Main Language',
      'Main Current Language': 'Main Current Language',
      'Main Locale': 'Main Locale',
      'Change Main Language': 'Change Main Language',
      'Main Translation Example': 'Main Translation Example',
      'Hello from Main Page': 'Hello from Main Page',
      'This page demonstrates':
          "This page demonstrates how to use a package's "
          'LanguageDelegate',
      'Package Widget Section': 'Package Widget Section',
      'The widget below has its own LanguageHelper':
          'The widget below has its own LanguageHelper and exposes a '
          'static LanguageDelegate',
      'MaterialApp Configuration': 'MaterialApp Configuration',
      'The MaterialApp uses PackageWidget.delegate':
          'The MaterialApp uses PackageWidget.delegate in '
          'localizationsDelegates',
    },
    LanguageCodes.vi: {
      'Package Delegate Example': 'Ví dụ Package Delegate',
      'Main Page Title': 'Tiêu đề Trang Chính',
      'Main Page Description':
          'Trang này có LanguageHelper riêng và sử dụng LanguageDelegate '
          'của PackageWidget',
      'Main Language': 'Ngôn ngữ Trang Chính',
      'Main Current Language': 'Ngôn ngữ Trang Chính hiện tại',
      'Main Locale': 'Locale Trang Chính',
      'Change Main Language': 'Thay đổi ngôn ngữ Trang Chính',
      'Main Translation Example': 'Ví dụ dịch Trang Chính',
      'Hello from Main Page': 'Xin chào từ Trang Chính',
      'This page demonstrates':
          'Trang này minh họa cách sử dụng LanguageDelegate của package',
      'Package Widget Section': 'Phần Package Widget',
      'The widget below has its own LanguageHelper':
          'Widget bên dưới có LanguageHelper riêng và cung cấp '
          'LanguageDelegate tĩnh',
      'MaterialApp Configuration': 'Cấu hình MaterialApp',
      'The MaterialApp uses PackageWidget.delegate':
          'MaterialApp sử dụng PackageWidget.delegate trong '
          'localizationsDelegates',
    },
    LanguageCodes.es: {
      'Package Delegate Example': 'Ejemplo de Delegate de Paquete',
      'Main Page Title': 'Título de la Página Principal',
      'Main Page Description':
          'Esta página tiene su propio LanguageHelper y usa el '
          'LanguageDelegate de PackageWidget',
      'Main Language': 'Idioma Principal',
      'Main Current Language': 'Idioma Principal Actual',
      'Main Locale': 'Locale Principal',
      'Change Main Language': 'Cambiar Idioma Principal',
      'Main Translation Example': 'Ejemplo de Traducción Principal',
      'Hello from Main Page': 'Hola desde la Página Principal',
      'This page demonstrates':
          'Esta página demuestra cómo usar el LanguageDelegate de un paquete',
      'Package Widget Section': 'Sección de Widget de Paquete',
      'The widget below has its own LanguageHelper':
          'El widget a continuación tiene su propio LanguageHelper y '
          'expone un LanguageDelegate estático',
      'MaterialApp Configuration': 'Configuración de MaterialApp',
      'The MaterialApp uses PackageWidget.delegate':
          'El MaterialApp usa PackageWidget.delegate en '
          'localizationsDelegates',
    },
    LanguageCodes.fr: {
      'Package Delegate Example': 'Exemple de Délégué de Package',
      'Main Page Title': 'Titre de la Page Principale',
      'Main Page Description':
          'Cette page a son propre LanguageHelper et utilise le '
          'LanguageDelegate de PackageWidget',
      'Main Language': 'Langue Principale',
      'Main Current Language': 'Langue Principale Actuelle',
      'Main Locale': 'Locale Principale',
      'Change Main Language': 'Changer la Langue Principale',
      'Main Translation Example': 'Exemple de Traduction Principale',
      'Hello from Main Page': 'Bonjour depuis la Page Principale',
      'This page demonstrates':
          'Cette page démontre comment utiliser le LanguageDelegate '
          "d'un package",
      'Package Widget Section': 'Section Widget Package',
      'The widget below has its own LanguageHelper':
          'Le widget ci-dessous a son propre LanguageHelper et expose un '
          'LanguageDelegate statique',
      'MaterialApp Configuration': 'Configuration MaterialApp',
      'The MaterialApp uses PackageWidget.delegate':
          'Le MaterialApp utilise PackageWidget.delegate dans '
          'localizationsDelegates',
    },
  };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _mainLanguageHelper.ensureInitialized,
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (asyncSnapshot.hasError) {
          return Center(child: Text('Error: ${asyncSnapshot.error}'));
        }

        return LanguageScope(
          languageHelper: _mainLanguageHelper,
          child: LanguageBuilder(
            builder: (context) {
              // This MaterialApp uses PackageWidget.delegate in
              // localizationsDelegates
              return MaterialApp(
                title: 'Package Delegate Demo',
                theme: ThemeData(
                  useMaterial3: true,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF8B5CF6),
                  ),
                  appBarTheme: const AppBarTheme(
                    elevation: 0,
                    centerTitle: false,
                  ),
                ),
                // Using PackageWidget's LanguageDelegate
                localizationsDelegates: [
                  ...LanguageHelper.instance.delegates,
                  PackageWidget.delegate,
                ],
                supportedLocales: _mainLanguageHelper.locales,
                locale: _mainLanguageHelper.locale,
                home: Scaffold(
                  appBar: AppBar(
                    title: Text('Package Delegate Example'.tr),
                    elevation: 0,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    actions: [
                      PopupMenuButton<LanguageCodes>(
                        icon: const Icon(
                          Icons.language,
                          color: Color(0xFF2563EB),
                        ),
                        onSelected: _mainLanguageHelper.change,
                        itemBuilder: (context) => _mainLanguageHelper.codes
                            .map(
                              (code) => PopupMenuItem<LanguageCodes>(
                                value: code,
                                child: Row(
                                  children: [
                                    Text(code.name.toUpperCase()),
                                    const SizedBox(width: 8),
                                    if (_mainLanguageHelper.code == code)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF2563EB),
                                        size: 18,
                                      ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Card
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF8B5CF6,
                                ).withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Main Page Title'.tr,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Main Page Description'.tr,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Main Page Language Info
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
                                        color: Colors.purple.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.info_outline,
                                        color: Colors.purple,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Main Language'.tr,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  'Main Current Language'.tr,
                                  _mainLanguageHelper.code.name,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  'Main Locale'.tr,
                                  _mainLanguageHelper.locale.toString(),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Main Translation Example'.tr,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(
                                      alpha: 0.05,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Hello from Main Page'.tr,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(
                                      alpha: 0.05,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'This page demonstrates'.tr,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Change Main Language'.tr,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _mainLanguageHelper.codes.map((
                                    code,
                                  ) {
                                    return ElevatedButton(
                                      onPressed: () {
                                        _mainLanguageHelper.change(code);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            _mainLanguageHelper.code == code
                                            ? Colors.purple
                                            : Colors.grey[200],
                                        foregroundColor:
                                            _mainLanguageHelper.code == code
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      child: Text(code.name.toUpperCase()),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Package Widget Section
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
                                        color: Colors.blue.withValues(
                                          alpha: 0.1,
                                        ),
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
                                        'Package Widget Section'.tr,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'The widget below has its own '
                                          'LanguageHelper'
                                      .tr,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const PackageWidget(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // MaterialApp Configuration Info
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
                                        color: Colors.green.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.settings,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'MaterialApp Configuration'.tr,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'The MaterialApp uses '
                                          'PackageWidget.delegate'
                                      .tr,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1F2937),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey[700]!,
                                    ),
                                  ),
                                  child: Text(
                                    '''
    MaterialApp(
      localizationsDelegates: [
    PackageWidget.delegate,  // Using package's delegate
    // ... other delegates
      ],
      supportedLocales: _mainLanguageHelper.locales,
      locale: _mainLanguageHelper.locale,
    )''',
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
