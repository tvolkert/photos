import 'package:json_annotation/json_annotation.dart';
import 'package:photos/src/photos_library_api/media_item.dart';

part 'search_media_items_response.g.dart';

@JsonSerializable()
class SearchMediaItemsResponse {
  SearchMediaItemsResponse({required this.mediaItems, this.nextPageToken});

  factory SearchMediaItemsResponse.fromJson(Map<String, dynamic> json) =>
      _$SearchMediaItemsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SearchMediaItemsResponseToJson(this);

  List<MediaItem> mediaItems;
  String? nextPageToken;
}
