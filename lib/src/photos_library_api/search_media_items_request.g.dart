// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_media_items_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchMediaItemsRequest _$SearchMediaItemsRequestFromJson(
        Map<String, dynamic> json) =>
    SearchMediaItemsRequest(
      pageSize: json['pageSize'] as int,
      filters: json['filters'] == null
          ? null
          : Filters.fromJson(json['filters'] as Map<String, dynamic>),
      pageToken: json['pageToken'] as String?,
    );

Map<String, dynamic> _$SearchMediaItemsRequestToJson(
        SearchMediaItemsRequest instance) =>
    <String, dynamic>{
      'pageSize': instance.pageSize,
      'filters': instance.filters,
      'pageToken': instance.pageToken,
    };
