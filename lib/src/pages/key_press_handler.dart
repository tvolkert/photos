import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../model/dream.dart';

import 'app_container.dart';

class KeyPressHandler extends StatefulWidget {
  const KeyPressHandler({super.key, required this.child});

  final Widget child;

  @override
  State<KeyPressHandler> createState() => _KeyPressHandlerState();
}

class _KeyPressHandlerState extends State<KeyPressHandler> {
  late FocusNode focusNode;

  void _handleKeyEvent(KeyEvent event) async {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.digit0) {
        PhotosApp.of(context).toggleShowDebugInfo();
      } else {
        DreamBinding.instance.wakeUp();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
    SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
      focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: focusNode,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }
}
