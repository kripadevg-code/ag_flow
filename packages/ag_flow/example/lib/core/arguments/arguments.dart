// The single application-level file for every navigation argument class
// (see requirments/routes.md §3). `ag g m` maintains this automatically
// for detail/child modules — there must never be more than one of this
// file in the application.

class ProductDetailsPageArgument {
  const ProductDetailsPageArgument({required this.id});

  /// Rebuilds this argument from the route's path parameters — what
  /// makes ProductDetailsPage work from a deep link, not just an
  /// in-app push.
  factory ProductDetailsPageArgument.fromPathParameters(
    Map<String, String> pathParameters,
  ) {
    final id = pathParameters['id'];
    if (id == null) {
      throw ArgumentError(
        'Route was opened without an "id" path parameter. '
        'Navigate via RouteManagement.goToProductDetailsPage().',
      );
    }
    return ProductDetailsPageArgument(id: id);
  }

  final String id;

  Map<String, String> toPathParameters() => {'id': id};
}
