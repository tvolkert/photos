import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:photos/src/photos_library_api/media_item.dart';

import 'app.dart';

mixin ContentProviderBinding on AppBindingBase {
  /// The singleton instance of this object.
  static late ContentProviderBinding _instance;
  static ContentProviderBinding get instance => _instance;

  @override
  @protected
  @mustCallSuper
  Future<void> initInstances() async {
    await super.initInstances();
    _instance = this;
  }

  Future<void> init();

  Widget buildHome(BuildContext context);

  /// Gets the URL to load this media item at the specified size.
  String getMediaItemUrl(MediaItem item, ui.Size size);
}
