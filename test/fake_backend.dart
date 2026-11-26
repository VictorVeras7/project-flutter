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

// Pedido guardado no back-end falso.
class FakeOrder {
  FakeOrder(
    this.id,
    this.items, {
    this.status = 'live',
    this.step = 1,
    this.paymentType = 'pix',
    this.paymentLabel = 'PIX',
    this.addressLine = 'Rua das Palmeiras, 128 · apto 42',
    required this.createdAt,
  });

  final int id;
  // (productId, quantidade).
  final List<(String, int)> items;
  String status;
  int step;
  final String paymentType;
  final String paymentLabel;
  final String addressLine;
  final DateTime createdAt;

  String get code => 'RG-$id';

  // Uma etapa por leitura; na última, o pedido é entregue.
  void advance() {
    step++;
    if (step >= 4) {
      step = 4;
      status = 'done';
    }
  }
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

  // Endereços como no seed do servidor; o primeiro é o selecionado.
  final addresses = <Map<String, Object?>>[
    _address(1, 'Casa', 'Rua das Palmeiras, 128', 'apto 42', 'Pinheiros'),
    _address(2, 'Trabalho', 'Av. Faria Lima, 3400', '9º andar', 'Itaim Bibi'),
  ];
  var selectedAddressId = 1;
  // Pedidos criados: addressId e paymentMethodId enviados.
  final orders = <Map<String, Object?>>[];
  // Histórico do servidor: um entregue e um cancelado, como no seed.
  final placed = <FakeOrder>[
    FakeOrder(
      10391,
      [('p2', 1)],
      status: 'done',
      step: 4,
      createdAt: DateTime.utc(2026, 9, 12, 19, 14),
    ),
    FakeOrder(
      10298,
      [('p5', 1)],
      status: 'cancel',
      step: 1,
      createdAt: DateTime.utc(2026, 8, 28, 19, 14),
    ),
  ];
  // Cada leitura de um pedido em andamento avança uma etapa, no lugar dos
  // 20 s do servidor.
  var advanceOnRead = true;

  // Pedido em andamento já existente (para a aba e o acompanhamento).
  FakeOrder seedLiveOrder({int step = 2}) {
    final order = FakeOrder(
      10500 + placed.length,
      [('p1', 2)],
      step: step,
      createdAt: DateTime.now().toUtc(),
    );
    placed.insert(0, order);
    return order;
  }

  static const paymentMethods = [
    {'id': 1, 'type': 'pix', 'label': 'PIX', 'detail': 'Aprovação imediata'},
    {
      'id': 2,
      'type': 'credit',
      'label': 'Cartão de crédito',
      'detail': 'Visa •••• 4410',
    },
    {
      'id': 4,
      'type': 'cash',
      'label': 'Dinheiro',
      'detail': 'Pagamento na entrega',
    },
  ];

  static Map<String, Object?> _address(
    int id,
    String label,
    String street,
    String? complement,
    String neighborhood, [
    String city = 'São Paulo',
  ]) => {
    'id': id,
    'label': label,
    'cep': '05422-030',
    'street': street,
    'complement': complement,
    'neighborhood': neighborhood,
    'city': city,
    'line': complement == null || complement.isEmpty
        ? street
        : '$street · $complement',
    'cityLine': '$neighborhood · $city',
  };

  List<Map<String, Object?>> _addressList() => [
    for (final a in addresses)
      {...a, 'isSelected': a['id'] == selectedAddressId},
  ];

