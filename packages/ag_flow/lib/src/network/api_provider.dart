import 'package:ag_flow/src/network/ag_api_exception.dart';
import 'package:ag_flow/src/network/ag_log_options.dart';
import 'package:ag_flow/src/network/ag_logging_interceptor.dart';
import 'package:ag_flow/src/network/ag_request.dart';
import 'package:ag_flow/src/network/ag_response.dart';
import 'package:ag_flow/src/network/ag_retry_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

/// The single, shared HTTP execution point for the whole application.
///
/// Wraps `dio` directly — every capability the endpoint rules require
/// (interceptors, base URL, auth, timeout, retry, multipart, tracing) is a
/// first-class dio feature. dio types never leak past this class: Services
/// only ever see [AgRequest] in, [AgResponse]/[AgApiException] out.
class ApiProvider {
  ApiProvider({
    required String baseUrl,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 15),
    List<Interceptor> interceptors = const [],
    AgLogOptions logOptions = const AgLogOptions(),
    AgRetryPolicy? retryPolicy,
    Map<String, String> defaultHeaders = const {},
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: connectTimeout,
           receiveTimeout: receiveTimeout,
           headers: defaultHeaders,
         ),
       ) {
    _dio.interceptors.addAll(interceptors);
    if (retryPolicy != null) {
      _dio.interceptors.add(AgRetryInterceptor(_dio, retryPolicy));
    }
    if (logOptions.enabled) {
      _dio.interceptors.add(AgLoggingInterceptor(logOptions));
    }
  }

  final Dio _dio;

  /// The underlying dio instance. Exists only so tests can swap in a fake
  /// [HttpClientAdapter] — everywhere else, go through [send].
  @visibleForTesting
  Dio get debugDio => _dio;

  /// Adds an app-level interceptor (e.g. an auth-refresh interceptor)
  /// after construction.
  void addInterceptor(Interceptor interceptor) =>
      _dio.interceptors.add(interceptor);

  /// Sends [request], returning a decoded [AgResponse] or throwing an
  /// [AgApiException]. [decode] converts the raw JSON body to [D]; when
  /// omitted, the raw body is used as-is (only safe when `D` is `dynamic`
  /// or already matches the raw shape).
  Future<AgResponse<D>> send<D>(
    AgRequest request, {
    D Function(Object? json)? decode,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    final started = DateTime.now();
    try {
      final response = await _dio.request<Object?>(
        request.resolvePath(),
        data: request.isMultipart
            ? await _buildFormData(request)
            : request.body,
        queryParameters: request.queryParams,
        options: Options(method: request.method.name, headers: request.headers),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      final data = decode != null ? decode(response.data) : response.data as D;
      return AgResponse<D>(
        statusCode: response.statusCode ?? 0,
        data: data,
        headers: response.headers.map,
        duration: DateTime.now().difference(started),
      );
    } on DioException catch (error) {
      throw AgApiException.fromDioException(
        error,
        duration: DateTime.now().difference(started),
      );
    }
  }

  Future<FormData> _buildFormData(AgRequest request) async {
    final formData = FormData();

    final fields = request.formFields;
    if (fields != null) {
      for (final entry in fields.entries) {
        formData.fields.add(MapEntry(entry.key, entry.value));
      }
    }

    final files = request.formFiles;
    if (files != null) {
      for (final file in files) {
        formData.files.add(
          MapEntry(
            file.fieldName,
            await MultipartFile.fromFile(
              file.filePath,
              filename: file.fileName,
              contentType: file.contentType == null
                  ? null
                  : DioMediaType.parse(file.contentType!),
            ),
          ),
        );
      }
    }

    return formData;
  }
}
