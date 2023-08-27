import 'dart:async';

import 'package:flutter/material.dart' show CircleAvatar, CircularProgressIndicator, Icons;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../model/auth.dart';

class SettingsApp extends StatelessWidget {
  const SettingsApp({super.key});

  static const Map<ShortcutActivator, Intent> _settingsShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.tab): ActivateIntent(),
  };

  @override
  Widget build(BuildContext context) {
    Widget result = const FocusScope(
      child: DefaultTextStyle(
        style: TextStyle(color: Color(0xffffffff)),
        child: SettingsNav(
          root: SettingsMainPage(),
        ),
      ),
    );
    assert(() {
      result = CheckedModeBanner(child: result);
      return true;
    }());
    return Shortcuts(
      shortcuts: {
        ...WidgetsApp.defaultShortcuts,
        ..._settingsShortcuts,
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ...WidgetsApp.defaultActions,
        },
        child: Localizations(
          delegates: const [DefaultWidgetsLocalizations.delegate],
          locale: const Locale('en'),
          child: Title(
            title: 'Photos Screensaver',
            color: const Color(0xff000000),
            child: FocusTraversalGroup(
              policy: ReadingOrderTraversalPolicy(),
              child: result,
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsNav extends StatefulWidget {
  const SettingsNav({
    super.key,
    required this.root,
  });

  final Widget root;

  static const Duration animationDuration = Duration(milliseconds: 350);
  static const Curve animationCurve = Curves.easeOut;
  static const Color defaultBgColor = Color(0xff1f232b);
  static const Color secondaryBgColor = Color(0xff20252e);

  static SettingsNavController of(BuildContext context) {
    _SettingsNavScope scope = context.dependOnInheritedWidgetOfExactType<_SettingsNavScope>()!;
    return scope.state;
  }

  @override
  State<SettingsNav> createState() => _SettingsNavState();
}

abstract class SettingsNavController {
  /// Whether it is legal to call [forward].
  bool get canMoveForward;

  /// Whether it is legal to call [backward].
  bool get canMoveBackward;

  /// Moves the current entry forward (to what was the next entry).
  ///
  /// This will also cause the new current entry to gain the focus.
  Future<void> forward();

  /// Moves the current entry backward (to what was the previous entry).
  ///
  /// This will first call [clearNext], such that after moving backward, there
  /// is only one entry after the current entry.
  ///
  /// This will also cause the new current entry to gain the focus.
  Future<void> backward();

  /// Sets the next entry (the one after the current entry).
  ///
  /// If there are any entries after the first entry, they will first be removed
  /// and disposed of, then the new entry will be added to the end of the list.
  void setNext(Widget child);

  /// Removes all entries after the current entry.
  ///
  /// If there are no entries after the current entry (i.e. [canMoveForward])
  /// is false), then this has no effect.
  void clearNext();
}

class SettingsNavEntry {
  SettingsNavEntry(this.child): focusNode = FocusNode();

  final Widget child;
  final FocusNode focusNode;
}

class _SettingsNavState extends State<SettingsNav> implements SettingsNavController {
  Completer<void>? _completer;
  final List<SettingsNavEntry> _entries = <SettingsNavEntry>[];
  late int _currentIndex;

  static const double _splitRatio = 0.58;

  void _focusCurrentEntry() {
    _entries[_currentIndex].focusNode.nextFocus();
  }

  void _handleDoneScrolling() {
    assert(_completer != null);
    _completer!.complete();
    _completer = null;
  }

  bool get isScrolling => _completer != null;

  bool get isNotScrolling => !isScrolling;

  bool get nextEntriesExist => _currentIndex < _entries.length - 1;

  bool get previousEntriesExist => _currentIndex > 0;

  void clearWhile(bool Function() test) {
    while (test()) {
      setState(() {
        _entries.removeLast();
      });
    }
  }

  @override
  bool get canMoveForward => isNotScrolling && nextEntriesExist;

  @override
  bool get canMoveBackward => isNotScrolling && previousEntriesExist;

  @override
  Future<void> forward() {
    assert(canMoveForward);
    _completer = Completer<void>();
    setState(() {
      _currentIndex++;
      _focusCurrentEntry();
    });
    return _completer!.future;
  }

  @override
  Future<void> backward() {
    assert(canMoveBackward);
    _completer = Completer<void>();
    setState(() {
      _currentIndex--;
      _focusCurrentEntry();
    });
    return _completer!.future.then((_) {
      bool pending = true;
      clearWhile(() {
        bool result = pending;
        pending = false;
        return result;
      });
    });
  }

  @override
  void setNext(Widget child) {
    assert(_currentIndex < _entries.length);
    setState(() {
      final SettingsNavEntry entry = SettingsNavEntry(child);
      if (_currentIndex == _entries.length - 1) {
        _entries.add(entry);
      } else {
        assert(_currentIndex + 1 < _entries.length);
        _entries[_currentIndex + 1] = entry;
      }
    });
  }

  @override
  void clearNext() {
    clearWhile(() => nextEntriesExist);
  }

  @override
  void initState() {
    super.initState();
    _entries.add(SettingsNavEntry(widget.root));
    _currentIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsNavScope(
      state: this,
      child: SettingsNavScroller(
        onDoneScrolling: _handleDoneScrolling,
        selectedIndex: _currentIndex,
        child: SettingsNavChildren(
          index: _currentIndex,
          entries: _entries,
        ),
      ),
    );
  }
}

class SettingsNavChildren extends StatelessWidget {
  const SettingsNavChildren({
    super.key,
    required this.index,
    required this.entries,
  });

  final int index;
  final List<SettingsNavEntry> entries;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        assert(constraints.hasTightWidth);
        final double primaryWidth = constraints.maxWidth * _SettingsNavState._splitRatio;
        return ColoredBox(
          color: SettingsNav.defaultBgColor,
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.loose,
            children: () {
              final List<Widget> wrappedChildren = <Widget>[];
              for (int i = 0; i < entries.length; i++) {
                wrappedChildren.add(
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: i * primaryWidth,
                    width: primaryWidth,
                    child: SettingsNavPane(
                      isPrimary: i == index,
                      isSecondary: i > index,
                      focusNode: entries[i].focusNode,
                      child: entries[i].child,
                    ),
                  ),
                );
              }
              return wrappedChildren;
            }(),
          ),
        );
      },
    );
  }
}

