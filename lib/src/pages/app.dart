import 'dart:async';

import 'package:flutter/material.dart' show CircularProgressIndicator, Icons;
import 'package:flutter/widgets.dart';

import '../model/dream.dart';
import '../model/photos_library_api_model.dart';
import '../model/ui.dart';

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

  /// Sets the current state of the photos library update.
  void setLibraryUpdateStatus(PhotosLibraryUpdateStatus status);

  /// Sets a message to display to the user containing the current status of
  /// the library update.
  void setLibraryUpdateMessage(String message);
}

enum PhotosLibraryUpdateStatus {
  /// The photos library is up-to-date; no action is being taken.
  idle,

  /// The photos library is actively updating.
  updating,

  /// The photos library has recently successfully completed an update.
  success,

  /// The photos library has recently encountered an error while updating.
  error,
}

class _PhotosAppState extends State<PhotosApp> implements PhotosAppController {
  bool _showDebugInfo = false;
  PhotosLibraryUpdateStatus _updateStatus = PhotosLibraryUpdateStatus.idle;
  String? _updateMessage;
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
  void setLibraryUpdateStatus(PhotosLibraryUpdateStatus status) {
    if (_updateStatus != status) {
      setState(() {
        _updateStatus = status;
      });
    }
  }

  @override
  void setLibraryUpdateMessage(String message) {
    setState(() {
      _updateMessage = message;
    });
  }

  @override
  void initState() {
    super.initState();
    UiBinding.instance.controller = this;
    widget.apiModel.addListener(_handleApiModelUpdate);
  }

  @override
  void dispose() {
    widget.apiModel.removeListener(_handleApiModelUpdate);
    UiBinding.instance.controller = null;
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
                  UpdateStatus(status: _updateStatus, message: _updateMessage),
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

class UpdateStatus extends StatefulWidget {
  const UpdateStatus({
    super.key,
    required this.status,
    this.message,
  });

  final PhotosLibraryUpdateStatus status;
  final String? message;

  @override
  State<StatefulWidget> createState() => UpdateStatusState();
}

class UpdateStatusState extends State<UpdateStatus> {
  PhotosLibraryUpdateStatus? _firstStatus;
  PhotosLibraryUpdateStatus? _secondStatus;
  CrossFadeState _fadeState = CrossFadeState.showFirst;

  static const Duration _fadeDuration = Duration(milliseconds: 250);

  void _updateFirstStatus(PhotosLibraryUpdateStatus? value) => _firstStatus = value;
  void _updateSecondStatus(PhotosLibraryUpdateStatus? value) => _secondStatus = value;
  void _updateOtherStatus(PhotosLibraryUpdateStatus? value) {
    void Function(PhotosLibraryUpdateStatus?) updater = _fadeState == CrossFadeState.showFirst
        ? _updateSecondStatus
        : _updateFirstStatus;
    setState(() {
      updater(value);
    });
  }

  void _toggleFadeState() {
    setState(() {
      _fadeState = _fadeState == CrossFadeState.showFirst
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst;
    });
  }

  Widget _getWidgetFromStatus(PhotosLibraryUpdateStatus? status) {
    Widget icon;
    String text;
    switch (status) {
      case null:
      case PhotosLibraryUpdateStatus.idle:
        return Container();
      case PhotosLibraryUpdateStatus.updating:
        double? size = IconTheme.of(context).size;
        icon = SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator.adaptive(
            backgroundColor: Color(0xff000000),
          ),
        );
        text = 'Updating the photos library. This may take a while.';
        if (widget.message != null) {
          text += ' ${widget.message}';
        }
        break;
      case PhotosLibraryUpdateStatus.success:
        icon = const Icon(Icons.check_circle, color: Color(0xff00cc00));
        text = 'Done updating the photos library.';
        break;
      case PhotosLibraryUpdateStatus.error:
        icon = const Icon(Icons.error, color: Color(0xffcc0000));
        text = 'There was an error updating the photos library.';
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: <Widget>[
              icon,
              const SizedBox(width: 10),
              () {
                Widget result = Text(text, maxLines: 1);
                if (constraints.hasBoundedWidth) {
                  result = Flexible(child: result);
                }
                return result;
              }(),
            ],
          );
        }
      ),
    );
  }

  @override
  void didUpdateWidget(covariant UpdateStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status) {
      _updateOtherStatus(widget.status);
      _toggleFadeState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      right: 10,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xffffffff),
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(
            color: Color(0xff000000),
          ),
          child: AnimatedCrossFade(
            firstChild: _getWidgetFromStatus(_firstStatus),
            secondChild: _getWidgetFromStatus(_secondStatus),
            crossFadeState: _fadeState,
            duration: _fadeDuration,
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeOut,
            sizeCurve: Curves.easeOut,
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
