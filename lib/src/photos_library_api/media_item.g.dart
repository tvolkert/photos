// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaItem _$MediaItemFromJson(Map<String, dynamic> json) {
  return MediaItem(
      id: json['id'] as String,
      description: json['description'] as String,
      productUrl: json['productUrl'] as String,
      baseUrl: json['baseUrl'] as String,
      mediaMetadata: json['mediaMetadata'] == null
          ? null
          : MediaMetadata.fromJson(
              json['mediaMetadata'] as Map<String, dynamic>));
}

Map<String, dynamic> _$MediaItemToJson(MediaItem instance) => <String, dynamic>{
      'id': instance.id,
      'description': instance.description,
      'productUrl': instance.productUrl,
      'baseUrl': instance.baseUrl,
      'mediaMetadata': instance.mediaMetadata
    };
