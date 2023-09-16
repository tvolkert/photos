import 'dart:async';

import 'package:flutter/widgets.dart';

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

  bool isActivePage(BuildContext context);
}

class _SettingsNavEntry {
  _SettingsNavEntry(this.child, {String? debugLabel})
      : focusNode = FocusNode(canRequestFocus: false, debugLabel: debugLabel);

  final Widget child;

  /// This node is used as the [SettingsNavPane.focusNode], at which point
  /// [SettingsNavPane] takes ownership of the node and is responsible for
  /// disposing it.
  final FocusNode focusNode;
}

class _SettingsNavState extends State<SettingsNav> with WidgetsBindingObserver implements SettingsNavController {
  Completer<void>? _scrollingCompleter;
  final List<_SettingsNavEntry> _entries = <_SettingsNavEntry>[];
  late int _currentIndex;

  static const double _splitRatio = 0.58;

  void _focusCurrentEntry() {
    _entries[_currentIndex].focusNode.nextFocus();
  }

  void _handleDoneScrolling() {
    assert(_scrollingCompleter != null);
    _scrollingCompleter!.complete();
    _scrollingCompleter = null;
  }

  bool get isScrolling => _scrollingCompleter != null;

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
    assert(_scrollingCompleter == null);
    _scrollingCompleter = Completer<void>();
    setState(() {
      _currentIndex++;
      _focusCurrentEntry();
    });
    return _scrollingCompleter!.future;
  }

  @override
  Future<void> backward() {
    assert(canMoveBackward);
    assert(_scrollingCompleter == null);
    bool clear = nextEntriesExist;
    _scrollingCompleter = Completer<void>();
    setState(() {
      _currentIndex--;
      _focusCurrentEntry();
    });
    return _scrollingCompleter!.future.then((_) {
      clearWhile(() {
        bool result = clear;
        clear = false;
        return result;
      });
    });
  }

  @override
  void setNext(Widget child) {
    assert(_currentIndex < _entries.length);
    setState(() {
      final _SettingsNavEntry entry = _SettingsNavEntry(child, debugLabel: '${_currentIndex + 1}');
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
  bool isActivePage(BuildContext context) {
    return _entries[_currentIndex].child == context.widget;
  }

  @override
  Future<bool> didPopRoute() async {
    if (isScrolling) {
      await _scrollingCompleter!.future;
    }
    // To ensure that the completer has been nulled out.
    await Future<void>.delayed(const Duration());
    if (canMoveBackward) {
      backward();
      return true;
    } else {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _entries.add(_SettingsNavEntry(widget.root, debugLabel: 'root'));
    _currentIndex = 0;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsNavScope(
      state: this,
      currentIndex: _currentIndex,
      child: _SettingsNavScroller(
        onDoneScrolling: _handleDoneScrolling,
        selectedIndex: _currentIndex,
        child: _SettingsNavChildren(
          index: _currentIndex,
          entries: _entries,
        ),
      ),
    );
  }
}

class _SettingsNavChildren extends StatelessWidget {
  const _SettingsNavChildren({
    required this.index,
    required this.entries,
  });

  final int index;
  final List<_SettingsNavEntry> entries;

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
    return FocusScope(
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

class _SettingsNavScroller extends ImplicitlyAnimatedWidget {
  const _SettingsNavScroller({
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

class SettingsNavScrollerState extends AnimatedWidgetBaseState<_SettingsNavScroller> {
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
    required this.currentIndex,
    required super.child,
  });

  final _SettingsNavState state;
  final int currentIndex;

  @override
  bool updateShouldNotify(_SettingsNavScope oldWidget) => currentIndex != oldWidget.currentIndex;
}
