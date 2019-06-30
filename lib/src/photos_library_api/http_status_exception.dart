class HttpStatusException implements Exception {
  const HttpStatusException(this.statusCode);

  final int statusCode;
}
