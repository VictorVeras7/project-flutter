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

class Addon {
  const Addon({required this.id, required this.name, required this.price});

  final String id;
  final String name;
  final double price;
}

// Detalhe do produto: o resumo da lista mais ingredientes e adicionais.
class ProductDetail {
  const ProductDetail({
    required this.product,
    required this.ingredients,
    required this.addons,
  });

  final Product product;
  final String ingredients;
  final List<Addon> addons;

  // Texto do protótipo: a descrição mais a primeira frase dos ingredientes.
  String get fullDescription =>
      '${product.description}. ${ingredients.split('.').first}.';

  // Preço unitário com os adicionais escolhidos.
  double unitPrice(Set<String> addonIds) =>
      product.price +
      addons
          .where((a) => addonIds.contains(a.id))
          .fold(0.0, (sum, a) => sum + a.price);
}

// Regra do protótipo para o card "entrega" do detalhe.
const standardDeliveryFee = 7.9;
bool hasFreeDelivery(double price) => price >= 50;

const allCategories = 'Todos';

String formatMoney(double value) {
  final cents = (value * 100).round();
  return 'R\$ ${cents ~/ 100},${(cents % 100).toString().padLeft(2, '0')}';
}

String formatRating(double value) =>
    value.toStringAsFixed(1).replaceAll('.', ',');