  // Coloca um item no carrinho antes de abrir o app.
  void seedCart(
    String productId, {
    int quantity = 1,
    List<String> addonIds = const [],
    String notes = '',
  }) => cart.add(FakeLine(_nextLineId++, productId, quantity, addonIds, notes));

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
          'selectedAddress': {
            'street': addresses.firstWhere(
              (a) => a['id'] == selectedAddressId,
            )['street'],
          },
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
        final addonIds = [...(body['addonIds'] as List).cast<String>()]..sort();
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
      case ('GET', '/addresses'):
        return _json({'data': _addressList()});
      case ('POST', '/addresses'):
        final cep = (body['cep'] as String).replaceAll(RegExp(r'\D'), '');
        if (cep.length != 8) {
          return _error(400, 'VALIDATION_ERROR', 'Dados inválidos.', {
            'cep': 'CEP inválido.',
          });
        }
        final created = _address(
          addresses.length + 10,
          body['label'] as String,
          body['street'] as String,
          body['complement'] as String?,
          body['neighborhood'] as String,
          body['city'] as String,
        );
        addresses.add(created);
        return _json({...created, 'isSelected': false}, 201);
      case ('GET', '/payment-methods'):
        return _json({'data': paymentMethods});
      case ('POST', '/orders'):
        if (cart.isEmpty) {
          return _error(422, 'EMPTY_CART', 'Seu carrinho está vazio.');
        }
        final payment = paymentMethods.firstWhere(
          (p) => p['id'] == body['paymentMethodId'],
        );
        final address = addresses.firstWhere(
          (a) => a['id'] == body['addressId'],
        );
        orders.add(body);
        final order = FakeOrder(
          10482,
          [for (final line in cart) (line.productId, line.quantity)],
          paymentType: payment['type'] as String,
          paymentLabel: payment['label'] as String,
          addressLine: address['line'] as String,
          createdAt: DateTime.now().toUtc(),
        );
        placed.insert(0, order);
        cart.clear();
        coupon = null;
        return _json(_orderJson(order), 201);
      case ('GET', '/orders'):
        final live = request.url.queryParameters['group'] == 'live';
        final list = [
          for (final o in placed)
            if ((o.status == 'live') == live) o,
        ];
        return _json({
          'data': [for (final o in list) _orderJson(o)],
          'meta': {'total': list.length},
        });
      case ('GET', '/favorites'):
        return _json({
          'data': [
            for (final p in _withFavorites())
              if (favorites.contains(p['id'])) p,
          ],
        });
      case ('PUT', '/cart/coupon'):
        if ((body['code'] as String).toUpperCase() != 'RANGO10') {
          return _error(422, 'INVALID_COUPON', 'Cupom inválido.');
        }
        coupon = 'RANGO10';
        return _cart();
    }
    if (path.startsWith('/orders/')) {
      final code = path.split('/')[2];
      final order = placed.where((o) => o.code == code).firstOrNull;
      if (order == null) {
        return _error(404, 'ORDER_NOT_FOUND', 'Pedido não encontrado.');
      }
      if (path.endsWith('/reorder')) {
        cart.clear();
        final skipped = <String>[];
        for (final (productId, quantity) in order.items) {
          if (products.any((p) => p['id'] == productId)) {
            seedCart(productId, quantity: quantity);
          } else {
            skipped.add(productId);
          }
        }
        return _json({
          'cart': jsonDecode(utf8.decode(_cart().bodyBytes)),
          'skippedProductIds': skipped,
        });
      }
      if (advanceOnRead && order.status == 'live') order.advance();
      return _json(_orderJson(order));
    }
    if (path.startsWith('/addresses/') && path.endsWith('/select')) {
      final id = int.parse(path.split('/')[2]);
      selectedAddressId = id;
      return _json(_addressList().firstWhere((a) => a['id'] == id));
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

  static const _steps = [
    'Pedido recebido',
    'Pedido confirmado',
    'Em preparação',
    'Saiu para entrega',
    'Entregue',
  ];
  static const _hints = [
    'Aguardando o restaurante',
    'O restaurante aceitou seu pedido',
    'Seu pedido está sendo preparado',
    'O entregador está levando seu pedido',
    'Bom apetite!',
  ];

  // Mesmo formato de GET /orders/:id do servidor.
  Map<String, Object?> _orderJson(FakeOrder o) {
    final items = [
      for (final (productId, quantity) in o.items)
        (products.firstWhere((p) => p['id'] == productId), quantity),
    ];
    final subtotal = items.fold<num>(
      0,
      (s, i) => s + (i.$1['price'] as num) * i.$2,
    );
    final fee = subtotal >= 60 ? 0 : 7.9;
    return {
      'id': o.id,
      'code': o.code,
      'status': o.status,
      'statusLabel': o.status == 'cancel'
          ? 'Cancelado'
          : o.status == 'done'
          ? 'Entregue'
          : _steps[o.step],
      'step': o.step,
      'createdAt': o.createdAt.toIso8601String(),
      'total': subtotal + fee,
      'itemCount': items.fold<int>(0, (s, i) => s + i.$2),
      'itemsSummary': [for (final i in items) '${i.$2}× ${i.$1['name']}']
          .join(', '),
      'thumbnail': {'imageHue': items.first.$1['imageHue']},
      'hint': o.status == 'cancel'
          ? 'Este pedido foi cancelado'
          : _hints[o.step],
      'timeline': [
        for (var step = 0; step < _steps.length; step++)
          {
            'step': step,
            'label': _steps[step],
            'state': step < o.step || (step == o.step && o.status != 'live')
                ? 'done'
                : step == o.step
                ? 'current'
                : 'upcoming',
            'reachedAt': step <= o.step
                ? o.createdAt.add(Duration(minutes: step * 5)).toIso8601String()
                : null,
          },
      ],
      'estimatedDelivery': {'minMinutes': 25, 'maxMinutes': 35},
      'items': [
        for (final (p, quantity) in items)
          {
            'name': p['name'],
            'restaurant': p['restaurant'],
            'imageHue': p['imageHue'],
            'quantity': quantity,
            'total': (p['price'] as num) * quantity,
          },
      ],
      'address': {'line': o.addressLine},
      'payment': {'type': o.paymentType, 'label': o.paymentLabel},
      'amounts': {
        'subtotal': subtotal,
        'deliveryFee': fee,
        'discount': 0,
        'total': subtotal + fee,
      },
      'courier': {'name': 'Rafael Souza', 'vehicle': 'Honda CG 160'},
    };
  }

  http.Response _cart([int status = 200]) {
    final items = [for (final line in cart) _item(line)];
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

  http.Response _error(
    int status,
    String code,
    String message, [
    Map<String, String> fields = const {},
  ]) => _json({
    'error': {
      'code': code,
      'message': message,
      'details': [
        for (final MapEntry(:key, :value) in fields.entries)
          {'field': key, 'message': value},
      ],
    },
  }, status);
}

// Sessão salva no aparelho (shared_preferences em memória).
void setSavedSession(String? refreshToken) {
  SharedPreferences.setMockInitialValues({'refresh_token': ?refreshToken});
}
