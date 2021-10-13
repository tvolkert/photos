import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

import '../photos_library_api/media_item.dart';

@immutable
class Photo {
  /// Creates a [Photo].
  ///
  /// The [mediaItem], [size], [scale], and [bytes] arguments must all be
  /// non-null.
  const Photo(this.mediaItem, this.size, this.scale, this.bytes);

  /// The Google Photos API representation of this photo.
  ///
  /// See also:
  ///
  ///  * <https://developers.google.com/photos/library/reference/rest/v1/mediaItems#MediaItem>
  final MediaItem mediaItem;

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

  /// The encoded image bytes.
  ///
  /// The image format depends on the format that was used when the photo was
  /// originally uploaded to Google Photos. The most common formats are JPG,
  /// PNG, and GIF.
  final Uint8List bytes;

  @override
  int get hashCode => hashValues(mediaItem.id, size);

  @override
  bool operator ==(dynamic other) {
    if (runtimeType != other.runtimeType) {
      return false;
    }
    Photo typedOther = other;
    return mediaItem.id == typedOther.mediaItem.id && size == typedOther.size;
  }
}
