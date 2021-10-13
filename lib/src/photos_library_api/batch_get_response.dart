import 'package:json_annotation/json_annotation.dart';

import 'media_item_result.dart';

part 'batch_get_response.g.dart';

@JsonSerializable()
class BatchGetResponse {
  BatchGetResponse({
    required this.mediaItemResults,
  });

  factory BatchGetResponse.fromJson(Map<String, dynamic> json) =>
      _$BatchGetResponseFromJson(json);

  /// List of media items retrieved.
  ///
  /// Note that even if the call to mediaItems.batchGet succeeds, there may
  /// have been failures for some media items in the batch. These failures are
  /// indicated in each MediaItemResult.status.
  ///
  /// See also:
  ///
  ///  * <https://developers.google.com/photos/library/reference/rest/v1/mediaItems/batchGet#body.BatchGetMediaItemsResponse.FIELDS.media_item_results>
  final List<MediaItemResult> mediaItemResults;

  Map<String, dynamic> toJson() => _$BatchGetResponseToJson(this);
}
