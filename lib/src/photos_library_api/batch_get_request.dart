import 'package:json_annotation/json_annotation.dart';

part 'batch_get_request.g.dart';

@JsonSerializable()
class BatchGetRequest {
  BatchGetRequest({
    required this.mediaItemIds,
  });

  factory BatchGetRequest.fromJson(Map<String, dynamic> json) =>
      _$BatchGetRequestFromJson(json);

  /// Identifiers of the media items to be requested.
  ///
  /// Must not contain repeated identifiers and cannot be empty. The maximum
  /// number of media items that can be retrieved in one call is 50.
  ///
  /// See also:
  ///
  ///  * <https://developers.google.com/photos/library/reference/rest/v1/mediaItems/batchGet#body.QUERY_PARAMETERS.media_item_ids>
  final List<String> mediaItemIds;

  Map<String, dynamic> toJson() => _$BatchGetRequestToJson(this);
}
