part of '../language_helper.dart';

class LanguageNotifier extends StatefulWidget {
  const LanguageNotifier({
    Key? key,
    required this.builder,
  }) : super(key: key);

  final Function(BuildContext) builder;

  @override
  State<LanguageNotifier> createState() => _LanguageNotifierState();
}

class _LanguageNotifierState extends State<LanguageNotifier> {
  void _updateLanguage() => mounted ? setState(() {}) : null;

  @override
  void initState() {
    LanguageHelper.instance._print('Added ${this} to LanguageHelper states');
    LanguageHelper.instance._states.add(this);
    super.initState();
  }

  @override
  void dispose() {
    LanguageHelper.instance
        ._print('Removed ${this} from LanguageHelper states');
    LanguageHelper.instance._states.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}
