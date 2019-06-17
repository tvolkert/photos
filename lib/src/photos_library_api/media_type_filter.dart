import 'package:json_annotation/json_annotation.dart';

import 'media_type.dart';

part 'media_type_filter.g.dart';

@JsonSerializable()
class MediaTypeFilter {
  MediaTypeFilter({this.mediaTypes});

  factory MediaTypeFilter.fromJson(Map<String, dynamic> json) =>
      _$MediaTypeFilterFromJson(json);

  final List<MediaType> mediaTypes;

  Map<String, dynamic> toJson() => _$MediaTypeFilterToJson(this);
}
