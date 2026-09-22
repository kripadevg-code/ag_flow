// The single application-level file for every navigation argument class
// (see requirments/routes.md §3). `ag g m` maintains this automatically
// for detail/child modules — there must never be more than one of this
// file in the application.

class ProductDetailsPageArgument {
  const ProductDetailsPageArgument({required this.productId});

  /// Rebuilds this argument from the route's path parameters, so
  /// /product/details/5 opens the right product whether it was reached
  /// by an in-app tap or by a link from outside the app.
  ///
  /// Path parameters are always strings; this module's id is an int, so
  /// the conversion lives here — the one place that knows the type.
  factory ProductDetailsPageArgument.fromPathParameters(
    Map<String, String> pathParameters,
  ) {
    final raw = pathParameters['id'];
    final productId = raw == null ? null : int.tryParse(raw);
    if (productId == null) {
      throw ArgumentError(
        'Route was opened with an invalid "id" path parameter: $raw',
      );
    }
    return ProductDetailsPageArgument(productId: productId);
  }

  final int productId;

  Map<String, String> toPathParameters() => {'id': '$productId'};
}
