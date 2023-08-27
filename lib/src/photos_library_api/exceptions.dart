import 'package:http/http.dart' as http;

class PhotosApiException implements Exception {
  /// Creates a new [PhotosApiException].
  PhotosApiException(this.response) : assert(response.request != null);

  /// The HTTP response that triggered the exception.
  final http.Response response;

  /// The URL of the request that was being made when this exception was thrown.
  Uri get requestUrl => response.request!.url;

  /// The HTTP status code that the server responded with.
  ///
  /// See also:
  ///  * [HttpStatus] for a list of known HTTP status codes.
  int get statusCode => response.statusCode;

  /// A human-readable description of the HTTP status.
  String? get reasonPhrase => response.reasonPhrase;

  /// The body of the response that the server responded with.
  String get responseBody => response.body;

  @override
  String toString() {
    return '$runtimeType[$statusCode]($responseBody)';
  }
}

class GetMediaItemException extends PhotosApiException {
  /// Creates a new [GetMediaItemException].
  GetMediaItemException(this.mediaItemId, Uri requestUrl, http.Response response) : super(response);

  /// The id of the media item that was attempted to be retrieved.
  ///
  /// The product URL for a given media item is https://photos.google.com/lr/photo/$id.
  final String mediaItemId;
}
