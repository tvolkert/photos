// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_media_items_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListMediaItemsResponse _$ListMediaItemsResponseFromJson(
        Map<String, dynamic> json) =>
    ListMediaItemsResponse(
      mediaItems: (json['mediaItems'] as List<dynamic>)
          .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextPageToken: json['nextPageToken'] as String?,
    );

Map<String, dynamic> _$ListMediaItemsResponseToJson(
        ListMediaItemsResponse instance) =>
    <String, dynamic>{
      'mediaItems': instance.mediaItems,
      'nextPageToken': instance.nextPageToken,
    };
