import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/src/model/dream.dart';

import 'auth.dart';
import 'files.dart';
import 'photos_api.dart';
import 'ui.dart';

class PhotosAppBinding extends AppBindingBase with ChangeNotifier, FilesBinding, DreamBinding, AuthBinding, UiBinding, PhotosApiBinding {
  /// Creates and initializes the application binding if necessary.
  ///
  /// Applications should call this method before calling [runApp].
  static Future<void> ensureInitialized() async {
    // [AppBinding.initInstances] may rely on things like [ServicesBinding].
    WidgetsFlutterBinding.ensureInitialized();
    await PhotosAppBinding().initialized;
  }
}

class SettingsAppBinding extends AppBindingBase with FilesBinding, DreamBinding, AuthBinding, UiBinding {
  /// Creates and initializes the application binding if necessary.
  ///
  /// Applications should call this method before calling [runApp].
  static Future<void> ensureInitialized() async {
    // [AppBinding.initInstances] may rely on things like [ServicesBinding].
    WidgetsFlutterBinding.ensureInitialized();
    await SettingsAppBinding().initialized;
  }
}

abstract class AppBindingBase {
  /// Default abstract constructor for application bindings.
  ///
  /// First calls [initInstances] to have bindings initialize their
  /// instance pointers and other state.
  AppBindingBase() {
    developer.Timeline.startSync('App initialization');

    assert(!_debugInitialized);
    _initialized = initInstances();
    assert(_debugInitialized);

    developer.postEvent('Photos.AppInitialization', <String, String>{});
    _initialized.whenComplete(() {
      developer.Timeline.finishSync();
    });
  }

  static bool _debugInitialized = false;

  /// A future that completes once this app binding has been fully initialized.
  late Future<void> _initialized;
  Future<void> get initialized => _initialized;

  /// The initialization method. Subclasses override this method to hook into
  /// the app. Subclasses must call `super.initInstances()`.
  ///
  /// By convention, if the service is to be provided as a singleton, it should
  /// be exposed as `MixinClassName.instance`, a static getter that returns
  /// `MixinClassName._instance`, a static field that is set by
  /// `initInstances()`.
  @protected
  @mustCallSuper
  Future<void> initInstances() async {
    assert(!_debugInitialized);
    assert(() {
      _debugInitialized = true;
      return true;
    }());
  }

  @override
  String toString() => '<${objectRuntimeType(this, 'AppBindingBase')}>';
}
