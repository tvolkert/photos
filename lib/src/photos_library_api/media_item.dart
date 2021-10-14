import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

import 'http_status_exception.dart';
import 'media_metadata.dart';

part 'media_item.g.dart';

@JsonSerializable()
class MediaItem {
  const MediaItem({
    required this.id,
    this.description,
    this.productUrl,
    required this.baseUrl,
    required this.mediaMetadata,
  });

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
  final String? description;

  /// The Google Photos URL for the media item.
  ///
  /// See also:
  ///
  ///  * <https://developers.google.com/photos/library/reference/rest/v1/mediaItems#MediaItem.FIELDS.product_url>
  final String? productUrl;

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
  Size? get size {
    if (mediaMetadata.width == null || mediaMetadata.height == null) {
      return null;
    }
    int width = int.parse(mediaMetadata.width!);
    int height = int.parse(mediaMetadata.height!);
    return Size(width.toDouble(), height.toDouble());
  }

  Future<Uint8List> load(Size size) async {
    String url = '$baseUrl=w${size.width.toInt()}-h${size.height.toInt()}';

    final HttpClient httpClient = HttpClient();
    final Uri resolved = Uri.base.resolve(url);
    final HttpClientRequest request = await httpClient.getUrl(resolved);
    final HttpClientResponse response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpStatusException(response.statusCode);
    }

    return await consolidateHttpClientResponseBytes(response);
  }

  Map<String, dynamic> toJson() => _$MediaItemToJson(this);
}
