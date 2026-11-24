enum ProductTag {
  offer('offers'),
  popular('popular'),
  recommended('recommended'),
  fast('fast');

  const ProductTag(this.apiKey);

  // Chave usada pela API nas seções da Home e nas tags do produto.
  final String apiKey;

  static ProductTag? fromApi(String key) {
    for (final tag in values) {
      if (tag.apiKey == key) return tag;
    }
    return null;
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.restaurant,
    required this.category,
    required this.description,
    required this.price,
    required this.oldPrice,
    required this.rating,
    required this.minMinutes,
    required this.maxMinutes,
    required this.hue,
    required this.tags,
  });

  final String id;
  final String name;
  final String restaurant;
  final String category;
  final String description;
  final double price;
  final double? oldPrice;
  final double rating;
  final int minMinutes;
  final int maxMinutes;
  final double hue;
  final Set<ProductTag> tags;
}

const allCategories = 'Todos';

String formatMoney(double value) {
  final cents = (value * 100).round();
  return 'R\$ ${cents ~/ 100},${(cents % 100).toString().padLeft(2, '0')}';
}

String formatRating(double value) =>
    value.toStringAsFixed(1).replaceAll('.', ',');
