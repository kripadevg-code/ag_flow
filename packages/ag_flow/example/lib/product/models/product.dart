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

  /// Encodes back to jsonplaceholder's `/posts` shape for create/update
  /// requests. `id` is never sent — the server assigns/keeps it.
  Map<String, dynamic> toJson() => {
    'title': name,
    'body': description,
    'userId': 1,
  };

  Product copyWith({String? name, String? description}) => Product(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
  );
}
