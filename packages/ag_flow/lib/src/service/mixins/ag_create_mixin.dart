import 'package:ag_flow/src/service/ag_base_service.dart';

/// Creates a resource — `POST /products`.
///
/// A typed contract; see `AgListMixin`.
mixin AgCreateMixin<T> on AgBaseService {
  /// Creates [item] and returns it as the backend stored it.
  Future<T> create(T item);
}
