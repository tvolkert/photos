import 'package:flutter/foundation.dart';

import 'app.dart';
import '../pages/app.dart';

mixin UiBinding on AppBindingBase {
  /// The singleton instance of this object.
  static late UiBinding _instance;
  static UiBinding get instance => _instance;

  PhotosAppController? _controller;
  PhotosAppController? get controller => _controller;
  set controller(PhotosAppController? value) {
    assert(_controller == null || value == null);
    _controller = value;
  }

  @override
  @protected
  @mustCallSuper
  Future<void> initInstances() async {
    await super.initInstances();
    _instance = this;
  }
}
