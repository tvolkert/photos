import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:photos/src/model/dream.dart';
import 'package:photos/src/model/files.dart';

import 'app.dart';

class KeyPressHandler extends StatefulWidget {
  const KeyPressHandler({super.key, required this.child});

  final Widget child;

  @override
  State<KeyPressHandler> createState() => _KeyPressHandlerState();
}

class _KeyPressHandlerState extends State<KeyPressHandler> {
  late FocusNode focusNode;

  KeyEventResult _handleKeyEvent(FocusNode focusNode, KeyEvent event) {
    KeyEventResult result = KeyEventResult.ignored;
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.digit0 || event.logicalKey == LogicalKeyboardKey.keyD) {
        PhotosApp.of(context).toggleShowDebugInfo();
        result = KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.digit9 || event.logicalKey == LogicalKeyboardKey.keyW) {
        final DateTime now = DateTime.now();
        final String basename = 'photos_${now.toIso8601String()}';
        result = KeyEventResult.handled;
        () async {
          if (FilesBinding.instance.photosFile.existsSync()) {
            final Uint8List bytes = await FilesBinding.instance.photosFile.readAsBytes();
            debugPrint('Read photos file; got ${bytes.length} bytes; writing to downloads...');
            await DreamBinding.instance.writeFileToDownloads(basename, bytes);
          } else {
            debugPrint('${FilesBinding.instance.photosFile.path} does not exist');
          }
        }();
      } else if (event.logicalKey == LogicalKeyboardKey.digit8 || event.logicalKey == LogicalKeyboardKey.keyP) {
        PhotosApp.of(context).toggleShowPerformanceMetrics();
        result = KeyEventResult.handled;
      }
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    return Focus(
      focusNode: focusNode,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }
}
