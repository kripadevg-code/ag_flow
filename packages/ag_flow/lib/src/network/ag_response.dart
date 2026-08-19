/// The result of a successful `ApiProvider.send` call.
class AgResponse<D> {
  const AgResponse({
    required this.statusCode,
    required this.data,
    required this.headers,
    required this.duration,
  });

  final int statusCode;
  final D data;
  final Map<String, List<String>> headers;
  final Duration duration;
}
