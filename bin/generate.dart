import 'package:args/args.dart';
import 'package:language_helper_generator/language_helper_generator.dart';

void main(List<String> args) {
  final generator = LanguageHelperGenerator();

  final parser = ArgParser()
    ..addOption(
      'path',
      abbr: 'p',
      help:
          'Path to the main folder that you want to to create a base language. Default is `./lib`.',
      valueHelp: './lib',
      defaultsTo: './lib',
    );
  final argResult = parser.parse(args);

  final path = argResult['path'] as String;

  final result = generator.generate(path);
  if (result == null) return;

  generator.createLanguageDataAbstractFile(result, path: path);
  generator.createLanguageDataFile(path);
}
