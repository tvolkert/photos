import 'package:flutter/foundation.dart';

import 'app.dart';

abstract class AppController {
  /// Tells whether debug info is currently being shown to the user.
  bool get isShowDebugInfo;

  /// Toggles whether debug info is shown to the user.
  void toggleShowDebugInfo();

  /// Adds an error to the list of errors to possibly show the user.
  ///
  /// If [showErrorsInReleaseMode] is true, then errors will always be shown
  /// to the user. If it is false, then errors will be shown in debug mode
  /// only.
  void addError(Object error, StackTrace? stack);
}

mixin UiBinding on AppBindingBase {
  /// The singleton instance of this object.
  static late UiBinding _instance;
  static UiBinding get instance => _instance;

  AppController? _controller;
  AppController? get controller => _controller;
  set controller(AppController? value) {
    assert(_controller == null || value == null);
    _controller = value;
  }

  T? getTypedController<T extends AppController>() {
    return _controller as T?;
  }

  @override
  @protected
  @mustCallSuper
  Future<void> initInstances() async {
    await super.initInstances();
    _instance = this;
  }
}
