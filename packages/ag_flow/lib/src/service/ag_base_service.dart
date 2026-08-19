import 'package:ag_flow/src/network/ag_request.dart';
import 'package:ag_flow/src/network/ag_response.dart';
import 'package:ag_flow/src/network/api_provider.dart';
import 'package:meta/meta.dart';

/// Base class for every AG service.
///
/// Services own API communication: they build `AgRequest`s against
/// reusable `AgEndpoint`s and send them through the single shared
/// [ApiProvider]. A service must never construct a raw URL or use an HTTP
/// client directly.
abstract class AgBaseService {
  const AgBaseService(this.apiProvider);

  @protected
  final ApiProvider apiProvider;

  /// Sends [request] through the shared [ApiProvider].
  @protected
  Future<AgResponse<D>> send<D>(
    AgRequest request, {
    D Function(Object? json)? decode,
  }) {
    return apiProvider.send<D>(request, decode: decode);
  }
}
