import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rango/data/remote/rango_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, Object?> product(
  String id,
  String name,
  String category,
  List<String> tags, {
  double price = 30,
  double? oldPrice,
  bool favorite = false,
}) => {
  'id': id,
  'name': name,
  'restaurant': 'Casa do Burger',
  'category': {'name': category, 'slug': category.toLowerCase()},
  'description': 'Descrição de $name',
  'price': price,
  'oldPrice': oldPrice,
  'rating': 4.8,
  'deliveryTime': {'min': 25, 'max': 35},
  'imageHue': 48,
  'tags': tags,
  'isFavorite': favorite,
};

const addons = [
  {'id': 'a1', 'name': 'Bacon extra', 'price': 4},
  {'id': 'a2', 'name': 'Cheddar extra', 'price': 3.5},
];

// Linha do carrinho guardada no back-end falso.
class FakeLine {
  FakeLine(this.id, this.productId, this.quantity, this.addonIds, this.notes);

  final int id;
  final String productId;
  int quantity;
  final List<String> addonIds;
  String notes;
}

// Back-end em memória com o mesmo contrato da API local (porta 3333).
// Carrinho com as regras do servidor: entrega de R$ 7,90, grátis a partir
// de R$ 60, e o cupom RANGO10 com 10% sobre o subtotal.
class FakeBackend {
  FakeBackend({this.homeDelay = Duration.zero});

  final Duration homeDelay;
  final requests = <String>[];
  final cart = <FakeLine>[];
  String? coupon;
  var _nextLineId = 1;
  var expireNextHome = false;
  final favorites = <String>{'p2'};

  int get cartCount => cart.fold(0, (sum, line) => sum + line.quantity);

  // Coloca um item no carrinho antes de abrir o app.
  void seedCart(
    String productId, {
    int quantity = 1,
    List<String> addonIds = const [],
    String notes = '',
  }) => cart.add(
    FakeLine(_nextLineId++, productId, quantity, addonIds, notes),
  );

  late final products = [
    product('p1', 'Burger duplo cheddar', 'Pizza', [
      'offers',
      'popular',
    ], oldPrice: 42.9),
    product('p2', 'Pizza margherita', 'Pizza', ['popular', 'recommended']),
    product('p5', 'Brownie com sorvete', 'Bebidas', ['fast']),
  ];

  RangoApi api() =>
      RangoApi(client: MockClient(_handle), baseUrl: 'http://api');

