import 'package:ag_flow/src/service/ag_base_service.dart';

/// Replaces one resource — `PUT /products/{id}`.
///
/// A typed contract; see `AgListMixin`.
mixin AgUpdateMixin<T, ID extends Object> on AgBaseService {
  /// Replaces the resource identified by [id] with [item] and returns it
  /// as the backend stored it.
  Future<T> update(ID id, T item);
}
