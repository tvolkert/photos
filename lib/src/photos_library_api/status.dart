import 'package:json_annotation/json_annotation.dart';

part 'status.g.dart';

@JsonSerializable()
class Status {
  Status({required this.code, required this.message, this.details});

  factory Status.fromJson(Map<String, dynamic> json) =>
      _$StatusFromJson(json);

  /// The status code, which should be an enum value of google.rpc.Code.
  ///
  /// See also:
  ///
  ///  * <https://developers.google.com/photos/library/reference/rest/v1/Status#FIELDS.code>
  final int code;

  /// A developer-facing error message, which should be in English.
  ///
  /// Any user-facing error message should be localized and sent in the
  /// google.rpc.Status.details field, or localized by the client.
  ///
  /// See also:
  ///
  ///  * <https://developers.google.com/photos/library/reference/rest/v1/Status#FIELDS.message>
  final String message;

  /// A list of messages that carry the error details.
  ///
  /// There is a common set of message types for APIs to use.
  ///
  /// An object containing fields of an arbitrary type. An additional field
  /// "@type" contains a URI identifying the type.
  ///
  /// Example: { "id": 1234, "@type": "types.example.com/standard/id" }.
  ///
  /// See also:
  ///
  ///  * <https://developers.google.com/photos/library/reference/rest/v1/Status#FIELDS.details>
  final List<Object>? details;

  Map<String, dynamic> toJson() => _$StatusToJson(this);
}
