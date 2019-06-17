import 'package:json_annotation/json_annotation.dart';

enum MediaType {
  @JsonValue('ALL_MEDIA')
  allMedia,

  @JsonValue('VIDEO')
  video,

  @JsonValue('PHOTO')
  photo,
}
