import 'package:json_annotation/json_annotation.dart';

part 'media_metadata.g.dart';

@JsonSerializable()
class MediaMetadata {
  MediaMetadata({this.width, this.height});

  factory MediaMetadata.fromJson(Map<String, dynamic> json) =>
      _$MediaMetadataFromJson(json);

  final String width;
  final String height;

  Map<String, dynamic> toJson() => _$MediaMetadataToJson(this);
}
