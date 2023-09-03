import 'package:flutter/foundation.dart';

import 'app.dart';
import '../pages/app.dart';

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
