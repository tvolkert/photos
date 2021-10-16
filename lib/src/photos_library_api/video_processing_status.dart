import 'package:json_annotation/json_annotation.dart';

enum VideoProcessingStatus {
  @JsonValue('UNSPECIFIED')
  unspecified,

  @JsonValue('PROCESSING')
  processing,

  @JsonValue('READY')
  ready,

  @JsonValue('FAILED')
  failed,
}
