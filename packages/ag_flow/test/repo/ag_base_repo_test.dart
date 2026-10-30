import 'package:ag_flow/ag_flow.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo extends AgBaseRepo {
  const _Repo();

  Future<R> run<R>(Future<R> Function() action) => guard(action);
}

AgApiException _dio(DioExceptionType type, [int? status]) => AgApiException.fromDioException(
  DioException(
    requestOptions: RequestOptions(),
    type: type,
    response: status == null
        ? null
        : Response<Object?>(
            requestOptions: RequestOptions(),
            statusCode: status,
          ),
  ),
);

Future<AgRepoException> _guarded(Object error) async {
  try {
    // The test throws arbitrary objects to check how guard classifies them.
    // ignore: only_throw_errors
    await const _Repo().run<void>(() async => throw error);
  } on AgRepoException catch (e) {
    return e;
  }
  fail('guard did not throw');
}

Future<AgRepoErrorKind> _kindOf(Object error) async {
  final e = await _guarded(error);
  expect(e.cause, same(error));
  return e.kind;
}

void main() {
  test('guard passes results through', () async {
    expect(await const _Repo().run(() async => 1), 1);
  });

  test('guard classifies transport failures', () async {
    expect(
      await _kindOf(_dio(DioExceptionType.connectionError)),
      AgRepoErrorKind.network,
    );
    expect(
      await _kindOf(_dio(DioExceptionType.receiveTimeout)),
      AgRepoErrorKind.timeout,
    );
    expect(
      await _kindOf(_dio(DioExceptionType.cancel)),
      AgRepoErrorKind.cancelled,
    );
  });

  test('guard classifies status codes', () async {
    Future<AgRepoErrorKind> status(int code) => _kindOf(_dio(DioExceptionType.badResponse, code));
    expect(await status(401), AgRepoErrorKind.unauthorized);
    expect(await status(403), AgRepoErrorKind.unauthorized);
    expect(await status(404), AgRepoErrorKind.notFound);
    expect(await status(422), AgRepoErrorKind.rejected);
    expect(await status(503), AgRepoErrorKind.server);
  });

  test('guard classifies decode and other errors', () async {
    expect(
      await _kindOf(const FormatException('bad')),
      AgRepoErrorKind.badResponse,
    );
    expect(await _kindOf(StateError('x')), AgRepoErrorKind.unknown);
  });

  test('guard does not re-wrap an AgRepoException', () async {
    const original = AgRepoException('x', kind: AgRepoErrorKind.notFound);
    expect(await _guarded(original), same(original));
  });

  testWidgets('AgError shows a Repo failure as its message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AgError(
          error: AgRepoException('x', kind: AgRepoErrorKind.network),
        ),
      ),
    );
    expect(find.text('No connection. Check your network.'), findsOneWidget);
  });
}
