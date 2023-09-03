import 'dart:async';

import 'package:flutter/material.dart' show CircularProgressIndicator, Icons;
import 'package:flutter/widgets.dart' hide Notification;

import '../extensions/list.dart';
import '../model/photos_library_api_model.dart';
import '../model/ui.dart';

import 'debug.dart';
import 'key_press_handler.dart';
import 'notifications.dart';

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
  ///
  /// If non-null, the `message` may be shown to the user in the status display.
  void setLibraryUpdateStatus((PhotosLibraryUpdateStatus status, String? message) status);

  /// Sets an optional notification to be shown in the bottom bar.
  void setBottomBarNotification(Notification? notification);
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
  Notification? _bottomBarNotification;

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
        _errors.insert(0, (error, stack));
        Timer(const Duration(seconds: 10), _removeLastError);
      });
      return true;
    }());
  }

  @override
  void setLibraryUpdateStatus((PhotosLibraryUpdateStatus, String?) status) {
    var (value, message) = status;
    if (_updateStatus != value || _updateMessage != message) {
      setState(() {
        _updateStatus = value;
        _updateMessage = message;
      });
    }
  }

  @override
  void setBottomBarNotification(Notification? notification) {
    setState(() {
      _bottomBarNotification = notification;
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
                  NotificationsPanel(
                    upperLeft: ErrorsNotification(_errors.clone()),
                    upperRight: UpdateStatusNotification(_updateStatus, _updateMessage),
                    bottomBar: _bottomBarNotification,
                  ),
                  if (isShowDebugInfo) const DebugInfo(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UpdateStatusNotification extends Notification {
  const UpdateStatusNotification(this.status, this.message);

  final PhotosLibraryUpdateStatus status;
  final String? message;
  
  @override
  bool shouldUpdate(Notification? other) {
    bool update = super.shouldUpdate(other);
    if (!update) {
      assert(other is UpdateStatusNotification);
      other as UpdateStatusNotification;
      update = status != other.status || message != other.message;
    }
    return update;
  }

  @override
  Widget? build(BuildContext context) {
    Widget icon;
    String text;
    switch (status) {
      case PhotosLibraryUpdateStatus.idle:
        return null;
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
        if (message != null) {
          text += ' $message';
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
    return Row(
      children: <Widget>[
        icon,
        const SizedBox(width: 10),
        Text(text, maxLines: 1),
      ],
    );
  }

  @override
  toString() => 'UpdateStatusNotification(status=$status; message=$message)';
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
