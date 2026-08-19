/// The single application-level file for every navigation argument class
/// (see requirments/routes.md §3). `ag_cli` will maintain this file
/// automatically once it exists; for this hand-wired example, argument
/// classes are added here by hand, in the exact shape the CLI must later
/// reproduce.
class ProductDetailsPageArgument {
  const ProductDetailsPageArgument({required this.productId});

  final String productId;
}
