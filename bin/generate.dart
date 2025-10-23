// ignore_for_file: avoid_print

import 'dart:io';

/// Executes the isolate manager generator with the provided arguments.
///
/// Takes a list of command-line arguments, processes them, and generates
/// the appropriate worker files based on the configuration.
///
/// Returns:
///   0: Success
///   1: Compilation error
///   2: Unable to resolve file
///   3: No main function found
///   4: Main function has no open braces
///   5: File not found
///
///   11: Could not find package `language_helper_generator` or file `language_helper_generator`
///
///   111: Unknown error
void main(List<String> args) async {
  final isGeneratorInstalled = _isGeneratorInstalled();
  if (!isGeneratorInstalled) {
    if (args.contains('--add-generator')) {
      print('Adding language_helper_generator to dev dependencies...');

      final addProcess = await Process.run('dart', [
        'pub',
        'add',
        'language_helper_generator',
        '--dev',
      ]);

      if (addProcess.exitCode != 0) {
        print('Failed to add language_helper_generator: ${addProcess.stderr}');
        exit(1);
      }

      print('Added language_helper_generator to dev dependencies.');
    } else {
      print(
        'Missing dependency: `language_helper_generator`.\n'
        'To fix this, you have two options:\n'
        '1. Run: `dart pub add language_helper_generator --dev`\n'
        '2. Or simply re-run this command with the `--add-generator` flag to '
        'add it automatically.',
      );
      exit(11);
    }
  }

  final process = await Process.start('dart', [
    'run',
    'language_helper_generator',
    ...[...args]..remove('--add-generator'),
  ]);

  exit(await process.exitCode);
}

bool _isGeneratorInstalled() {
  final result = Process.runSync('dart', ['pub', 'deps']);
  if (result.exitCode != 0) return false;
  final output = result.stdout.toString();
  return output.contains('language_helper_generator');
}
