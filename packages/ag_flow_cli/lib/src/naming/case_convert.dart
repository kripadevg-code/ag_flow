/// Case-conversion helpers for module-name segments.
///
/// Hand-rolled rather than depending on `recase` (unmaintained since 2022)
/// — the conversions this CLI needs are narrow and fully known, so owning
/// this one small, correctness-critical utility directly is worth it.
library;

/// A module path segment must already be lowercase snake_case (see
/// requirments/ag_framework.md §10): letters, digits, and underscores,
/// starting with a letter.
final RegExp validModuleSegment = RegExp(r'^[a-z][a-z0-9_]*$');

/// Converts a single snake_case segment (e.g. `product_details`) to
/// PascalCase (`ProductDetails`).
String pascalCase(String snakeSegment) {
  return snakeSegment
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join();
}

/// Converts a single snake_case segment to lower camelCase
/// (`product_details` -> `productDetails`).
String camelCase(String snakeSegment) {
  final pascal = pascalCase(snakeSegment);
  if (pascal.isEmpty) return pascal;
  return pascal[0].toLowerCase() + pascal.substring(1);
}

/// Converts a PascalCase identifier to snake_case
/// (`ProductDetailsReviewsComments` -> `product_details_reviews_comments`).
///
/// Used to derive layer file names from an already-pluralized class
/// prefix (`Products` -> `products`) — the one case where a file name
/// isn't simply the raw module path joined with underscores (see
/// [ModuleSpec.layerFileBase]).
String snakeCase(String pascal) {
  final buffer = StringBuffer();
  for (var i = 0; i < pascal.length; i++) {
    final char = pascal[i];
    final isUpper = char != char.toLowerCase();
    if (isUpper && i > 0) buffer.write('_');
    buffer.write(char.toLowerCase());
  }
  return buffer.toString();
}
