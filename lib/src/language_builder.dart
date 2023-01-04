part of '../language_helper.dart';

// ignore: deprecated_member_use_from_same_package
@Deprecated('Use `LanguageBuilder` insteads')
class LanguageNotifier extends LanguageBuilder {
  const LanguageNotifier({
    super.key,
    required super.builder,
    super.forceRebuild,
  });
}

/// @Source https://hillel.dev/2018/08/15/flutter-how-to-rebuild-the-entire-app-to-change-the-theme-or-locale/

class LanguageBuilder extends StatefulWidget {
  /// Wrap the widget that you want to change when changing language
  const LanguageBuilder({
    Key? key,
    required this.builder,
    this.forceRebuild,
  }) : super(key: key);

  /// Add you builder
  final Widget Function(BuildContext) builder;

  /// The plugin only rebuilds the root widget even when you use multiple [LanguageBuilder],
  /// So, you can set this value to `true` if you want to force rebuild
  /// this widget when the language is changed. Use the default value
  /// from LanguageHelper.initial() if this value is null.
  final bool? forceRebuild;

  @override
  State<LanguageBuilder> createState() => _LanguageBuilderState();
}

class _LanguageBuilderState extends State<LanguageBuilder> {
  GlobalKey _key = GlobalKey();

  /// Update the language
  void _updateLanguage() {
    if (mounted) {
      setState(() {
        _key = GlobalKey();
      });
    }
  }

  /// Get the root state
  static _LanguageBuilderState? _of(BuildContext context, bool forceRebuild) {
    if (forceRebuild) return null;
    return context.findRootAncestorStateOfType<_LanguageBuilderState>();
  }

  @override
  void didChangeDependencies() {
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

    super.didChangeDependencies();
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
    return Builder(
      key: _key,
      builder: (context) {
        return widget.builder(context);
      },
    );
  }
}
