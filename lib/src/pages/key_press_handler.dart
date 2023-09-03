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
          final Uint8List bytes = await FilesBinding.instance.photosFile.readAsBytes();
          debugPrint('Read photos file; got ${bytes.length} bytes; writing to downloads...');
          await DreamBinding.instance.writeFileToDownloads(basename, bytes);
        }();
      // } else if (event.logicalKey == LogicalKeyboardKey.digit1) {
      //   PhotosApp.of(context).addError(StateError('state error'), StackTrace.current);
      //   result = KeyEventResult.handled;
      // } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
      //   PhotosApp.of(context).setLibraryUpdateStatus((PhotosLibraryUpdateStatus.idle, null));
      //   result = KeyEventResult.handled;
      // } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
      //   PhotosApp.of(context).setLibraryUpdateStatus((PhotosLibraryUpdateStatus.updating, null));
      //   int i = 10;
      //   Timer.periodic(const Duration(milliseconds: 500), (timer) {
      //     if (i < 1) {
      //       timer.cancel();
      //     }
      //     PhotosApp.of(context).setLibraryUpdateStatus((PhotosLibraryUpdateStatus.updating, '$i left to go'));
      //     i--;
      //   });
      //   result = KeyEventResult.handled;
      // } else if (event.logicalKey == LogicalKeyboardKey.digit4) {
      //   PhotosApp.of(context).setLibraryUpdateStatus((PhotosLibraryUpdateStatus.success, null));
      //   result = KeyEventResult.handled;
      // } else if (event.logicalKey == LogicalKeyboardKey.digit5) {
      //   PhotosApp.of(context).setLibraryUpdateStatus((PhotosLibraryUpdateStatus.error, null));
      //   result = KeyEventResult.handled;
      } else {
        DreamBinding.instance.wakeUp();
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
    return Focus(
      focusNode: focusNode,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }
}
