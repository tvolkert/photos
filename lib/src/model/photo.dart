import 'dart:typed_data';
import 'dart:ui';

import '../photos_library_api/media_item.dart';

class Photo {
  const Photo(this.mediaItem, this.size, this.scale, this.bytes);

  final MediaItem mediaItem;
  final Size size;
  final double scale;
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
