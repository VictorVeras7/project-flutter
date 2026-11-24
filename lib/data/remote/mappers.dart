import '../product.dart';
import 'api_models.dart';

extension ProductDtoMapper on ProductDto {
  Product toProduct() => Product(
    id: id,
    name: name,
    restaurant: restaurant,
    category: category,
    description: description,
    price: price,
    oldPrice: oldPrice,
    rating: rating,
    minMinutes: minMinutes,
    maxMinutes: maxMinutes,
    hue: imageHue,
    tags: {...tags.map(ProductTag.fromApi).nonNulls},
  );
}
