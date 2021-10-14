// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_item_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaItemResult _$MediaItemResultFromJson(Map<String, dynamic> json) =>
    MediaItemResult(
      status: json['status'] == null
          ? null
          : Status.fromJson(json['status'] as Map<String, dynamic>),
      mediaItem: json['mediaItem'] == null
          ? null
          : MediaItem.fromJson(json['mediaItem'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MediaItemResultToJson(MediaItemResult instance) =>
    <String, dynamic>{
      'status': instance.status,
      'mediaItem': instance.mediaItem,
    };