class SettingsNavPane extends ImplicitlyAnimatedWidget {
  const SettingsNavPane({
    super.key,
    required this.isPrimary,
    required this.isSecondary,
    required this.focusNode,
    this.child,
  }) : super(duration: SettingsNav.animationDuration, curve: SettingsNav.animationCurve);

  final bool isPrimary;
  final bool isSecondary;
  final FocusNode focusNode;
  final Widget? child;

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() {
    return SettingsNavPaneState();
  }
}

class SettingsNavPaneState extends AnimatedWidgetBaseState<SettingsNavPane> {
  EdgeInsetsTween? _edgeInsetsTween;
  ColorTween? _colorTween;

  static const EdgeInsets _primaryPadding = EdgeInsets.only(left: 63, right: 80);
  static const EdgeInsets _defaultPadding = EdgeInsets.zero;

  @override
  void didUpdateWidget(covariant SettingsNavPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.dispose();
    }
  }

  @override
  void dispose() {
    widget.focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    EdgeInsets padding = const EdgeInsets.fromLTRB(65, 68, 30, 60);
    padding += _edgeInsetsTween!.evaluate(animation);
    final Color color = _colorTween!.evaluate(animation)!;
    return FocusTraversalGroup(
      child: Focus(
        focusNode: widget.focusNode,
        skipTraversal: true,
        child: ColoredBox(
          color: color,
          child: Padding(
            padding: padding,
            child: widget.child,
          ),
        ),
      ),
    );
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _edgeInsetsTween = visitor(
      _edgeInsetsTween,
      widget.isSecondary ? _defaultPadding : _primaryPadding,
      (dynamic value) => EdgeInsetsTween(begin: value as EdgeInsets?),
    ) as EdgeInsetsTween?;
    _colorTween = visitor(
      _colorTween,
      widget.isSecondary ? SettingsNav.secondaryBgColor : SettingsNav.defaultBgColor,
      (dynamic value) => ColorTween(begin: value as Color?),
    ) as ColorTween?;
  }
}

