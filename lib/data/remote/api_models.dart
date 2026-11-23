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

// Carrinho: a Home só usa o total de itens (badge da sacola).

class CartDto {
  CartDto.fromJson(Json json)
    : itemCount = (json['summary'] as Json)['itemCount'] as int;

  final int itemCount;
}
