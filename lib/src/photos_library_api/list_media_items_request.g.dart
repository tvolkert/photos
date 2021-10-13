// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_media_items_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListMediaItemsRequest _$ListMediaItemsRequestFromJson(
        Map<String, dynamic> json) =>
    ListMediaItemsRequest(
      pageSize: json['pageSize'] as int,
      pageToken: json['pageToken'] as String?,
    );

Map<String, dynamic> _$ListMediaItemsRequestToJson(
        ListMediaItemsRequest instance) =>
    <String, dynamic>{
      'pageSize': instance.pageSize,
      'pageToken': instance.pageToken,
    };
