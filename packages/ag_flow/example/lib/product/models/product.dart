/// A product, mapped from jsonplaceholder's `/posts` resource for this
/// example (id/title/body → id/name/description).
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: '${json['id']}',
      name: json['title'] as String? ?? '',
      description: json['body'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String description;
}
