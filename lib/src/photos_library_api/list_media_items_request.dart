import 'package:json_annotation/json_annotation.dart';

part 'list_media_items_request.g.dart';

@JsonSerializable()
class ListMediaItemsRequest {
  ListMediaItemsRequest({
    required this.pageSize,
    this.pageToken,
  }) : assert(pageSize > 0 && pageSize <= 100);

  factory ListMediaItemsRequest.fromJson(Map<String, dynamic> json) =>
      _$ListMediaItemsRequestFromJson(json);

  /// Maximum number of media items to return in the response.
  ///
  /// Fewer media items might be returned than the specified number. The
  /// default pageSize is 25, the maximum is 100.
  ///
  /// See also:
  ///
  ///  * <https://developers.google.com/photos/library/reference/rest/v1/mediaItems/list#body.QUERY_PARAMETERS.page_size>
  final int pageSize;

  /// A continuation token to get the next page of the results.
  ///
  /// Adding this to the request returns the rows after the pageToken. The
  /// pageToken should be the value returned in the nextPageToken parameter in
  /// the response to the listMediaItems request.
  ///
  /// See also:
  ///
  ///  * <https://developers.google.com/photos/library/reference/rest/v1/mediaItems/list#body.QUERY_PARAMETERS.page_token>
  final String? pageToken;

  Map<String, dynamic> toJson() => _$ListMediaItemsRequestToJson(this);
}
