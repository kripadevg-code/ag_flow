import 'package:ag_flow/src/service/ag_base_service.dart';

/// Reads one resource — `GET /products/{id}`.
///
/// A typed contract; see `AgListMixin`. [ID] is whatever identifies the
/// resource: an `int`, a slug, or a record such as `({String org, int id})`.
mixin AgRetrieveMixin<T, ID extends Object> on AgBaseService {
  /// Reads the resource identified by [id].
  Future<T> retrieve(ID id);
}
