import 'package:flutter/material.dart' show CircularProgressIndicator, Icons;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide Notification;
import 'package:photos/src/model/content_provider.dart';
import 'package:photos/src/model/dream.dart';

import 'package:photos/src/model/photos_api.dart';
import 'package:photos/src/model/ui.dart';
import 'package:photos/src/ui/common/app.dart';
import 'package:photos/src/ui/common/debug.dart';
import 'package:photos/src/ui/common/notifications.dart';

import 'shortcuts.dart';

class PhotosApp extends StatefulWidget {
  const PhotosApp({super.key});

  @override
  State<PhotosApp> createState() => _PhotosAppState();

  static PhotosAppController of(BuildContext context) {
    _PhotosAppScope scope = context.dependOnInheritedWidgetOfExactType<_PhotosAppScope>()!;
    return scope.state;
  }
}

/// Instances of this class can be obtained by calling [PhotosApp.of].
abstract class PhotosAppController extends AppController {
  /// The current state of the app.
  PhotosLibraryApiState get state;

  /// Tells whether the performance metrics panel is currently being shown to
  /// the user.
  bool get isShowPerformanceMetrics;

  /// Toggles whether the performance metrics pabel is shown to the user.
  void toggleShowPerformanceMetrics();

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

class _ClearMetricsNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}

class _PhotosAppState extends State<PhotosApp> with AppControllerMixin<PhotosApp> implements PhotosAppController {
  late PhotosLibraryApiState _state;
  PhotosLibraryUpdateStatus _updateStatus = PhotosLibraryUpdateStatus.idle;
  String? _updateMessage;
  Notification? _bottomBarNotification;
  bool _showPerformanceMetrics = false;
  final _ClearMetricsNotifier _clearPerformanceMetricsNotifier = _ClearMetricsNotifier();
  WidgetBuilder? _performanceMetricsNotification;
  late PhotosShortcutManager _shortcutManager;

  void _handleApiModelUpdate() {
    setState(() {
      _state = PhotosApiBinding.instance.state;
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode focusNode, KeyEvent event) {
    if (event is KeyDownEvent) {
      DreamBinding.instance.wakeUp();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _handleTimingsReport([
    Duration averageBuildTime = Duration.zero,
    Duration averageRasterTime = Duration.zero,
    Duration averageTotalTime = Duration.zero,
    Duration worstBuildTime = Duration.zero,
    Duration worstRasterTime = Duration.zero,
    Duration worstTotalTime = Duration.zero,
    int missedFrames = 0,
  ]) {
    void updateNotification() {
      _performanceMetricsNotification = (BuildContext context) {
        return Text(
          'Average build time: ${averageBuildTime.inMilliseconds}ms\n'
          'Average raster time: ${averageRasterTime.inMilliseconds}ms\n'
          'Average frame time: ${averageTotalTime.inMilliseconds}ms\n'
          'Worst build time: ${worstBuildTime.inMilliseconds}ms\n'
          'Worst raster time: ${worstRasterTime.inMilliseconds}ms\n'
          'Worst frame time: ${worstTotalTime.inMilliseconds}ms\n'
          'Missed frames: $missedFrames'
        );
      };
    }
    if (_showPerformanceMetrics) {
      setState(updateNotification);
    } else {
      updateNotification();
    }
  }

  @override
  PhotosLibraryApiState get state => _state;

  @override
  bool get isShowPerformanceMetrics {
    return isCollectingPerformanceMetrics && _showPerformanceMetrics;
  }

  @override
  void toggleShowPerformanceMetrics() {
    if (!isCollectingPerformanceMetrics) {
      // No-op; metrics can't be shown if they're not being collected.
      return;
    }
    setState(() {
      _showPerformanceMetrics = !_showPerformanceMetrics;
      if (_showPerformanceMetrics) {
        _handleTimingsReport();
        _clearPerformanceMetricsNotifier.notify();
      }
    });
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
    _state = PhotosApiBinding.instance.state;
    _shortcutManager = PhotosShortcutManager();
    PhotosApiBinding.instance.addListener(_handleApiModelUpdate);
  }

  @override
  void dispose() {
    PhotosApiBinding.instance.removeListener(_handleApiModelUpdate);
    _shortcutManager.dispose();
    UiBinding.instance.controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget app = MediaQuery.fromView(
      view: View.of(context),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(
            color: Color(0xffffffff),
            fontSize: 10,
          ),
          child: Focus(
            canRequestFocus: false,
            onKeyEvent: _handleKeyEvent,
            child: Shortcuts.manager(
              manager: _shortcutManager,
              child: ClipRect(
                child: Stack(
                  fit: StackFit.passthrough,
                  children: <Widget>[
                    ContentProviderBinding.instance.buildHome(context),
                    NotificationsPanel(
                      upperLeft: ErrorsNotification(errors),
                      upperRight: _showPerformanceMetrics
                          ? NotificationBuilder(builder: _performanceMetricsNotification)
                          : UpdateStatusNotification(_updateStatus, _updateMessage),
                      bottomBar: _bottomBarNotification,
                    ),
                    if (isShowDebugInfo) const DebugInfo(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (isCollectingPerformanceMetrics) {
      app = PerformanceMonitor(
        onTimingsReport: _handleTimingsReport,
        clearValuesNotifier: _clearPerformanceMetricsNotifier,
        child: app,
      );
    }

    return _PhotosAppScope(
      state: this,
      apiState: _state,
      isShowDebugInfo: isShowDebugInfo,
      child: app,
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
    required super.child,
  });

  final _PhotosAppState state;
  final PhotosLibraryApiState apiState;
  final bool isShowDebugInfo;

  @override
  bool updateShouldNotify(_PhotosAppScope old) {
    return isShowDebugInfo != old.isShowDebugInfo
        || apiState != old.apiState;
  }
}
