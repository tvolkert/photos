import 'dart:async';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';

mixin FilesBinding on AppBindingBase {
  /// The singleton instance of this object.
  static FilesBinding _instance;
  static FilesBinding get instance => _instance;

  File _nextPageTokenFile;
  File get nextPageTokenFile => _nextPageTokenFile;

  File _photosFile;
  File get photosFile => _photosFile;

  File _countFile;
  File get countFile => _countFile;

  @override
  @protected
  @mustCallSuper
  Future<void> initInstances() async {
    await super.initInstances();
    _instance = this;

    FileSystem fs = const LocalFileSystem();
    Directory documentsDirectory;
    try {
      documentsDirectory = fs.directory(await getApplicationDocumentsDirectory());
    } catch (error) {
      fs = MemoryFileSystem();
      documentsDirectory = fs.directory('documents')..createSync();
    }
    _nextPageTokenFile = documentsDirectory.childFile('nextPageToken');
    _photosFile = documentsDirectory.childFile('photos');
    _countFile = documentsDirectory.childFile('count');
  }
}
