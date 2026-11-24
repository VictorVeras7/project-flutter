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

// Back-end em memória com o mesmo contrato da API local (porta 3333).
class FakeBackend {
  FakeBackend({this.homeDelay = Duration.zero});

  final Duration homeDelay;
  final requests = <String>[];
  var cartCount = 0;
  var expireNextHome = false;
  final favorites = <String>{'p2'};

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
      case ('POST', '/cart/items'):
        cartCount += body['quantity'] as int;
        return _json({
          'items': const [],
          'summary': {'itemCount': cartCount},
        });
    }
    if (path.startsWith('/favorites/')) {
      final id = path.split('/').last;
      request.method == 'PUT' ? favorites.add(id) : favorites.remove(id);
      return http.Response('', 204);
    }
    return _error(404, 'NOT_FOUND', 'Rota não encontrada.');
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
