part of '../language_helper.dart';

/// @Source https://hillel.dev/2018/08/15/flutter-how-to-rebuild-the-entire-app-to-change-the-theme-or-locale/
class LanguageNotifier extends StatefulWidget {
  /// Wrap the widget that you want to change when changing language
  const LanguageNotifier({
    Key? key,
    required this.builder,
    this.forceRebuild,
  }) : super(key: key);

  /// Add you builder
  final Widget Function(BuildContext) builder;

  /// Force rebuild this widget when the language is changed. Use the default value
  /// from LanguageHelper.initial() if this value is null.
  final bool? forceRebuild;

  @override
  State<LanguageNotifier> createState() => _LanguageNotifierState();
}

class _LanguageNotifierState extends State<LanguageNotifier> {
  /// Update the language
  void _updateLanguage() => mounted ? setState(() {}) : null;

  /// Get the root state
  static _LanguageNotifierState? _of(BuildContext context, bool forceRebuild) {
    if (forceRebuild) return null;
    return context.findRootAncestorStateOfType<_LanguageNotifierState>();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final getRoot = _of(
        context,
        widget.forceRebuild == true ||
            (widget.forceRebuild == null &&
                LanguageHelper.instance._forceRebuild),
      );

      if (getRoot == null) {
        LanguageHelper.instance._print(
            'Cannot find the root context of this context. Add $this to states');
        LanguageHelper.instance._states.add(this);
      } else if (!LanguageHelper.instance._states.contains(getRoot)) {
        LanguageHelper.instance
            ._print('Added root context $getRoot to LanguageHelper states');
        LanguageHelper.instance._states.add(getRoot);
      } else {
        LanguageHelper.instance
            ._print('This root context $this was already contained in states');
      }

      LanguageHelper.instance._print(
          'Length of the states: ${LanguageHelper.instance._states.length}');
    });

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
