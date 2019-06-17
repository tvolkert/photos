// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_type_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaTypeFilter _$MediaTypeFilterFromJson(Map<String, dynamic> json) {
  return MediaTypeFilter(
      mediaTypes: (json['mediaTypes'] as List)
          ?.map((e) => _$enumDecodeNullable(_$MediaTypeEnumMap, e))
          ?.toList());
}

Map<String, dynamic> _$MediaTypeFilterToJson(MediaTypeFilter instance) =>
    <String, dynamic>{
      'mediaTypes':
          instance.mediaTypes?.map((e) => _$MediaTypeEnumMap[e])?.toList()
    };

T _$enumDecode<T>(Map<T, dynamic> enumValues, dynamic source) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }
  return enumValues.entries
      .singleWhere((e) => e.value == source,
          orElse: () => throw ArgumentError(
              '`$source` is not one of the supported values: '
              '${enumValues.values.join(', ')}'))
      .key;
}

T _$enumDecodeNullable<T>(Map<T, dynamic> enumValues, dynamic source) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source);
}

const _$MediaTypeEnumMap = <MediaType, dynamic>{
  MediaType.allMedia: 'ALL_MEDIA',
  MediaType.video: 'VIDEO',
  MediaType.photo: 'PHOTO'
};
