import '../cart.dart';
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

extension ProductDetailDtoMapper on ProductDetailDto {
  ProductDetail toDetail() => ProductDetail(
    product: summary.toProduct(),
    ingredients: ingredients,
    addons: [
      for (final addon in addons)
        Addon(id: addon.id, name: addon.name, price: addon.price),
    ],
  );
}

extension CartDtoMapper on CartDto {
  Cart toCart() => Cart(
    lines: [
      for (final item in items)
        CartLine(
          id: item.id,
          productId: item.productId,
          name: item.name,
          hue: item.imageHue,
          quantity: item.quantity,
          addons: [for (final addon in item.addons) addon.name],
          notes: item.notes,
          unitPrice: item.unitPrice,
          total: item.total,
          available: item.isAvailable,
        ),
    ],
    itemCount: itemCount,
    subtotal: subtotal,
    deliveryFee: deliveryFee,
    discount: discount,
    total: total,
    couponCode: couponCode,
    couponApplied: couponApplied,
    couponPercentOff: couponPercentOff,
  );
}
