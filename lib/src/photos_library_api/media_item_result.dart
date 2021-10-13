import 'package:json_annotation/json_annotation.dart';

import 'media_item.dart';

part 'media_item_result.g.dart';

@JsonSerializable()
class MediaItemResult {
  MediaItemResult({this.status, this.mediaItem});

  factory MediaItemResult.fromJson(Map<String, dynamic> json) =>
      _$MediaItemResultFromJson(json);

  /// If an error occurred while accessing this media item, this field is
  /// populated with information related to the error.
  ///
  /// For details regarding this field, see Status.
  ///
  /// See also:
  ///
  ///  * <https://developers.google.com/photos/library/reference/rest/v1/mediaItems/batchGet#MediaItemResult.FIELDS.status>
  final String? status;

  /// Media item retrieved from the user's library.
  ///
  /// It's populated if no errors occurred and the media item was fetched
  /// successfully.
  ///
  /// See also:
  ///
  ///  * <https://developers.google.com/photos/library/reference/rest/v1/mediaItems/batchGet#MediaItemResult.FIELDS.media_item>
  final MediaItem? mediaItem;

  Map<String, dynamic> toJson() => _$MediaItemResultToJson(this);
}
