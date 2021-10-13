import 'package:json_annotation/json_annotation.dart';

import 'media_type_filter.dart';

part 'filters.g.dart';

@JsonSerializable()
class Filters {
  Filters({this.mediaTypeFilter});

  factory Filters.fromJson(Map<String, dynamic> json) =>
      _$FiltersFromJson(json);

  final MediaTypeFilter? mediaTypeFilter;

  Map<String, dynamic> toJson() => _$FiltersToJson(this);
}
