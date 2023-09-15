import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../photos_library_api/media_item.dart';
import '../photos_library_api/media_metadata.dart';

import 'files.dart';
import 'photo.dart';
import 'photos_library_api_model.dart';

abstract class PhotoProducer {
  const PhotoProducer._();

  /// Produces a [Photo] that fits within the specified size constraints.
  Future<Photo> produce({
    required BuildContext context,
    required Size sizeConstraints,
    required double scaleMultiplier,
  });
}

/// A [PhotoProducer] that produces photos from Google Photos using
/// the specified [model] object.
///
/// If the Google Photos API fails for any reason, this photo producer will
/// fall back to producing photos that are pulled statically from assets that
/// are bundled with this app (or, as a last resort, Todd's profile pic).
class GooglePhotosPhotoProducer extends PhotoProducer {
  GooglePhotosPhotoProducer(this.model) : super._();

  final PhotosLibraryApiModel model;
  final List<MediaItem> queue = <MediaItem>[];
  Completer<void>? _queueCompleter;

  /// How many photos to load from the Google Photos API in one request.
  ///
  /// Batching saves the number of requests being made to the photos API, which
  /// is not only more efficient, but it makes it less likely that the app will
  /// be rate limited.
  static const int _batchSize = 50;

  /// Makes a batch request to the Google Photos API, and adds all the media
  /// items that it loaded into the [queue].
  ///
  /// This method depends on the entire set of photo IDs having already been
  /// loaded so that we can choose random photos from the main set. See
  /// [PhotosLibraryApiModel.populateDatabase] for more info.
  ///
  /// If this method is called, and then it is called again while the first
  /// call's future is still pending, then the existing future will be reused
  /// and returned.
  Future<void> _queueItems() {
    if (_queueCompleter != null) {
      return _queueCompleter!.future;
    }
    _queueCompleter = Completer<void>();
    final Future<void> result = _doQueueItems();
    _queueCompleter!.complete(result);
    _queueCompleter = null;
    return result;
  }

  /// Method that does the actual work of queueing media items.
  ///
  /// Assuming the database files have been created, this method will always
  /// make a request to the Google Photos API, even if other requests are still
  /// pending. To ensure that we reuse existing pending requests, use
  /// [_queueItems] instead.
  Future<void> _doQueueItems() async {
    final FilesBinding files = FilesBinding.instance;
    if (!files.photosFile.existsSync()) {
      // We haven't yet finished loading the set of photo IDs from which to
      // choose the next batch of media items; nothing to queue.
      return;
    }

    final List<String> mediaItemIds = await model.pickRandomMediaItems(_batchSize);
    Iterable<MediaItem> items = await model.getMediaItems(mediaItemIds);
    items = items.where((MediaItem item) => item.size != null);
    assert(() {
      if (items.length != _batchSize) {
        debugPrint('Expecting $_batchSize items, but retrieved ${items.length}');
      }
      return true;
    }());
    queue.insertAll(0, items);
  }

  @override
  Future<Photo> produce({
    required BuildContext context,
    required Size sizeConstraints,
    required double scaleMultiplier,
  }) async {
    final ui.FlutterView window = View.of(context);

    if (queue.isEmpty) {
      // The queue can still be empty after this call, e.g. if the database
      // files haven't been created yet.
      await _queueItems();
    }

    if (queue.isEmpty) {
      // ignore: use_build_context_synchronously
      return await const AssetPhotoProducer().produce(
        context: context,
        sizeConstraints: sizeConstraints,
        scaleMultiplier: scaleMultiplier,
      );
    } else {
      final MediaItem mediaItem = queue.removeLast();
      final Size photoSize = applyBoxFit(BoxFit.scaleDown, mediaItem.size!, sizeConstraints).destination;
      final double scale = window.devicePixelRatio * scaleMultiplier;
      return Photo(
        id: mediaItem.id,
        mediaItem: mediaItem,
        size: photoSize / window.devicePixelRatio,
        scale: scale,
        boundingConstraints: sizeConstraints,
        image: NetworkImage(mediaItem.getSizedUrl(photoSize), scale: scale),
      );
    }
  }
}

class ImmediateImageStreamCompleter extends ImageStreamCompleter {
  ImmediateImageStreamCompleter(ImageInfo image) {
    setImage(image);
  }
}

class ImageBackedPhoto extends Photo {
  const ImageBackedPhoto({
    required super.id,
    super.mediaItem,
    required super.size,
    required super.scale,
    required super.boundingConstraints,
    required super.image,
    required this.backingImage,
  });

  final ui.Image backingImage;

  @override
  void dispose() {
    backingImage.dispose();
    super.dispose();
  }
}

/// A [PhotoProducer] that produces photos that are pulled statically
/// from assets that are bundled with this app.
class AssetPhotoProducer extends PhotoProducer {
  const AssetPhotoProducer() : super._();

  static const List<String> _assets = <String>[
    'assets/DSC_0013.jpg',
    'assets/DSC_0021-2.jpg',
    'assets/DSC_0135-2.jpg',
    'assets/DSC_0256.jpg',
    'assets/IMG_20150220_174328408_HDR.jpg',
    'assets/Image13.jpeg',
    'assets/P1010073.jpg',
  ];

  static int _assetIndex = 0;
  static int get _nextAssetIndex {
    int index = _assetIndex;
    _assetIndex = (_assetIndex + 1) % _assets.length;
    return index;
  }

  @override
  Future<Photo> produce({
    required BuildContext context,
    required Size sizeConstraints,
    required double scaleMultiplier,
  }) async {
    final String assetName = _assets[_nextAssetIndex];
    final AssetImage asset = AssetImage(assetName);
    final double scale = WidgetsBinding.instance.window.devicePixelRatio * scaleMultiplier;
    return Photo(
      id: assetName,
      size: sizeConstraints,
      scale: scale,
      boundingConstraints: sizeConstraints,
      image: ResizeImage(
        asset,
        policy: ResizeImagePolicy.fit,
        width: sizeConstraints.width.toInt(),
        height: sizeConstraints.height.toInt(),
      ),
    );
  }
}

/// A [PhotoProducer] that produces a single static photo.
class StaticPhotoProducer extends PhotoProducer {
  const StaticPhotoProducer() : super._();

  @override
  Future<Photo> produce({
    required BuildContext context,
    required Size sizeConstraints,
    required double scaleMultiplier,
  }) async {
    const Size staticSize = Size(429, 429);
    final MediaItem staticMediaItem = MediaItem(
      id: 'profile_photo',
      baseUrl: 'https://lh3.googleusercontent.com/ogw/ADea4I4W_CNuQmCCPTLweMp6ndpZmVOgwL7GCClptOUZG6M',
      mediaMetadata: MediaMetadata(
        width: '${staticSize.width}',
        height: '${staticSize.height}',
      ),
    );
    return Photo(
      id: staticMediaItem.id,
      mediaItem: staticMediaItem,
      size: staticSize,
      scale: WidgetsBinding.instance.window.devicePixelRatio,
      boundingConstraints: sizeConstraints,
      image: NetworkImage(staticMediaItem.getSizedUrl(staticSize)),
    );
  }
}
