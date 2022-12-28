import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:flutter/widgets.dart';

import '../photos_library_api/media_item.dart';
import '../photos_library_api/media_metadata.dart';

import 'files.dart';
import 'photo.dart';
import 'photos_library_api_model.dart';
import 'random.dart';

abstract class PhotoProducer {
  /// Creates a [PhotoProducer] that produces photos from Google Photos using
  /// the specified [model] object.
  ///
  /// If the Google Photos API fails for any reason, this photo producer will
  /// fall back to producing photos that are pulled statically from assets that
  /// are bundled with this app (or, as a last resort, Todd's profile pic).
  factory PhotoProducer(PhotosLibraryApiModel model) = _ApiPhotoCardProducer;

  /// Creates a [PhotoProducer] that produces photos that are pulled statically
  /// from assets that are bundled with this app.
  factory PhotoProducer.asset() = _StaticPhotoProducer;

  const PhotoProducer._();

  /// Produces a [Photo] that fits within the specified size constraints.
  Future<Photo> produce(Size sizeConstraints);
}

class _ApiPhotoCardProducer extends PhotoProducer {
  _ApiPhotoCardProducer(this.model) : super._();

  final PhotosLibraryApiModel model;
  final List<MediaItem> _queue = <MediaItem>[];

  static const _kBatchSize = 50;

  Future<void> _queueItems() async {
    final FilesBinding files = FilesBinding.instance;

    if (files.photosFile.existsSync()) {
      final int count = files.photosFile.statSync().size ~/ PhotosLibraryApiModel.kBlockSize;
      final List<String> mediaItemIds = <String>[];
      final RandomAccessFile handle = await files.photosFile.open();
      try {
        for (int i = 0; i < _kBatchSize; i++) {
          final int offset = random.nextInt(count) * PhotosLibraryApiModel.kBlockSize;
          handle.setPositionSync(offset);
          final List<int> bytes = _unpadBytes(await handle.read(PhotosLibraryApiModel.kBlockSize));
          final String mediaItemId = utf8.decode(bytes);
          mediaItemIds.add(mediaItemId);
        }
      } finally {
        handle.closeSync();
      }
      assert(mediaItemIds.length == _kBatchSize);
      Iterable<MediaItem> items = await model.getMediaItems(mediaItemIds);
      items = items.where((MediaItem item) => item.size != null);
      assert(() {
        if (items.length != _kBatchSize) {
          debugPrint('Expecting $_kBatchSize items, but retrieved ${items.length}');
        }
        return true;
      }());
      _queue.insertAll(0, items);
    }
  }

  List<int> _unpadBytes(Uint8List bytes) {
    final int? paddingStart = _getPaddingStart(bytes);
    return paddingStart == null ? bytes : bytes.sublist(0, paddingStart);
  }

  int? _getPaddingStart(Uint8List bytes) {
    bool matchAt(int index) {
      assert(index >= 0);
      assert(index + PhotosLibraryApiModel.kPaddingStart.length <= bytes.length);
      for (int i = 0; i < PhotosLibraryApiModel.kPaddingStart.length; i++) {
        if (bytes[index + i] != PhotosLibraryApiModel.kPaddingStart[i]) {
          return false;
        }
      }
      return true;
    }
    for (int j = 0; j <= bytes.length - PhotosLibraryApiModel.kPaddingStart.length; j++) {
      if (matchAt(j)) {
        return j;
      }
    }
    return null;
  }

  @override
  Future<Photo> produce(Size sizeConstraints) async {
    if (_queue.isEmpty) {
      await _queueItems();
    }

    MediaItem mediaItem = _queue.isEmpty ? await _produceStaticMediaItem() : _queue.removeLast();
    return await _loadPhoto(mediaItem, sizeConstraints);
  }
}

class _StaticPhotoProducer extends PhotoProducer {
  const _StaticPhotoProducer() : super._();

  @override
  Future<Photo> produce(Size sizeConstraints) async {
    return await _nextAssetPhoto(sizeConstraints);
  }
}

Future<MediaItem> _produceStaticMediaItem() async {
  const MediaItem sample = MediaItem(
    id: 'test',
    baseUrl:
    'https://lh3.googleusercontent.com/ogw/ADea4I4W_CNuQmCCPTLweMp6ndpZmVOgwL7GCClptOUZG6M',
    mediaMetadata: MediaMetadata(
      width: '429',
      height: '429',
    ),
  );
  return sample;
}

Future<Photo> _loadPhoto(MediaItem mediaItem, Size size) async {
  const int maxAttempts = 3;
  Size photoSize = applyBoxFit(BoxFit.scaleDown, mediaItem.size!, size).destination;
  Uint8List? bytes;
  for (int attempt = 1; bytes == null && attempt <= maxAttempts; attempt++) {
    try {
      bytes = await mediaItem.load(photoSize);
    } catch (error, stack) {
      if (attempt == maxAttempts) {
        debugPrintStack(
          stackTrace: stack,
          label: 'Could not load ${mediaItem.baseUrl} ($error); giving up...',
        );
      } else {
        await Future.delayed(Duration(milliseconds: math.pow(2, attempt + 4).toInt()));
      }
    }
  }

  if (bytes == null) {
    // We were unable to load the photo over the network; fall back to an asset
    return _nextAssetPhoto(size);
  } else {
    return Photo(
      mediaItem,
      photoSize / WidgetsBinding.instance.window.devicePixelRatio,
      WidgetsBinding.instance.window.devicePixelRatio,
      bytes,
    );
  }
}

const List<AssetImage> _assetImages = <AssetImage>[
  AssetImage('assets/DSC_0013.jpg'),
  AssetImage('assets/DSC_0021-2.jpg'),
  AssetImage('assets/DSC_0135-2.jpg'),
  AssetImage('assets/DSC_0256.jpg'),
  AssetImage('assets/IMG_20150220_174328408_HDR.jpg'),
  AssetImage('assets/Image13.jpeg'),
  AssetImage('assets/P1010073.jpg'),
  AssetImage('assets/TCV_7314.jpg'),
  AssetImage('assets/TCV_8294.jpg'),
];

int _assetIndex = 0;
int get _nextAssetIndex {
  int index = _assetIndex;
  _assetIndex = (_assetIndex + 1) % _assetImages.length;
  return index;
}

Future<Photo> _nextAssetPhoto(Size size) async {
  final AssetImage asset = _assetImages[_nextAssetIndex];
  final ImageConfiguration configuration = ImageConfiguration(
    bundle: asset.bundle,
    devicePixelRatio: WidgetsBinding.instance.window.devicePixelRatio,
    textDirection: TextDirection.ltr,
    size: size,
  );
  final ImageStream stream = asset.resolve(configuration);
  final Completer<Uint8List> streamBytes = Completer<Uint8List>();
  stream.addListener(ImageStreamListener((ImageInfo image, bool synchronousCall) async {
    // TODO: we're doing work to convert to bytes here, only to then do work
    // to go back to the image later. Maybe there's a better data
    // representation that would save the extra work.
    ByteData? byteData = await image.image.toByteData();
    if (byteData != null) {
      streamBytes.complete(byteData.buffer.asUint8List());
    } else {
      // Something has gone very wrong. Fall back to using bytes of a
      // statically compiled error image.
      streamBytes.complete(Uint8List.fromList(_errorImageBytes));
    }
  }));
  return Photo(
    null,
    size,
    WidgetsBinding.instance.window.devicePixelRatio,
    await streamBytes.future,
  );
}

// TODO: encode proper bytes here
const List<int> _errorImageBytes = <int>[];
