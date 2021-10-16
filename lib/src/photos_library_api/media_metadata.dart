import 'package:json_annotation/json_annotation.dart';

import 'photo.dart';
import 'video.dart';

part 'media_metadata.g.dart';

@JsonSerializable()
class MediaMetadata {
  const MediaMetadata({
    this.creationTime,
    this.width,
    this.height,
    this.photo,
    this.video,
  });

  factory MediaMetadata.fromJson(Map<String, dynamic> json) =>
      _$MediaMetadataFromJson(json);

  final String? creationTime;

  /// Original width (in pixels) of the media item.
  ///
  /// This will not be set for videos that are still in the "PROCESSING" state.
  final String? width;

  /// Original height (in pixels) of the media item.
  ///
  /// This will not be set for videos that are still in the "PROCESSING" state.
  final String? height;

  final Photo? photo;

  final Video? video;

  Map<String, dynamic> toJson() => _$MediaMetadataToJson(this);
}
