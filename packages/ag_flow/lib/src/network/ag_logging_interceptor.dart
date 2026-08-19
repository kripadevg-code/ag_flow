import 'package:ag_flow/src/network/ag_log_options.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Produces centralized `[API] METHOD path Status: code Duration: Xms` log
/// lines for every request that passes through `ApiProvider`, masking
/// configured sensitive header/body keys so they're never logged raw.
class AgLoggingInterceptor extends Interceptor {
  AgLoggingInterceptor(this.options);

  final AgLogOptions options;

  static const _startTimeKey = 'ag_request_start_time';

  void Function(String) get _log => options.logger ?? debugPrint;

  @override
  void onRequest(
    // dio names this parameter `options`, but this class already has an
    // `options` field of type AgLogOptions — keeping the dio-conventional
    // name here would shadow it and read ambiguously.
    // ignore: avoid_renaming_method_parameters
    RequestOptions requestOptions,
    RequestInterceptorHandler handler,
  ) {
    requestOptions.extra[_startTimeKey] = DateTime.now();
    if (options.enabled) {
      final headers = _maskHeaders(requestOptions.headers);
      final bodyPart = options.logRequestBody && requestOptions.data != null
          ? ' body: ${_maskBody(requestOptions.data)}'
          : '';
      _log(
        '[API] → ${requestOptions.method} ${requestOptions.path} headers: $headers$bodyPart',
      );
    }
    handler.next(requestOptions);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _logResult(response.requestOptions, response.statusCode);
    if (options.enabled && options.logResponseBody) {
      _log('[API] ← body: ${_maskBody(response.data)}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logResult(err.requestOptions, err.response?.statusCode);
    handler.next(err);
  }

  void _logResult(RequestOptions requestOptions, int? statusCode) {
    if (!options.enabled) return;
    final start = requestOptions.extra[_startTimeKey];
    final duration = start is DateTime
        ? DateTime.now().difference(start)
        : null;
    final durationLabel = duration == null
        ? 'n/a'
        : '${duration.inMilliseconds}ms';
    _log(
      '[API] ${requestOptions.method} ${requestOptions.path} '
      'Status: ${statusCode ?? '-'} Duration: $durationLabel',
    );
  }

  Map<String, dynamic> _maskHeaders(Map<String, dynamic> headers) {
    return headers.map((key, value) {
      final masked = options.maskedHeaderKeys.contains(key.toLowerCase());
      return MapEntry(key, masked ? '***' : value);
    });
  }

  Object? _maskBody(Object? data) {
    if (data is Map) {
      return data.map((key, value) {
        final masked = options.maskedBodyKeys.contains(
          key.toString().toLowerCase(),
        );
        return MapEntry(key, masked ? '***' : value);
      });
    }
    return data;
  }
}
