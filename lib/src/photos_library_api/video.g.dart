// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Video _$VideoFromJson(Map<String, dynamic> json) => Video(
      cameraMake: json['cameraMake'] as String?,
      cameraModel: json['cameraModel'] as String?,
      fps: json['fps'] as num?,
      status: _$enumDecode(_$VideoProcessingStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$VideoToJson(Video instance) => <String, dynamic>{
      'cameraMake': instance.cameraMake,
      'cameraModel': instance.cameraModel,
      'fps': instance.fps,
      'status': _$VideoProcessingStatusEnumMap[instance.status],
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

const _$VideoProcessingStatusEnumMap = {
  VideoProcessingStatus.unspecified: 'UNSPECIFIED',
  VideoProcessingStatus.processing: 'PROCESSING',
  VideoProcessingStatus.ready: 'READY',
  VideoProcessingStatus.failed: 'FAILED',
};
