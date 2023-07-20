import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:photos/src/model/auth.dart';

import '../model/dream.dart';
import '../model/photos_library_api_model.dart';

import 'debug.dart';
import 'error_display.dart';
import 'key_press_handler.dart';

class PhotosApp extends StatefulWidget {
  const PhotosApp({
    super.key,
    required this.interactive,
    required this.apiModel,
    required this.child,
  });

  final bool interactive;
  final PhotosLibraryApiModel apiModel;
  final Widget child;

  @override
  State<PhotosApp> createState() => _PhotosAppState();

  static PhotosAppController of(BuildContext context) {
    _PhotosAppScope scope = context.dependOnInheritedWidgetOfExactType<_PhotosAppScope>()!;
    return scope.state;
  }
}

/// Instances of this class can be obtained by calling [PhotosApp.of].
abstract class PhotosAppController {
  /// The Google Photos API model.
  PhotosLibraryApiModel get apiModel;

  /// Tells whether this content producer is running in interactive mode.
  ///
  /// When interactive mode is false, the app was started automatically (it is
  /// running as a screensaver), and it is expected that the user is able to
  /// stop the app with simple keypad interaction.
  bool get isInteractive;

  /// Tells whether debug info is currently being shown to the user.
  bool get isShowDebugInfo;

  /// Toggles whether debug info is shown to the user.
  void toggleShowDebugInfo();

  /// Adds an error to the list of errors to possibly show the user.
  ///
  /// Errors wll only be shown to the user in debug mode.
  void addError(Object error, StackTrace? stack);
}

class _PhotosAppState extends State<PhotosApp> implements PhotosAppController {
  bool _showDebugInfo = false;
  final List<(Object, StackTrace?)> _errors = <(Object, StackTrace?)>[];

  void _removeLastError() {
    assert(() {
      if (mounted && _errors.isNotEmpty) {
        setState(() {
          _errors.removeLast();
        });
      }
      return true;
    }());
  }

  void _handleApiModelUpdate() {
    setState(() {
      // no-op; rebuild will pick up the latest api state.
    });
  }

  @override
  PhotosLibraryApiModel get apiModel => widget.apiModel;

  @override
  bool get isInteractive => widget.interactive;

  @override
  bool get isShowDebugInfo {
    bool showDebugInfo = _showDebugInfo;
    assert(() {
      showDebugInfo |= forceShowDebugInfo;
      return true;
    }());
    return showDebugInfo;
  }

  @override
  void toggleShowDebugInfo() {
    setState(() {
      _showDebugInfo = !_showDebugInfo;
      assert(() {
        debugInvertOversizedImages = !debugInvertOversizedImages;
        return true;
      }());
    });
  }

  @override
  void addError(Object error, StackTrace? stack) {
    assert(() {
      setState(() {
        _errors.add((error, stack));
        Timer(const Duration(seconds: 5), _removeLastError);
      });
      return true;
    }());
  }

  @override
  void initState() {
    super.initState();
    widget.apiModel.addListener(_handleApiModelUpdate);
  }

  @override
  void dispose() {
    widget.apiModel.removeListener(_handleApiModelUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PhotosAppScope(
      state: this,
      apiState: widget.apiModel.state,
      isShowDebugInfo: _showDebugInfo,
      child: MediaQuery.fromView(
        view: View.of(context),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Color(0xffffffff),
              fontSize: 10,
            ),
            child: ClipRect(
              child: Stack(
                fit: StackFit.passthrough,
                children: <Widget>[
                  KeyPressHandler(child: widget.child),
                  if (_errors.isNotEmpty) ErrorDisplay(errors: _errors),
                  if (isShowDebugInfo) const _DebugInfo(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DebugInfo extends StatefulWidget {
  const _DebugInfo({super.key});

  @override
  State<_DebugInfo> createState() => _DebugInfoState();
}

class _DebugInfoState extends State<_DebugInfo> {
  Map<String, dynamic>? _deviceInfo;
  late Timer _deviceInfoRefreshTimer;

  static const Duration _deviceInfoRefreshRate = Duration(seconds: 3);

  void _reloadDeviceInfo() async {
    Map<String, dynamic> info = await DreamBinding.instance.getDeviceInfo();
    if (mounted) {
      setState(() {
        _deviceInfo = info;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _deviceInfoRefreshTimer = Timer.periodic(_deviceInfoRefreshRate, (Timer timer) {
      _reloadDeviceInfo();
    });
    _reloadDeviceInfo();
  }

  @override
  void dispose() {
    _deviceInfoRefreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQueryData = MediaQuery.of(context);
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: PerformanceOverlay.allEnabled(
            checkerboardOffscreenLayers: true,
            checkerboardRasterCacheImages: true,
            rasterizerThreshold: 1,
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Screen size: ${mediaQueryData.size.width} x ${mediaQueryData.size.height}'),
              Text('Device pixel ratio: ${mediaQueryData.devicePixelRatio}'),
              Text('Max heap size (MB): ${_deviceInfo?['maxHeapSizeMB']}'),
              Text('Available heap size (MB): ${_deviceInfo?['availHeapSizeMB']}'),
              Text('Total system RAM (MB): ${_deviceInfo?['totalSystemRamMB']}'),
              Text('Available system RAM (MB): ${_deviceInfo?['availableSystemRamMB']}'),
              Text('GLES version (`ConfigurationInfo.getGlEsVersion()`): ${_deviceInfo?['gpuGlesVersion']}'),
              Text('GL vendor: ${_deviceInfo?['glVendor']}'),
              Text('GL renderer: ${_deviceInfo?['glRenderer']}'),
              Text('GL version (`GL10.glGetString(GL10.GL_VERSION)`): ${_deviceInfo?['glVersion']}'),
              Text('Image cache size (count): ${imageCache.currentSize}'),
              Text('Image cache size (MB): ${imageCache.currentSizeBytes / (1024 * 1024)}'),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotosAppScope extends InheritedWidget {
  const _PhotosAppScope({
    required this.state,
    required this.apiState,
    required this.isShowDebugInfo,
    required Widget child,
  }) : super(child: child);

  final _PhotosAppState state;
  final PhotosLibraryApiState apiState;
  final bool isShowDebugInfo;

  @override
  bool updateShouldNotify(_PhotosAppScope old) {
    return isShowDebugInfo != old.isShowDebugInfo
        || apiState != old.apiState;
  }
}
