// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_media_items_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchMediaItemsRequest _$SearchMediaItemsRequestFromJson(
    Map<String, dynamic> json) {
  return SearchMediaItemsRequest(
      filters: json['filters'] == null
          ? null
          : Filters.fromJson(json['filters'] as Map<String, dynamic>),
      pageSize: json['pageSize'] as int,
      pageToken: json['pageToken'] as String);
}

Map<String, dynamic> _$SearchMediaItemsRequestToJson(
        SearchMediaItemsRequest instance) =>
    <String, dynamic>{
      'filters': instance.filters,
      'pageSize': instance.pageSize,
      'pageToken': instance.pageToken
    };
