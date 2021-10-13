import 'package:json_annotation/json_annotation.dart';
import 'package:photos/src/photos_library_api/media_item.dart';

part 'list_media_items_response.g.dart';

@JsonSerializable()
class ListMediaItemsResponse {
  ListMediaItemsResponse({required this.mediaItems, this.nextPageToken});

  factory ListMediaItemsResponse.fromJson(Map<String, dynamic> json) =>
      _$ListMediaItemsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ListMediaItemsResponseToJson(this);

  List<MediaItem> mediaItems;
  String? nextPageToken;
}
