import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../photos_library_api/media_item.dart';

@immutable
class Photo {
  /// Creates a [Photo].
  const Photo({
    required this.id,
    this.mediaItem,
    required this.size,
    required this.scale,
    required this.boundingConstraints,
    required this.image,
  });

  /// A unique identifier of the photo.
  final String id;

  /// The Google Photos API representation of this photo.
  ///
  /// This will only be set for photos that are backed by Google Photos.
  /// Sometimes, the app will create photos from assets that are statically
  /// bundled with the app (e.g. in the case of network errors), and for these
  /// photos, this field will be null.
  ///
  /// See also:
  ///
  ///  * <https://developers.google.com/photos/library/reference/rest/v1/mediaItems#MediaItem>
  final MediaItem? mediaItem;

  /// The size in logical pixels of the photo.
  ///
  /// This does not necessarily map to the same size as the photo's original
  /// (raw) size. If the photo's original size is larger than the device's
  /// screen size, the photo will have been retrieved at a smaller, scaled-down
  /// size to save download bytes.
  final Size size;

  /// The linear scale factor for drawing this photo at its intended size.
  ///
  /// This is the ratio of image pixels to logical device pixels and is
  /// unrelated to any scaling that was applied to the photo when downloaded
  /// via the Google Photos API to alter its [size].
  ///
  /// See also:
  ///
  ///  * [ImageInfo.scale]
  final double scale;

  /// The bounding size that was used to load this photo.
  ///
  /// The photo's [size] is guaranteed to be less than or equal to these
  /// constraints in both width and height.
  final Size boundingConstraints;

  /// Identifies the image that backs this photo, without committing to the
  /// precise final asset.
  final ImageProvider<Object> image;

  /// Disposes of any resources that are held by this object.
  ///
  /// This must be called when the object is no longer needed and subject to
  /// garbage collection.
  @mustCallSuper
  void dispose() {}

  @override
  int get hashCode => Object.hash(id, size);

  @override
  bool operator ==(dynamic other) {
    if (runtimeType != other.runtimeType) {
      return false;
    }
    Photo typedOther = other;
    return id == typedOther.id && size == typedOther.size;
  }
}
