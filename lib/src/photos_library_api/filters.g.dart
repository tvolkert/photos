// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filters.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Filters _$FiltersFromJson(Map<String, dynamic> json) => Filters(
      mediaTypeFilter: json['mediaTypeFilter'] == null
          ? null
          : MediaTypeFilter.fromJson(
              json['mediaTypeFilter'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FiltersToJson(Filters instance) => <String, dynamic>{
      'mediaTypeFilter': instance.mediaTypeFilter,
    };
