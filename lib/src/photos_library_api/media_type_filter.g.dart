// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_type_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaTypeFilter _$MediaTypeFilterFromJson(Map<String, dynamic> json) =>
    MediaTypeFilter(
      mediaTypes: (json['mediaTypes'] as List<dynamic>)
          .map((e) => $enumDecode(_$MediaTypeEnumMap, e))
          .toList(),
    );

Map<String, dynamic> _$MediaTypeFilterToJson(MediaTypeFilter instance) =>
    <String, dynamic>{
      'mediaTypes':
          instance.mediaTypes.map((e) => _$MediaTypeEnumMap[e]!).toList(),
    };

const _$MediaTypeEnumMap = {
  MediaType.allMedia: 'ALL_MEDIA',
  MediaType.video: 'VIDEO',
  MediaType.photo: 'PHOTO',
};
