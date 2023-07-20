import 'dart:convert';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/src/model/files.dart';

import '../model/dream.dart';

import 'app.dart';

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
      if (event.logicalKey == LogicalKeyboardKey.digit0 || event.logicalKey == LogicalKeyboardKey.keyD) {
        PhotosApp.of(context).toggleShowDebugInfo();
      } else if (event.logicalKey == LogicalKeyboardKey.digit9 || event.logicalKey == LogicalKeyboardKey.keyW) {
        final DateTime now = DateTime.now();
        final String basename = 'photos_${now.toIso8601String()}';
        final Uint8List bytes = await FilesBinding.instance.photosFile.readAsBytes();
        debugPrint('Read photos file; got ${bytes.length} bytes; writing to downloads...');
        await DreamBinding.instance.writeFileToDownloads(basename, bytes);
      } else {
        DreamBinding.instance.wakeUp();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!PhotosApp.of(context).isInteractive) {
      SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
        focusNode.requestFocus();
      });
    }
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
