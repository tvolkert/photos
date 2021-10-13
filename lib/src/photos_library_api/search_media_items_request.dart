import 'package:json_annotation/json_annotation.dart';

import 'filters.dart';

part 'search_media_items_request.g.dart';

@JsonSerializable()
class SearchMediaItemsRequest {
  SearchMediaItemsRequest({
    required this.pageSize,
    this.filters,
    this.pageToken,
  }) : assert(pageSize > 0 && pageSize <= 100);

  factory SearchMediaItemsRequest.fromJson(Map<String, dynamic> json) =>
      _$SearchMediaItemsRequestFromJson(json);

  /// Maximum number of media items to return in the response.
  ///
  /// Fewer media items might be returned than the specified number. The
  /// default pageSize is 25, the maximum is 100.
  ///
  /// See also:
  ///
  ///  * <https://developers.google.com/photos/library/reference/rest/v1/mediaItems/search#body.request_body.FIELDS.page_size>
  final int pageSize;

  /// Filters to apply to the request.
  ///
  /// Can't be set in conjunction with an albumId.
  ///
  /// See also:
  ///
  ///  * <https://developers.google.com/photos/library/reference/rest/v1/mediaItems/search#body.request_body.FIELDS.filters>
  final Filters? filters;

  /// A continuation token to get the next page of the results.
  ///
  /// Adding this to the request returns the rows after the pageToken. The
  /// pageToken should be the value returned in the nextPageToken parameter in
  /// the response to the searchMediaItems request.
  ///
  /// See also:
  ///
  ///  * <https://developers.google.com/photos/library/reference/rest/v1/mediaItems/search#body.request_body.FIELDS.page_token>
  final String? pageToken;

  Map<String, dynamic> toJson() => _$SearchMediaItemsRequestToJson(this);
}
