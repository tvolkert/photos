// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_type_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaTypeFilter _$MediaTypeFilterFromJson(Map<String, dynamic> json) =>
    MediaTypeFilter(
      mediaTypes: (json['mediaTypes'] as List<dynamic>)
          .map((e) => _$enumDecode(_$MediaTypeEnumMap, e))
          .toList(),
    );

Map<String, dynamic> _$MediaTypeFilterToJson(MediaTypeFilter instance) =>
    <String, dynamic>{
      'mediaTypes':
          instance.mediaTypes.map((e) => _$MediaTypeEnumMap[e]).toList(),
    };

K _$enumDecode<K, V>(
  Map<K, V> enumValues,
  Object? source, {
  K? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, enumValues.values.first);
    },
  ).key;
}

const _$MediaTypeEnumMap = {
  MediaType.allMedia: 'ALL_MEDIA',
  MediaType.video: 'VIDEO',
  MediaType.photo: 'PHOTO',
};
