import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';

import 'media_metadata.dart';

part 'media_item.g.dart';

@JsonSerializable()
class MediaItem {
  MediaItem({this.id, this.description, this.productUrl, this.baseUrl, this.mediaMetadata});

  factory MediaItem.fromJson(Map<String, dynamic> json) =>
      _$MediaItemFromJson(json);

  /// The unique identifier of the media item.
  ///
  /// This is a persistent identifier that can be used between sessions to
  /// identify this media item.
  ///
  /// See also:
  ///
  ///  * <https://developers.google.com/photos/library/reference/rest/v1/mediaItems#MediaItem.FIELDS.id>
  final String id;

  /// The description of the media item.
  ///
  /// This is shown to the user in the item's info section in the Google Photos
  /// app.
  ///
  /// See also:
  ///
  ///  * <https://developers.google.com/photos/library/reference/rest/v1/mediaItems#MediaItem.FIELDS.description>
  final String description;

  /// The Google Photos URL for the media item.
  ///
  /// See also:
  ///
  ///  * <https://developers.google.com/photos/library/reference/rest/v1/mediaItems#MediaItem.FIELDS.product_url>
  final String productUrl;

  /// A URL to the media item's bytes.
  ///
  /// This shouldn't be used as is. Parameters should be appended to this URL
  /// before use. For example, '*=w2048-h1024*' will set the dimensions of a
  /// photo media item to have a width of 2048 px and height of 1024 px.
  ///
  /// See also:
  ///
  ///  * <https://developers.google.com/photos/library/guides/access-media-items#base-urls>
  ///    for a complete list of supported parameters to apply to the URL.
  ///  * <https://developers.google.com/photos/library/reference/rest/v1/mediaItems#MediaItem.FIELDS.base_url>
  final String baseUrl;

  /// Metadata related to the media item, such as width and height.
  ///
  /// See also:
  ///
  ///  * <https://developers.google.com/photos/library/reference/rest/v1/mediaItems#MediaItem.FIELDS.media_metadata>
  final MediaMetadata mediaMetadata;

  /// The original raw size (in photo pixels) of the media item.
  Size get size {
    int width = int.parse(mediaMetadata.width);
    int height = int.parse(mediaMetadata.height);
    return Size(width.toDouble(), height.toDouble());
  }

  Map<String, dynamic> toJson() => _$MediaItemToJson(this);
}
