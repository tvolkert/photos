import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';

import 'files.dart';

class AppBinding extends AppBindingBase with FilesBinding {
  static bool _debugInitialized = false;

  /// Creates and initializes the application binding if necessary.
  ///
  /// Applications should call this method before calling [runApp].
  static Future<void> ensureInitialized() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (FilesBinding.instance == null) {
      await AppBinding().initInstances();
    }
  }
}

abstract class AppBindingBase {
  static bool _debugInitialized = false;

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
}
