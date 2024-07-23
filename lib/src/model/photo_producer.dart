import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:photos/src/photos_library_api/media_item.dart';
import 'package:photos/src/photos_library_api/media_metadata.dart';

import 'content_provider.dart';
import 'photo.dart';

abstract class PhotoProducer {
  const PhotoProducer();

  /// Produces a [Photo] that fits within the specified size constraints.
  Future<Photo> produce({
    required BuildContext context,
    required Size sizeConstraints,
    double scaleMultiplier = 1,
  });
}

/// A [PhotoProducer] that produces photos that are pulled statically
/// from assets that are bundled with this app.
class AssetPhotoProducer extends PhotoProducer {
  const AssetPhotoProducer();

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
    double scaleMultiplier = 1,
  }) async {
    final String assetName = _assets[_nextAssetIndex];
    final AssetImage asset = AssetImage(assetName);
    final double scale = View.of(context).devicePixelRatio * scaleMultiplier;
    return Photo(
      id: assetName,
      size: sizeConstraints,
      scale: scale,
      boundingConstraints: sizeConstraints,
      image: ResizeImage(
        asset,
        policy: ResizeImagePolicy.fit,
        width: (sizeConstraints.width * scale).toInt(),
        height: (sizeConstraints.height * scale).toInt(),
      ),
    );
  }
}

/// A [PhotoProducer] that produces a single static photo.
class StaticPhotoProducer extends PhotoProducer {
  const StaticPhotoProducer();

  @override
  Future<Photo> produce({
    required BuildContext context,
    required Size sizeConstraints,
    double scaleMultiplier = 1,
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
      scale: View.of(context).devicePixelRatio,
      boundingConstraints: sizeConstraints,
      image: NetworkImage(ContentProviderBinding.instance.getMediaItemUrl(staticMediaItem, staticSize)),
    );
  }
}