class SettingsNavScroller extends ImplicitlyAnimatedWidget {
  const SettingsNavScroller({
    super.key,
    required this.selectedIndex,
    required this.child,
    VoidCallback? onDoneScrolling,
  }) : super(
    duration: SettingsNav.animationDuration,
    curve: SettingsNav.animationCurve,
    onEnd: onDoneScrolling,
  );

  final int selectedIndex;
  final Widget? child;

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() {
    return SettingsNavScrollerState();
  }
}

class SettingsNavScrollerState extends AnimatedWidgetBaseState<SettingsNavScroller> {
  Tween<double>? _indexTween;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        assert(constraints.hasTightWidth);
        final double primaryWidth = constraints.maxWidth * _SettingsNavState._splitRatio;
        final double index = _indexTween!.evaluate(animation);
        final double dx = index * -1 * primaryWidth;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: widget.child,
        );
      },
    );
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _indexTween = visitor(
      _indexTween,
      widget.selectedIndex.toDouble(),
      (dynamic value) => Tween<double>(begin: value as double?),
    ) as Tween<double>?;
  }
}

class _SettingsNavScope extends InheritedWidget {
  const _SettingsNavScope({
    required this.state,
    required super.child,
  });

  final _SettingsNavState state;

  @override
  bool updateShouldNotify(_SettingsNavScope oldWidget) => false;
}

class SettingsMainPage extends StatelessWidget {
  const SettingsMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 40),
          child: Text(
            'Settings',
            style: DefaultTextStyle.of(context).style.copyWith(fontSize: 35),
          ),
        ),
        Setting(
          text: 'Accounts & Sign In',
          icon: Icons.account_circle_outlined,
          autofocus: true,
          isActivePane: true,
          onGainsFocus: () {
            SettingsNav.of(context).setNext(const AccountsPage());
          },
        ),
      ],
    );
  }
}

class AccountsPage extends StatefulWidget {
  const AccountsPage({
    super.key,
  });

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  bool _loading = true;
  GoogleSignInAccount? _account;

  Future<void> _handleCurrentUserChanged() async {
    setState(() {
      _account = AuthBinding.instance.maybeUser;
    });
  }

  List<Widget> _getSignedInAccountRows() {
    final TextStyle baseStyle = DefaultTextStyle.of(context).style;
    List<Widget> results = [];
    if (_account != null) {
      final String initial = _account!.email.replaceAll(RegExp(r'[^a-zA-Z]'), '').substring(0, 1).toUpperCase();
      CircleAvatar avatar = CircleAvatar(
        backgroundColor: const Color(0xffcc0000),
        child: Text(initial),
      );
      Widget nameAndEmail = Text(
        _account!.email,
        style: baseStyle.copyWith(
          fontSize: 12,
          color: const Color(0xff686c72),
        ),
      );

      if (_account!.displayName != null) {
        final String initials = _account!.displayName!.replaceAll(RegExp(r'[^A-Z]'), '').substring(0, 2);
        avatar = CircleAvatar(
          backgroundColor: const Color(0xffcc0000),
          child: Text(initials),
        );
        nameAndEmail = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _account!.displayName!,
              style: baseStyle.copyWith(
                fontSize: 12,
                color: const Color(0xff979aa0),
              ),
            ),
            nameAndEmail,
          ],
        );
      }

      if (_account!.photoUrl != null) {
        avatar = CircleAvatar(
          backgroundImage: NetworkImage(_account!.photoUrl!),
        );
      }

      results.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 10, 10),
          child: Row(
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: Center(child: avatar),
              ),
              const SizedBox(width: 10),
              nameAndEmail,
            ],
          ),
        ),
      );
    }
    return results;
  }

  @override
  void initState() {
    super.initState();
    AuthBinding.instance.onUserChanged = _handleCurrentUserChanged;
    AuthBinding.instance.signInSilently().then((_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    AuthBinding.instance.onUserChanged = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 40),
          child: Text(
            'Accounts & Sign In',
            style: DefaultTextStyle.of(context).style.copyWith(
              color: const Color(0xff979aa0),
              fontSize: 34,
            ),
          ),
        ),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (!_loading) ...[
          ..._getSignedInAccountRows(),
          Setting(
            text: 'Add an account',
            icon: Icons.add,
            isActivePane: false,
            onGoForward: () {
              AuthBinding.instance.signIn();
            },
            onGainsFocus: () {
              SettingsNav.of(context).setNext(SettingsPlaceholder());
            },
          ),
        ],
      ],
    );
    return result;
  }
}

