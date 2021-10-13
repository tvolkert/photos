// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch_get_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BatchGetRequest _$BatchGetRequestFromJson(Map<String, dynamic> json) =>
    BatchGetRequest(
      mediaItemIds: (json['mediaItemIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$BatchGetRequestToJson(BatchGetRequest instance) =>
    <String, dynamic>{
      'mediaItemIds': instance.mediaItemIds,
    };
