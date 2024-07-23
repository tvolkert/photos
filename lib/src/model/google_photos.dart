import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:photos/src/photos_library_api/media_item.dart';
import 'package:photos/src/ui/common/notifications.dart';
import 'package:photos/src/ui/photos/app.dart';
import 'package:photos/src/ui/photos/photos_page.dart';

import 'auth.dart';
import 'content_provider.dart';
import 'files.dart';
import 'photo.dart';
import 'photo_producer.dart';
import 'photos_api.dart';

mixin GooglePhotosContentProvider on ContentProviderBinding {
  @override
  Future<void> init() async {
    await AuthBinding.instance.signInSilently();
  }

  @override
  Widget buildHome(BuildContext context) {
    switch (PhotosApp.of(context).state) {
      case PhotosLibraryApiState.pendingAuthentication:
        // Show a blank screen while we try to non-interactively sign in.
        return Container();
      case PhotosLibraryApiState.unauthenticated:
        return const MontageScaffold(
          producer: AssetPhotoProducer(),
          bottomBarNotification: NeedToLoginNotification(),
        );
      case PhotosLibraryApiState.authenticated:
      case PhotosLibraryApiState.authenticationExpired:
        return MontageContainer(producer: GooglePhotosPhotoProducer());
      case PhotosLibraryApiState.rateLimited:
        return const AssetPhotosMontageContainer();
    }
  }

  @override
  String getMediaItemUrl(MediaItem item, ui.Size size) =>'${item.baseUrl}=w${size.width.toInt()}-h${size.height.toInt()}';
}

/// A [PhotoProducer] that produces photos from Google Photos using
/// the specified [model] object.
///
/// If the Google Photos API fails for any reason, this photo producer will
/// fall back to producing photos that are pulled statically from assets that
/// are bundled with this app (or, as a last resort, Todd's profile pic).
class GooglePhotosPhotoProducer extends PhotoProducer {
  GooglePhotosPhotoProducer();

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

    final PhotosApiBinding photosApi = PhotosApiBinding.instance;
    final List<String> mediaItemIds = await photosApi.pickRandomMediaItems(_batchSize);
    Iterable<MediaItem> items = await photosApi.getMediaItems(mediaItemIds);
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
    double scaleMultiplier = 1,
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
      final double scale = window.devicePixelRatio * scaleMultiplier;
      final MediaItem mediaItem = queue.removeLast();
      final Size photoLogicalSize = applyBoxFit(
        BoxFit.scaleDown,
        mediaItem.size!,
        sizeConstraints,
      ).destination;
      return Photo(
        id: mediaItem.id,
        mediaItem: mediaItem,
        size: photoLogicalSize,
        scale: scale,
        boundingConstraints: sizeConstraints,
        image: NetworkImage(ContentProviderBinding.instance.getMediaItemUrl(mediaItem, photoLogicalSize * scale), scale: scale),
      );
    }
  }
}
