/// The product resource returned by fakestoreapi.com's `/products`
/// endpoints.
class Product {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.image,
    required this.ratingRate,
    required this.ratingCount,
  });

  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String image;
  final double ratingRate;
  final int ratingCount;

  factory Product.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'] as Map<String, dynamic>? ?? const {};
    return Product(
      id: json['id'] as int,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String,
      category: json['category'] as String,
      image: json['image'] as String,
      ratingRate: (rating['rate'] as num? ?? 0).toDouble(),
      ratingCount: rating['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'price': price,
    'description': description,
    'category': category,
    'image': image,
  };

  Product copyWith({String? title, double? price, String? description}) =>
      Product(
        id: id,
        title: title ?? this.title,
        price: price ?? this.price,
        description: description ?? this.description,
        category: category,
        image: image,
        ratingRate: ratingRate,
        ratingCount: ratingCount,
      );
}
