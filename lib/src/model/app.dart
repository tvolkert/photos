import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/src/model/dream.dart';

import 'files.dart';

class AppBinding extends AppBindingBase with FilesBinding, DreamBinding {
  /// Creates and initializes the application binding if necessary.
  ///
  /// Applications should call this method before calling [runApp].
  static Future<void> ensureInitialized() async {
    await AppBinding().initialized;
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
    developer.Timeline.finishSync();
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
    // This lives here instead of in `AppBinding.ensureInitialized()` to ensure
    // that the widgets binding is initialized before subclass implementations
    // of `initInstances()` (which may rely on things like `ServicesBinding`).
    WidgetsFlutterBinding.ensureInitialized();
  }

  @override
  String toString() => '<${objectRuntimeType(this, 'AppBindingBase')}>';
}
