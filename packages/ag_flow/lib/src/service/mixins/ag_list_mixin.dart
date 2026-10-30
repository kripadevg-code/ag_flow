import 'package:ag_flow/src/service/ag_base_service.dart';

/// Lists a resource's collection — `GET /products`.
///
/// Each action mixin is a typed *contract*, not an implementation: it
/// declares the method and its types, and the Service writes the body
/// against its own backend with `get` / `post` / .... Real backends
/// differ too much for one default body to fit them all.
///
/// A Service mixes in exactly the actions its backend supports, the way
/// Django REST Framework splits `ListModelMixin` / `CreateModelMixin` / ...,
/// so it never exposes a method that would only ever fail. An override may
/// add optional parameters — `list({int page = 1})` for a paged backend
/// still satisfies this contract.
mixin AgListMixin<T> on AgBaseService {
  /// Reads the collection.
  Future<List<T>> list();
}
