import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'nav.dart';

class SettingsPlaceholder extends StatelessWidget {
  const SettingsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: SettingsNav.secondaryBgColor,
    );
  }
}

class IconSetting extends StatelessWidget {
  const IconSetting({
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
  Widget build(BuildContext context) {
    return Setting(
      key: key,
      autofocus: autofocus,
      isActivePane: isActivePane,
      onGoForward: onGoForward,
      onGoBackward: onGoBackward,
      onGainsFocus: onGainsFocus,
      leading: (BuildContext context, bool hasFocus) {
        return Icon(
          icon,
          color: hasFocus ? const Color(0xff5383ec) : isActivePane ? const Color(0xffaeb2b9) : const Color(0xff747981),
          size: isActivePane ? 22 : 29,
        );
      },
      body: (BuildContext context, bool hasFocus) {
        return Text(text);
      },
    );
  }
}

typedef HasFocusBuilder = Widget Function(BuildContext context, bool hasFocus);

class Setting extends StatefulWidget {
  const Setting({
    super.key,
    this.autofocus = false,
    this.isActivePane = false,
    this.onGoForward,
    this.onGoBackward,
    this.onGainsFocus,
    required this.leading,
    required this.body,
  });

  final bool autofocus;
  final bool isActivePane;
  final VoidCallback? onGoForward;
  final VoidCallback? onGoBackward;
  final VoidCallback? onGainsFocus;
  final HasFocusBuilder leading;
  final HasFocusBuilder body;

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
        final VoidCallback callback = widget.onGainsFocus ?? _defaultGainsFocus;
        callback();
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

  void _defaultGainsFocus() {
    SettingsNav.of(context).setNext(const SettingsPlaceholder());
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
                        widget.leading(context, _hasFocus),
                      ],
                    ),
                  ),
                  SizedBox(width: widget.isActivePane ? 12 : 14),
                  SizedBox(
                    height: 40,
                    child: Align(
                      alignment: const Alignment(0, -0.1),
                      child: widget.body(context, _hasFocus),
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
