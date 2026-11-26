import '../cart.dart';
import '../checkout.dart';
import '../order.dart';
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

extension AddressDtoMapper on AddressDto {
  Address toAddress() => Address(
    id: id,
    label: label,
    street: street,
    line: line,
    cityLine: cityLine,
    selected: isSelected,
  );
}

extension PaymentMethodDtoMapper on PaymentMethodDto {
  PaymentMethod toPaymentMethod() => PaymentMethod(
    id: id,
    type: PaymentType.fromApi(type),
    label: label,
    detail: detail,
  );
}

extension OrderSummaryDtoMapper on OrderSummaryDto {
  OrderSummary toSummary() => OrderSummary(
    code: code,
    status: OrderStatus.fromApi(status),
    statusLabel: statusLabel,
    createdAt: createdAt,
    total: total,
    itemCount: itemCount,
    itemsSummary: itemsSummary,
    hue: imageHue,
  );
}

extension OrderDetailDtoMapper on OrderDetailDto {
  PlacedOrder toPlacedOrder() => PlacedOrder(
    code: summary.code,
    minMinutes: minMinutes,
    maxMinutes: maxMinutes,
    paymentLabel: paymentLabel,
    itemCount: summary.itemCount,
    total: summary.total,
  );

  OrderDetail toDetail() => OrderDetail(
    summary: summary.toSummary(),
    step: summary.step,
    hint: hint,
    timeline: [
      for (final t in timeline)
        TimelineStep(
          step: t.step,
          label: t.label,
          state: switch (t.state) {
            'done' => TimelineState.done,
            'current' => TimelineState.current,
            _ => TimelineState.upcoming,
          },
          reachedAt: t.reachedAt,
        ),
    ],
    minMinutes: minMinutes,
    maxMinutes: maxMinutes,
    items: [
      for (final i in items)
        OrderItem(
          name: i.name,
          restaurant: i.restaurant,
          hue: i.imageHue,
          quantity: i.quantity,
          total: i.total,
        ),
    ],
    addressLine: addressLine,
    paymentType: paymentType,
    paymentLabel: paymentLabel,
    subtotal: subtotal,
    deliveryFee: deliveryFee,
    discount: discount,
    courierName: courierName,
    courierVehicle: courierVehicle,
  );
}
