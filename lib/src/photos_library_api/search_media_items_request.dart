import 'package:json_annotation/json_annotation.dart';

import 'filters.dart';

part 'search_media_items_request.g.dart';

@JsonSerializable()
class SearchMediaItemsRequest {
  SearchMediaItemsRequest({this.filters, this.pageSize, this.pageToken})
      : assert(pageSize == null || (pageSize > 0 && pageSize <= 100));

  factory SearchMediaItemsRequest.fromJson(Map<String, dynamic> json) =>
      _$SearchMediaItemsRequestFromJson(json);

  final Filters filters;
  final int pageSize;
  final String pageToken;

  Map<String, dynamic> toJson() => _$SearchMediaItemsRequestToJson(this);
}
