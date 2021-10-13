// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch_get_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BatchGetResponse _$BatchGetResponseFromJson(Map<String, dynamic> json) =>
    BatchGetResponse(
      mediaItemResults: (json['mediaItemResults'] as List<dynamic>)
          .map((e) => MediaItemResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BatchGetResponseToJson(BatchGetResponse instance) =>
    <String, dynamic>{
      'mediaItemResults': instance.mediaItemResults,
    };