class SettingsPlaceholder extends StatelessWidget {
  const SettingsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: SettingsNav.secondaryBgColor,
    );
  }
}

class Setting extends StatefulWidget {
  const Setting({
    super.key,
    required this.text,
    required this.icon,
    this.autofocus = false,
    this.isActivePane = false,
    this.onGoForward,
    this.onGoBackward,
    this.onGainsFocus,
  });

  final String text;
  final IconData icon;
  final bool autofocus;
  final bool isActivePane;
  final VoidCallback? onGoForward;
  final VoidCallback? onGoBackward;
  final VoidCallback? onGainsFocus;

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

  static final Set<LogicalKeyboardKey> _goForwardKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.tab,
  };

  static final Set<LogicalKeyboardKey> _goBackwardKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.escape,
  };

  void _handleFocusChanged(bool hasFocus) {
    if (hasFocus != _hasFocus) {
      setState(() {
        _hasFocus = hasFocus;
      });
      if (hasFocus) {
        widget.onGainsFocus?.call();
      }
    }
  }

  void _defaultGoForward() {
    final SettingsNavController controller = SettingsNav.of(context);
    if (controller.canMoveForward) {
      controller.forward();
    }
  }

  void _defaultGoBackward() {
    final SettingsNavController controller = SettingsNav.of(context);
    if (controller.canMoveBackward) {
      controller.backward();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    KeyEventResult result = KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      if (_goForwardKeys.contains(event.logicalKey)) {
        SystemSound.play(SystemSoundType.click);
        VoidCallback callback = widget.onGoForward ?? _defaultGoForward;
        callback();
        result = KeyEventResult.handled;
      } else if (_goBackwardKeys.contains(event.logicalKey)) {
        SystemSound.play(SystemSoundType.click);
        VoidCallback callback = widget.onGoBackward ?? _defaultGoBackward;
        callback();
        result = KeyEventResult.handled;
      } else {
        debugPrint('Not handling key event: ${event.logicalKey}');
      }
    }

    return result;
  }

  void _handleTap() {
    widget.onGoForward?.call();
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(
      descendantsAreFocusable: false,
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: _handleFocusChanged,
      autofocus: widget.autofocus,
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: _handleTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _hasFocus ? const Color(0xffe8ebed) : const Color(0x00000000),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: _hasFocus ? const Color(0xff000000) : widget.isActivePane ? const Color(0xffe8eaed) : const Color(0xff979aa0),
              fontSize: widget.isActivePane? 15 : 16,
              letterSpacing: -0.5,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 10, 10),
              child: Row(
                children: [
                  SizedBox(
                    width: widget.isActivePane ? 40 : 46,
                    height: widget.isActivePane ? 40 : 46,
                    child: Stack(
                      fit: StackFit.passthrough,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _hasFocus ? const Color(0x305383ec) : widget.isActivePane ? const Color(0xff263041) : const Color(0xff232b39),
                          ),
                        ),
                        Icon(
                          widget.icon,
                          color: _hasFocus ? const Color(0xff5383ec) : widget.isActivePane ? const Color(0xffaeb2b9) : const Color(0xff747981),
                          size: widget.isActivePane ? 22 : 29,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: widget.isActivePane ? 12 : 14),
                  SizedBox(
                    height: 40,
                    child: Align(
                      alignment: const Alignment(0, -0.1),
                      child: Text(widget.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
