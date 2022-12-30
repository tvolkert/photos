import 'dart:async';

import 'package:flutter/widgets.dart';

import '../photos_library_api/media_item.dart';
import '../photos_library_api/media_metadata.dart';

import 'files.dart';
import 'photo.dart';
import 'photos_library_api_model.dart';

abstract class PhotoProducer {
  /// Creates a [PhotoProducer] that produces photos from Google Photos using
  /// the specified [model] object.
  ///
  /// If the Google Photos API fails for any reason, this photo producer will
  /// fall back to producing photos that are pulled statically from assets that
  /// are bundled with this app (or, as a last resort, Todd's profile pic).
  factory PhotoProducer(PhotosLibraryApiModel model) = _GooglePhotosPhotoProducer;

  /// Creates a [PhotoProducer] that produces photos that are pulled statically
  /// from assets that are bundled with this app.
  factory PhotoProducer.asset() = _AssetPhotoProducer;

  /// Creates a [PhotoProducer] that produces a single static photo.
  factory PhotoProducer.static() = _StaticPhotoProducer;

  const PhotoProducer._();

  /// Produces a [Photo] that fits within the specified size constraints.
  Future<Photo> produce(Size sizeConstraints);
}

class _GooglePhotosPhotoProducer extends PhotoProducer {
  _GooglePhotosPhotoProducer(this.model) : super._();

  final PhotosLibraryApiModel model;
  final List<MediaItem> queue = <MediaItem>[];

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
  Future<void> _queueItems() async {
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
  Future<Photo> produce(Size sizeConstraints) async {
    if (queue.isEmpty) {
      // The queue can still be empty after this call, e.g. if the database
      // files haven't been created yet.
      await _queueItems();
    }

    if (queue.isEmpty) {
      return await const _AssetPhotoProducer().produce(sizeConstraints);
    } else {
      final MediaItem mediaItem = queue.removeLast();
      final Size photoSize = applyBoxFit(BoxFit.scaleDown, mediaItem.size!, sizeConstraints).destination;
      return Photo(
        id: mediaItem.id,
        mediaItem: mediaItem,
        size: photoSize / WidgetsBinding.instance.window.devicePixelRatio,
        scale: WidgetsBinding.instance.window.devicePixelRatio,
        image: NetworkImage(mediaItem.getSizedUrl(photoSize)),
      );
    }
  }
}

class _AssetPhotoProducer extends PhotoProducer {
  const _AssetPhotoProducer() : super._();

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
  Future<Photo> produce(Size sizeConstraints) async {
    final String assetName = _assets[_nextAssetIndex];
    return Photo(
      id: assetName,
      size: sizeConstraints,
      scale: WidgetsBinding.instance.window.devicePixelRatio,
      image: AssetImage(assetName),
    );
  }
}

class _StaticPhotoProducer extends PhotoProducer {
  const _StaticPhotoProducer() : super._();

  @override
  Future<Photo> produce(Size sizeConstraints) async {
    const Size staticSize = Size(429, 429);
    final MediaItem staticMediaItem = MediaItem(
      id: 'profile_photo',
      baseUrl:
          'https://lh3.googleusercontent.com/ogw/ADea4I4W_CNuQmCCPTLweMp6ndpZmVOgwL7GCClptOUZG6M',
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
      image: NetworkImage(staticMediaItem.getSizedUrl(staticSize)),
    );
  }
}
