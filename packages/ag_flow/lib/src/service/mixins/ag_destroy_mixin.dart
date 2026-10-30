import 'package:ag_flow/src/service/ag_base_service.dart';

/// Deletes one resource — `DELETE /products/{id}`.
///
/// A typed contract; see `AgListMixin`.
mixin AgDestroyMixin<ID extends Object> on AgBaseService {
  /// Deletes the resource identified by [id].
  Future<void> destroy(ID id);
}
