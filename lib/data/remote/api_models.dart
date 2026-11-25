// Formatos das respostas e corpos da API, só com os campos que o app usa.
// Campos extras da resposta são ignorados.

typedef Json = Map<String, dynamic>;

List<T> _list<T>(Object? value, T Function(Json) parse) => [
  for (final item in (value as List? ?? const [])) parse(item as Json),
];

class ErrorDto {
  ErrorDto.fromJson(Json json)
    : code = json['code'] as String,
      message = json['message'] as String,
      fields = {
        for (final detail in (json['details'] as List? ?? const []))
          (detail as Json)['field'] as String: detail['message'] as String,
      };

  final String code;
  final String message;
  final Map<String, String> fields;
}

// Sessão

class SessionDto {
  SessionDto.fromJson(Json json)
    : accessToken = json['accessToken'] as String,
      refreshToken = json['refreshToken'] as String,
      userName = (json['user'] as Json)['name'] as String;

  final String accessToken;
  final String refreshToken;
  final String userName;
}

class RegisterRequest {
  const RegisterRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.passwordConfirmation,
  });

  final String name;
  final String email;
  final String phone;
  final String password;
  final String passwordConfirmation;

  Json toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'password': password,
    'passwordConfirmation': passwordConfirmation,
    'acceptTerms': true,
    'keepSignedIn': true,
  };
}

// Catálogo

class HomeDto {
  HomeDto.fromJson(Json json)
    : userName = (json['user'] as Json)['name'] as String,
      address = (json['selectedAddress'] as Json?)?['street'] as String?,
      cartItemCount = json['cartItemCount'] as int,
      unreadNotifications = json['unreadNotifications'] as int? ?? 0,
      categories = _list(json['categories'], CategoryDto.fromJson),
      sections = _list(json['sections'], HomeSectionDto.fromJson);

  final String userName;
  final String? address;
  final int cartItemCount;
  final int unreadNotifications;
  final List<CategoryDto> categories;
  final List<HomeSectionDto> sections;
}

class CategoryDto {
  CategoryDto.fromJson(Json json)
    : name = json['name'] as String,
      slug = json['slug'] as String;

  final String name;
  final String slug;
}

class HomeSectionDto {
  HomeSectionDto.fromJson(Json json)
    : key = json['key'] as String,
      products = _list(json['products'], ProductDto.fromJson);

  final String key;
  final List<ProductDto> products;
}

class ProductDto {
  ProductDto.fromJson(Json json)
    : id = json['id'] as String,
      name = json['name'] as String,
      restaurant = json['restaurant'] as String,
      category = (json['category'] as Json)['name'] as String,
      description = json['description'] as String,
      price = (json['price'] as num).toDouble(),
      oldPrice = (json['oldPrice'] as num?)?.toDouble(),
      rating = (json['rating'] as num).toDouble(),
      minMinutes = (json['deliveryTime'] as Json)['min'] as int,
      maxMinutes = (json['deliveryTime'] as Json)['max'] as int,
      imageHue = (json['imageHue'] as num).toDouble(),
      tags = [
        for (final tag in (json['tags'] as List? ?? const [])) tag as String,
      ],
      isFavorite = json['isFavorite'] as bool? ?? false;

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
  final double imageHue;
  final List<String> tags;
  final bool isFavorite;
}

class ProductListDto {
  ProductListDto.fromJson(Json json)
    : data = _list(json['data'], ProductDto.fromJson);

  final List<ProductDto> data;
}

class AddonDto {
  AddonDto.fromJson(Json json)
    : id = json['id'] as String,
      name = json['name'] as String,
      price = (json['price'] as num).toDouble();

  final String id;
  final String name;
  final double price;
}

class ProductDetailDto {
  ProductDetailDto.fromJson(Json json)
    : summary = ProductDto.fromJson(json),
      ingredients = json['ingredients'] as String,
      addons = _list(json['addons'], AddonDto.fromJson);

  final ProductDto summary;
  final String ingredients;
  final List<AddonDto> addons;
}

// Carrinho: toda operação devolve o carrinho completo atualizado.

class CartItemDto {
  CartItemDto.fromJson(Json json)
    : id = json['id'] as int,
      productId = (json['product'] as Json)['id'] as String,
      name = (json['product'] as Json)['name'] as String,
      imageHue = ((json['product'] as Json)['imageHue'] as num).toDouble(),
      isAvailable = (json['product'] as Json)['isAvailable'] as bool? ?? true,
      quantity = json['quantity'] as int,
      addons = _list(json['addons'], AddonDto.fromJson),
      notes = json['notes'] as String? ?? '',
      unitPrice = (json['unitPrice'] as num).toDouble(),
      total = (json['total'] as num).toDouble();

  final int id;
  final String productId;
  final String name;
  final double imageHue;
  final bool isAvailable;
  final int quantity;
  final List<AddonDto> addons;
  final String notes;
  final double unitPrice;
  final double total;
}

