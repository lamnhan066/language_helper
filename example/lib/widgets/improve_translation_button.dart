import 'package:flutter/material.dart';
import 'package:language_helper/language_helper.dart';

/// A small button widget that opens LanguageImprover for a specific
/// translation key.
///
/// This widget should be placed next to text widgets that display
/// translations. It does not render the text itself - it's just the
/// improve button.
///
/// Example usage:
/// ```dart
/// Row(
///   children: [
///     Text('Hello @{name}'.trP({'name': 'World'})),
///     ImproveTranslationButton(translationKey: 'Hello @{name}'),
///   ],
/// )
/// ```
class ImproveTranslationButton extends StatelessWidget {
  const ImproveTranslationButton({
    super.key,
    required this.translationKey,
    this.languageHelper,
    this.size,
  });

  /// The translation key to improve
  final String translationKey;

  /// The LanguageHelper instance to use
  final LanguageHelper? languageHelper;

  /// Optional custom size for the button
  final double? size;

  @override
  Widget build(BuildContext context) {
    final helper = languageHelper ?? LanguageHelper.instance;

    return Tooltip(
      message: 'Improve translation for "$translationKey"',
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LanguageImprover(
                languageHelper: helper,
                scrollToKey: translationKey,
                onTranslationsUpdated: (updatedTranslations) async {
                  // Apply the updated translations to LanguageHelper
                  // This will trigger rebuilds automatically via
                  // LanguageBuilder
                  for (final entry in updatedTranslations.entries) {
                    final code = entry.key;
                    final translations = entry.value;

                    // Create a LanguageDataProvider from the updated
                    // translations
                    final provider = LanguageDataProvider.data({
                      code: translations,
                    });

                    // Add the translations as overrides, which will trigger
                    // rebuilds. We await to ensure translations are applied
                    // before the screen updates
                    await helper.addDataOverrides(provider);
                  }

                  // Show success message after translations are applied
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Translation improved for key '
                          '"$translationKey"',
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                onCancel: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Translation editing cancelled.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                autoSearchOnScroll: false,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Icon(
            Icons.edit_outlined,
            size: size ?? 14,
            color: Colors.blue[700],
          ),
        ),
      ),
    );
  }
}
