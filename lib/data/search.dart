import 'product.dart';

// Ordenação da busca: rótulo da folha de filtros, rótulo curto dos
// resultados e chave da API.
enum SearchSort {
  relevance('Relevância', 'Relevância', 'relevance'),
  priceAsc('Preço · crescente', 'Menor preço', 'price_asc'),
  priceDesc('Preço · decrescente', 'Maior preço', 'price_desc'),
  rating('Melhor avaliados', 'Melhor avaliados', 'rating');

  const SearchSort(this.label, this.shortLabel, this.apiKey);

  final String label;
  final String shortLabel;
  final String apiKey;
}

// Limites do slider de preço do protótipo (R$ 10 a R$ 80, de 5 em 5).
const minPriceFilter = 10.0;
const maxPriceFilter = 80.0;
const priceFilterStep = 5.0;

// "Qualquer" avaliação e tempo: os valores padrão não filtram nada.
const ratingOptions = [
  (0.0, 'Todas'),
  (4.0, '4,0+'),
  (4.5, '4,5+'),
  (4.8, '4,8+'),
];
const anyDeliveryTime = 60;
const deliveryTimeOptions = [
  (anyDeliveryTime, 'Qualquer'),
  (30, 'até 30 min'),
  (25, 'até 25 min'),
];

class SearchFilters {
  const SearchFilters({
    this.category = allCategories,
    this.maxPrice = maxPriceFilter,
    this.minRating = 0,
    this.maxTime = anyDeliveryTime,
    this.sort = SearchSort.relevance,
  });

  // "Ver tudo" de cada seção da Home abre a busca com os filtros do protótipo.
  factory SearchFilters.forSection(ProductTag tag) => switch (tag) {
    ProductTag.offer => const SearchFilters(sort: SearchSort.priceAsc),
    ProductTag.popular => const SearchFilters(sort: SearchSort.rating),
    ProductTag.recommended => const SearchFilters(
      minRating: 4.5,
      sort: SearchSort.rating,
    ),
    ProductTag.fast => const SearchFilters(maxTime: 30),
  };

  static const none = SearchFilters();

  final String category;
  final double maxPrice;
  final double minRating;
  final int maxTime;
  final SearchSort sort;

  bool get hasCategory => category != allCategories;
  bool get hasPrice => maxPrice != maxPriceFilter;
  bool get hasRating => minRating != 0;
  bool get hasTime => maxTime != anyDeliveryTime;
  bool get hasSort => sort != SearchSort.relevance;

  // Número no botão de filtros.
  int get activeCount => [
    hasCategory,
    hasPrice,
    hasRating,
    hasTime,
    hasSort,
  ].where((on) => on).length;

  bool get isEmpty => activeCount == 0;

  // Chips de filtros ativos; tocar remove só aquele filtro.
  List<(String label, SearchFilters without)> get chips => [
    if (hasCategory) (category, copyWith(category: allCategories)),
    if (hasPrice)
      ('até ${formatMoney(maxPrice)}', copyWith(maxPrice: maxPriceFilter)),
    if (hasRating)
      ('${formatRating(minRating)}+ estrelas', copyWith(minRating: 0)),
    if (hasTime) ('até $maxTime min', copyWith(maxTime: anyDeliveryTime)),
    if (hasSort) (sort.shortLabel, copyWith(sort: SearchSort.relevance)),
  ];

  SearchFilters copyWith({
    String? category,
    double? maxPrice,
    double? minRating,
    int? maxTime,
    SearchSort? sort,
  }) => SearchFilters(
    category: category ?? this.category,
    maxPrice: maxPrice ?? this.maxPrice,
    minRating: minRating ?? this.minRating,
    maxTime: maxTime ?? this.maxTime,
    sort: sort ?? this.sort,
  );

  @override
  bool operator ==(Object other) =>
      other is SearchFilters &&
      other.category == category &&
      other.maxPrice == maxPrice &&
      other.minRating == minRating &&
      other.maxTime == maxTime &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(category, maxPrice, minRating, maxTime, sort);
}

// "Sugestões para você": nome do produto e o resumo embaixo, quando o app
// já conhece o produto ("Forno di Napoli · 4,7 · R$ 45,00").
class SearchSuggestion {
  const SearchSuggestion(this.label, [this.hint = '']);

  final String label;
  final String hint;
}

String resultCountLabel(int count) =>
    '$count ${count == 1 ? 'resultado' : 'resultados'}';

String savedCountLabel(int count) =>
    '$count ${count == 1 ? 'item salvo' : 'itens salvos'}';