class CartDto {
  CartDto.fromJson(Json json)
    : items = _list(json['items'], CartItemDto.fromJson),
      couponCode = (json['coupon'] as Json?)?['code'] as String?,
      couponApplied = (json['coupon'] as Json?)?['applied'] as bool? ?? false,
      couponPercentOff = (json['coupon'] as Json?)?['percentOff'] as int? ?? 0,
      itemCount = (json['summary'] as Json)['itemCount'] as int,
      subtotal = ((json['summary'] as Json)['subtotal'] as num).toDouble(),
      deliveryFee = ((json['summary'] as Json)['deliveryFee'] as num)
          .toDouble(),
      discount = ((json['summary'] as Json)['discount'] as num).toDouble(),
      total = ((json['summary'] as Json)['total'] as num).toDouble();

  final List<CartItemDto> items;
  final String? couponCode;
  final bool couponApplied;
  final int couponPercentOff;
  final int itemCount;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
}

// Checkout

class AddressDto {
  AddressDto.fromJson(Json json)
    : id = json['id'] as int,
      label = json['label'] as String,
      street = json['street'] as String,
      line = json['line'] as String,
      cityLine = json['cityLine'] as String,
      isSelected = json['isSelected'] as bool? ?? false;

  final int id;
  final String label;
  final String street;
  final String line;
  final String cityLine;
  final bool isSelected;
}

class PaymentMethodDto {
  PaymentMethodDto.fromJson(Json json)
    : id = json['id'] as int,
      type = json['type'] as String,
      label = json['label'] as String,
      detail = json['detail'] as String;

  final int id;
  final String type;
  final String label;
  final String detail;
}

// Pedidos

class OrderSummaryDto {
  OrderSummaryDto.fromJson(Json json)
    : code = json['code'] as String,
      status = json['status'] as String,
      statusLabel = json['statusLabel'] as String,
      step = json['step'] as int,
      createdAt = DateTime.parse(json['createdAt'] as String),
      total = (json['total'] as num).toDouble(),
      itemCount = json['itemCount'] as int,
      itemsSummary = json['itemsSummary'] as String,
      imageHue = ((json['thumbnail'] as Json)['imageHue'] as num).toDouble();

  final String code;
  final String status;
  final String statusLabel;
  final int step;
  final DateTime createdAt;
  final double total;
  final int itemCount;
  final String itemsSummary;
  final double imageHue;
}

class OrderListDto {
  OrderListDto.fromJson(Json json)
    : data = _list(json['data'], OrderSummaryDto.fromJson),
      total = (json['meta'] as Json)['total'] as int;

  final List<OrderSummaryDto> data;
  // Total do filtro, usado no badge de pedidos em andamento.
  final int total;
}

class TimelineStepDto {
  TimelineStepDto.fromJson(Json json)
    : step = json['step'] as int,
      label = json['label'] as String,
      state = json['state'] as String,
      reachedAt = switch (json['reachedAt']) {
        final String value => DateTime.parse(value),
        _ => null,
      };

  final int step;
  final String label;
  final String state;
  final DateTime? reachedAt;
}

class OrderItemDto {
  OrderItemDto.fromJson(Json json)
    : name = json['name'] as String,
      restaurant = json['restaurant'] as String? ?? '',
      imageHue = (json['imageHue'] as num).toDouble(),
      quantity = json['quantity'] as int,
      total = (json['total'] as num).toDouble();

  final String name;
  final String restaurant;
  final double imageHue;
  final int quantity;
  final double total;
}

// Detalhe do pedido; também é a resposta de POST /orders.
class OrderDetailDto {
  OrderDetailDto.fromJson(Json json)
    : summary = OrderSummaryDto.fromJson(json),
      hint = json['hint'] as String,
      timeline = _list(json['timeline'], TimelineStepDto.fromJson),
      minMinutes = (json['estimatedDelivery'] as Json)['minMinutes'] as int,
      maxMinutes = (json['estimatedDelivery'] as Json)['maxMinutes'] as int,
      items = _list(json['items'], OrderItemDto.fromJson),
      addressLine = (json['address'] as Json)['line'] as String,
      paymentType = (json['payment'] as Json)['type'] as String,
      paymentLabel = (json['payment'] as Json)['label'] as String,
      subtotal = ((json['amounts'] as Json)['subtotal'] as num).toDouble(),
      deliveryFee = ((json['amounts'] as Json)['deliveryFee'] as num)
          .toDouble(),
      discount = ((json['amounts'] as Json)['discount'] as num).toDouble(),
      courierName = (json['courier'] as Json)['name'] as String,
      courierVehicle = (json['courier'] as Json)['vehicle'] as String;

  final OrderSummaryDto summary;
  final String hint;
  final List<TimelineStepDto> timeline;
  final int minMinutes;
  final int maxMinutes;
  final List<OrderItemDto> items;
  final String addressLine;
  final String paymentType;
  final String paymentLabel;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final String courierName;
  final String courierVehicle;
}

// "Pedir novamente": o carrinho novo e os produtos que saíram do cardápio.
class ReorderDto {
  ReorderDto.fromJson(Json json)
    : cart = CartDto.fromJson(json['cart'] as Json),
      skippedProductIds = [
        for (final id in (json['skippedProductIds'] as List? ?? const []))
          id as String,
      ];

  final CartDto cart;
  final List<String> skippedProductIds;
}

class FavoriteListDto {
  FavoriteListDto.fromJson(Json json)
    : count = (json['data'] as List? ?? const []).length;

  // A barra inferior só usa a quantidade.
  final int count;
}
