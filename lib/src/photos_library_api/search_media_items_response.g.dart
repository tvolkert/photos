// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_media_items_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchMediaItemsResponse _$SearchMediaItemsResponseFromJson(
    Map<String, dynamic> json) {
  return SearchMediaItemsResponse(
      mediaItems: (json['mediaItems'] as List)
          ?.map((e) =>
              e == null ? null : MediaItem.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      nextPageToken: json['nextPageToken'] as String);
}

Map<String, dynamic> _$SearchMediaItemsResponseToJson(
        SearchMediaItemsResponse instance) =>
    <String, dynamic>{
      'mediaItems': instance.mediaItems,
      'nextPageToken': instance.nextPageToken
    };