  Future<http.Response> _handle(http.Request request) async {
    final path = request.url.path;
    requests.add('${request.method} $path');
    final body = request.body.isEmpty
        ? const <String, Object?>{}
        : jsonDecode(request.body) as Map<String, Object?>;

    switch ((request.method, path)) {
      case ('POST', '/auth/login'):
        if (body['password'] != 'rango123') {
          return _error(
            401,
            'INVALID_CREDENTIALS',
            'E-mail ou senha incorretos.',
          );
        }
        return _session();
      case ('POST', '/auth/register'):
        if (body['email'] == 'marina.alves@email.com') {
          return _error(409, 'EMAIL_IN_USE', 'Este e-mail já está cadastrado.');
        }
        return _session(name: body['name'] as String);
      case ('POST', '/auth/refresh'):
        if (body['refreshToken'] != 'refresh-1') {
          return _error(401, 'INVALID_REFRESH_TOKEN', 'Sessão inválida.');
        }
        return _session();
      case ('GET', '/home'):
        if (homeDelay > Duration.zero) await Future<void>.delayed(homeDelay);
        if (expireNextHome) {
          expireNextHome = false;
          return _error(401, 'INVALID_TOKEN', 'Token inválido.');
        }
        return _json({
          'user': {'name': 'Marina Alves'},
          'selectedAddress': {'street': 'Rua das Palmeiras, 128'},
          'cartItemCount': cartCount,
          'unreadNotifications': 2,
          'categories': [
            {'name': 'Pizza', 'slug': 'pizza'},
            {'name': 'Bebidas', 'slug': 'bebidas'},
          ],
          'sections': [
            for (final key in ['offers', 'popular', 'recommended', 'fast'])
              {
                'key': key,
                'products': [
                  for (final p in _withFavorites())
                    if ((p['tags'] as List).contains(key)) p,
                ],
              },
          ],
        });
      case ('GET', '/products'):
        final slug = request.url.queryParameters['category'];
        return _json({
          'data': [
            for (final p in _withFavorites())
              if ((p['category'] as Map)['slug'] == slug) p,
          ],
        });
      case ('GET', '/cart'):
        return _cart();
      case ('POST', '/cart/items'):
        final productId = body['productId'] as String;
        final addonIds = [...(body['addonIds'] as List).cast<String>()]
          ..sort();
        final notes = body['notes'] as String;
        final quantity = body['quantity'] as int;
        final existing = cart
            .where(
              (l) =>
                  l.productId == productId &&
                  l.addonIds.join(',') == addonIds.join(','),
            )
            .firstOrNull;
        if (existing != null) {
          existing.quantity += quantity;
          if (notes.isNotEmpty) existing.notes = notes;
        } else {
          seedCart(
            productId,
            quantity: quantity,
            addonIds: addonIds,
            notes: notes,
          );
        }
        return _cart(201);
      case ('DELETE', '/cart'):
        cart.clear();
        return _cart();
      case ('PUT', '/cart/coupon'):
        if ((body['code'] as String).toUpperCase() != 'RANGO10') {
          return _error(422, 'INVALID_COUPON', 'Cupom inválido.');
        }
        coupon = 'RANGO10';
        return _cart();
    }
    if (path.startsWith('/cart/items/')) {
      final id = int.parse(path.split('/').last);
      final line = cart.where((l) => l.id == id).firstOrNull;
      if (line == null) {
        return _error(404, 'NOT_FOUND', 'Item do carrinho não encontrado.');
      }
      if (request.method == 'DELETE') {
        cart.remove(line);
      } else {
        line.quantity = body['quantity'] as int;
      }
      return _cart();
    }
    if (request.method == 'GET' && path.startsWith('/products/')) {
      final id = path.split('/').last;
      final found = _withFavorites().where((p) => p['id'] == id).firstOrNull;
      if (found == null) {
        return _error(404, 'PRODUCT_NOT_FOUND', 'Produto não encontrado.');
      }
      return _json({
        ...found,
        'ingredients': 'Pão brioche, cheddar inglês. Molho da casa.',
        'addons': addons,
      });
    }
    if (path.startsWith('/favorites/')) {
      final id = path.split('/').last;
      request.method == 'PUT' ? favorites.add(id) : favorites.remove(id);
      return http.Response('', 204);
    }
    return _error(404, 'NOT_FOUND', 'Rota não encontrada.');
  }

  http.Response _cart([int status = 200]) {
    final items = [
      for (final line in cart) _item(line),
    ];
    final subtotal = items.fold<double>(0, (s, i) => s + (i['total'] as num));
    final fee = subtotal == 0 || subtotal >= 60 ? 0.0 : 7.9;
    final discount = coupon == null ? 0.0 : subtotal * 0.1;
    return _json({
      'items': items,
      'coupon': coupon == null
          ? null
          : {
              'code': coupon,
              'description': '10% de desconto',
              'percentOff': 10,
              'minSubtotal': 0,
              'applied': subtotal > 0,
            },
      'summary': {
        'itemCount': cartCount,
        'subtotal': subtotal,
        'deliveryFee': fee,
        'discount': discount,
        'total': subtotal + fee - discount,
        'freeDeliveryThreshold': 60,
      },
    }, status);
  }

  Map<String, Object?> _item(FakeLine line) {
    final p = products.firstWhere((p) => p['id'] == line.productId);
    final chosen = [
      for (final a in addons)
        if (line.addonIds.contains(a['id'])) a,
    ];
    final unit =
        (p['price'] as num) +
        chosen.fold<num>(0, (s, a) => s + (a['price'] as num));
    return {
      'id': line.id,
      'product': {
        'id': p['id'],
        'name': p['name'],
        'restaurant': p['restaurant'],
        'imageUrl': null,
        'imageHue': p['imageHue'],
        'isAvailable': true,
      },
      'quantity': line.quantity,
      'addons': chosen,
      'notes': line.notes,
      'unitPrice': unit,
      'total': unit * line.quantity,
    };
  }

  List<Map<String, Object?>> _withFavorites() => [
    for (final p in products) {...p, 'isFavorite': favorites.contains(p['id'])},
  ];

  http.Response _session({String name = 'Marina Alves'}) => _json({
    'accessToken': 'access-1',
    'refreshToken': 'refresh-1',
    'user': {'name': name, 'email': 'marina.alves@email.com'},
  });

  http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json'},
  );

  http.Response _error(int status, String code, String message) => _json({
    'error': {'code': code, 'message': message},
  }, status);
}

// Sessão salva no aparelho (shared_preferences em memória).
void setSavedSession(String? refreshToken) {
  SharedPreferences.setMockInitialValues({'refresh_token': ?refreshToken});
}
