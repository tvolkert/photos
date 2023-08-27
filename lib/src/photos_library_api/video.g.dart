// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Video _$VideoFromJson(Map<String, dynamic> json) => Video(
      cameraMake: json['cameraMake'] as String?,
      cameraModel: json['cameraModel'] as String?,
      fps: json['fps'] as num?,
      status: $enumDecode(_$VideoProcessingStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$VideoToJson(Video instance) => <String, dynamic>{
      'cameraMake': instance.cameraMake,
      'cameraModel': instance.cameraModel,
      'fps': instance.fps,
      'status': _$VideoProcessingStatusEnumMap[instance.status]!,
    };

const _$VideoProcessingStatusEnumMap = {
  VideoProcessingStatus.unspecified: 'UNSPECIFIED',
  VideoProcessingStatus.processing: 'PROCESSING',
  VideoProcessingStatus.ready: 'READY',
  VideoProcessingStatus.failed: 'FAILED',
};
