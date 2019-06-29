import 'package:http/http.dart' as http;

class PhotosApiException implements Exception {
  /// Creates a new [PhotosApiException].
  PhotosApiException(http.Response response)
      : statusCode = response.statusCode,
        reasonPhrase = response.reasonPhrase,
        responseBody = response.body;

  /// The HTTP status code that the server responded with.
  ///
  /// See also:
  ///  * [HttpStatus] for a list of known HTTP status codes.
  final int statusCode;

  /// A human-readable description of the HTTP status.
  final String reasonPhrase;

  /// The body of the response that the server responded with.
  final String responseBody;
}

class GetMediaItemException extends PhotosApiException {
  /// Creates a new [GetMediaItemException].
  GetMediaItemException(this.mediaItemId, http.Response response) : super(response);

  /// The id of the media item that was attempted to be retrieved.
  ///
  /// The product URL for a given media item is https://photos.google.com/lr/photo/$id.
  final String mediaItemId;
}
