import 'package:json_annotation/json_annotation.dart';

part 'photo.g.dart';

@JsonSerializable()
class Photo {
  const Photo({this.cameraMake, this.cameraModel});

  factory Photo.fromJson(Map<String, dynamic> json) =>
      _$PhotoFromJson(json);

  final String? cameraMake;

  final String? cameraModel;

  Map<String, dynamic> toJson() => _$PhotoToJson(this);
}
