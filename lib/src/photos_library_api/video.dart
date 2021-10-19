import 'package:json_annotation/json_annotation.dart';

import 'video_processing_status.dart';

part 'video.g.dart';

@JsonSerializable()
class Video {
  const Video({
    this.cameraMake,
    this.cameraModel,
    this.fps,
    required this.status,
  });

  factory Video.fromJson(Map<String, dynamic> json) =>
      _$VideoFromJson(json);

  final String? cameraMake;

  final String? cameraModel;

  final num? fps;

  final VideoProcessingStatus status;

  Map<String, dynamic> toJson() => _$VideoToJson(this);
}
