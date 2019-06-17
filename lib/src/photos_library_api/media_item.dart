import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';
import 'package:photos/src/photos_library_api/media_metadata.dart';

part 'media_item.g.dart';

@JsonSerializable()
class MediaItem {
  MediaItem({this.id, this.description, this.productUrl, this.baseUrl, this.mediaMetadata});

  factory MediaItem.fromJson(Map<String, dynamic> json) =>
      _$MediaItemFromJson(json);

  final String id;
  final String description;
  final String productUrl;
  final String baseUrl;
  final MediaMetadata mediaMetadata;

  Size get size {
    int width = int.parse(mediaMetadata.width);
    int height = int.parse(mediaMetadata.height);
    return Size(width.toDouble(), height.toDouble());
  }

  Map<String, dynamic> toJson() => _$MediaItemToJson(this);
}
