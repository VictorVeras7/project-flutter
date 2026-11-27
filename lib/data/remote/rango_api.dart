import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../search.dart';
import 'api_models.dart';
import 'platform.dart';

// Erro da API já com a mensagem para exibir. `fields` traz erros por campo do formulário.
class ApiException implements Exception {
  const ApiException(this.code, this.message, [this.fields = const {}]);

  final String code;
  final String message;
  final Map<String, String> fields;

  @override
  String toString() => 'ApiException($code, $message)';
}

// Sem resposta do servidor (sem rede ou servidor fora do ar).
const networkError = 'NETWORK_ERROR';
const _sessionEndedCodes = {
  'INVALID_REFRESH_TOKEN',
  'SESSION_EXPIRED',
  'INVALID_TOKEN',
  'UNAUTHORIZED',
};
// Erro único para o fim da sessão: o app volta ao login e mostra só este aviso.
const _sessionExpired = ApiException(
  'SESSION_EXPIRED',
  'Sua sessão expirou. Entre novamente.',
);

class RangoApi {
  RangoApi({http.Client? client, SessionStorage? storage, String? baseUrl})
    : _client = client ?? http.Client(),
      _storage = storage ?? SessionStorage(),
      _baseUrl = baseUrl ?? apiBaseUrl;

  final http.Client _client;
  final SessionStorage _storage;
  final String _baseUrl;

  String? _accessToken;
  String? _refreshToken;
  var _keepSignedIn = false;
  // Só uma renovação por vez: reutilizar um refresh token antigo encerra todas as sessões.
  Completer<void>? _refreshing;

  // Chamado quando a sessão não pode mais ser renovada (o app volta para o login).
  void Function() onSessionExpired = () {};

  // Sessão

  Future<String> login(String email, String password, bool keepSignedIn) async {
    final session = SessionDto.fromJson(
      await _call(
        'POST',
        '/auth/login',
        auth: false,
        body: {
          'email': email.trim(),
          'password': password,
          'keepSignedIn': keepSignedIn,
        },
      ),
    );
    await _startSession(session, keepSignedIn);
    return session.userName;
  }

  Future<String> register(RegisterRequest request) async {
    final session = SessionDto.fromJson(
      await _call(
        'POST',
        '/auth/register',
        auth: false,
        body: request.toJson(),
      ),
    );
    await _startSession(session, true);
    return session.userName;
  }

  // Abertura do app: se houver refresh token salvo, renova a sessão.
  // Sem rede, a sessão continua valendo e é renovada na próxima chamada.
  Future<bool> restoreSession() async {
    _refreshToken = await _storage.readRefreshToken();
    if (_refreshToken == null) return false;
    _keepSignedIn = true;
    try {
      await _refreshSession(null);
      return true;
    } on ApiException catch (e) {
      return e.code == networkError;
    }
  }

  // Catálogo

  Future<HomeDto> home() async => HomeDto.fromJson(await _call('GET', '/home'));

  Future<List<ProductDto>> products(String categorySlug) async =>
      ProductListDto.fromJson(
        await _call('GET', '/products?category=$categorySlug&pageSize=50'),
      ).data;

  Future<ProductDetailDto> product(String productId) async =>
      ProductDetailDto.fromJson(await _call('GET', '/products/$productId'));

  Future<void> setFavorite(String productId, bool favorite) =>
      _call(favorite ? 'PUT' : 'DELETE', '/favorites/$productId');

  // Busca: só manda os filtros que fogem do padrão ("Todos", "Qualquer").
  Future<ProductListDto> searchProducts(
    String query,
    SearchFilters filters, {
    String? categorySlug,
  }) async {
    final params = {
      if (query.isNotEmpty) 'q': query,
      'category': ?categorySlug,
      if (filters.hasPrice) 'maxPrice': '${filters.maxPrice}',
      if (filters.hasRating) 'minRating': '${filters.minRating}',
      if (filters.hasTime) 'maxDeliveryTime': '${filters.maxTime}',
      'sort': filters.sort.apiKey,
      'pageSize': '50',
    };
    return ProductListDto.fromJson(
      await _call(
        'GET',
        Uri(path: '/products', queryParameters: params).toString(),
      ),
    );
  }

  // Sem termo: os mais pedidos.
  Future<List<String>> searchSuggestions() async =>
      stringList(await _call('GET', '/search/suggestions'));

  // Até 6, mais recente primeiro.
  Future<List<String>> recentSearches() async =>
      stringList(await _call('GET', '/search/recent'));

  // Devolve a lista atualizada.
  Future<List<String>> saveRecentSearch(String term) async =>
      stringList(await _call('POST', '/search/recent', body: {'term': term}));

  Future<void> clearRecentSearches() => _call('DELETE', '/search/recent');

  // Carrinho: toda chamada devolve o carrinho completo atualizado.

  Future<CartDto> cart() async => CartDto.fromJson(await _call('GET', '/cart'));

  // Mesmo produto com os mesmos adicionais soma na linha existente.
  Future<CartDto> addToCart(
    String productId, {
    int quantity = 1,
    List<String> addonIds = const [],
    String notes = '',
  }) async => CartDto.fromJson(
    await _call(
      'POST',
      '/cart/items',
      body: {
        'productId': productId,
        'quantity': quantity,
        'addonIds': addonIds,
        'notes': notes,
      },
    ),
  );

  Future<CartDto> setCartQuantity(int itemId, int quantity) async =>
      CartDto.fromJson(
        await _call(
          'PATCH',
          '/cart/items/$itemId',
          body: {'quantity': quantity},
        ),
      );

  Future<CartDto> removeCartItem(int itemId) async =>
      CartDto.fromJson(await _call('DELETE', '/cart/items/$itemId'));

  Future<CartDto> clearCart() async =>
      CartDto.fromJson(await _call('DELETE', '/cart'));

  Future<CartDto> applyCoupon(String code) async => CartDto.fromJson(
    await _call('PUT', '/cart/coupon', body: {'code': code}),
  );

  // Checkout

  // Selecionado primeiro.
  Future<List<AddressDto>> addresses() async => [
    for (final item
        in ((await _call('GET', '/addresses')) as Json)['data'] as List)
      AddressDto.fromJson(item as Json),
  ];

  Future<AddressDto> createAddress({
    required String label,
    required String cep,
    required String street,
    required String complement,
    required String neighborhood,
    required String city,
  }) async => AddressDto.fromJson(
    await _call(
      'POST',
      '/addresses',
      body: {
        'label': label,
        'cep': cep,
        'street': street,
        'complement': complement,
        'neighborhood': neighborhood,
        'city': city,
      },
    ),
  );

  // "Usar este endereço": vira o endereço de entrega no servidor.
  Future<AddressDto> selectAddress(int id) async =>
      AddressDto.fromJson(await _call('POST', '/addresses/$id/select'));

  Future<List<PaymentMethodDto>> paymentMethods() async => [
    for (final item
        in ((await _call('GET', '/payment-methods')) as Json)['data'] as List)
      PaymentMethodDto.fromJson(item as Json),
  ];

  // Transforma o carrinho do servidor em pedido; o servidor esvazia o carrinho.
  Future<OrderDetailDto> placeOrder({
    required int addressId,
    required int paymentMethodId,
  }) async => OrderDetailDto.fromJson(
    await _call(
      'POST',
      '/orders',
      body: {'addressId': addressId, 'paymentMethodId': paymentMethodId},
    ),
  );

  // Pedidos

  // "Em andamento" ou "Anteriores", mais recentes primeiro.
  Future<OrderListDto> orders(String group, {int pageSize = 50}) async =>
      OrderListDto.fromJson(
        await _call('GET', '/orders?group=$group&pageSize=$pageSize'),
      );

  // O servidor avança a etapa do pedido na leitura (simulação a cada 20 s).
  Future<OrderDetailDto> order(String code) async =>
      OrderDetailDto.fromJson(await _call('GET', '/orders/$code'));

  // Substitui o carrinho pelos itens do pedido, com os preços atuais.
  Future<ReorderDto> reorder(String code) async =>
      ReorderDto.fromJson(await _call('POST', '/orders/$code/reorder'));

  Future<FavoriteListDto> favorites() async =>
      FavoriteListDto.fromJson(await _call('GET', '/favorites'));

  // Infra

  // Envia a requisição; se o access token venceu, renova a sessão e tenta de novo uma vez.
  Future<dynamic> _call(
    String method,
    String path, {
    bool auth = true,
    Object? body,
  }) async {
    // Sessão restaurada sem rede: ainda não há access token, então renova antes de chamar.
    if (auth && _accessToken == null && _refreshToken != null) {
      await _refreshSession(null);
    }
    final usedToken = _accessToken;
    var response = await _send(method, path, auth, body);
    if (_ok(response)) return _decode(response);

    var error = _readError(response);
    if (auth && response.statusCode == 401 && error.code == 'TOKEN_EXPIRED') {
      await _refreshSession(usedToken);
      response = await _send(method, path, auth, body);
      if (_ok(response)) return _decode(response);
      error = _readError(response);
    }
    if (auth && _sessionEndedCodes.contains(error.code)) {
      await _endSession();
      throw _sessionExpired;
    }
    throw error;
  }

  Future<http.Response> _send(
    String method,
    String path,
    bool auth,
    Object? body,
  ) async {
    final request = http.Request(method, Uri.parse(_baseUrl + path));
    final token = _accessToken;
    if (auth && token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    try {
      return await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 15)),
      );
    } on Exception {
      throw const ApiException(
        networkError,
        'Não foi possível conectar ao servidor. Tente novamente.',
      );
    }
  }

  Future<void> _refreshSession(String? expiredToken) async {
    // Outra requisição já está renovando: espera por ela em vez de usar o mesmo token.
    final running = _refreshing;
    if (running != null) return running.future;
    // Outra requisição já renovou enquanto esta esperava.
    if (_accessToken != expiredToken) return;

    final completer = _refreshing = Completer<void>();
    // Quem não espera pela renovação não deixa o erro escapar como não tratado.
    completer.future.ignore();
    try {
      final token = _refreshToken;
      if (token == null) {
        await _endSession();
        throw _sessionExpired;
      }
      final response = await _send('POST', '/auth/refresh', false, {
        'refreshToken': token,
      });
      if (!_ok(response)) {
        await _endSession();
        throw _sessionExpired;
      }
      await _startSession(
        SessionDto.fromJson(_decode(response) as Json),
        _keepSignedIn,
      );
      completer.complete();
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _refreshing = null;
    }
  }

  Future<void> _startSession(SessionDto session, bool keep) async {
    _accessToken = session.accessToken;
    _refreshToken = session.refreshToken;
    _keepSignedIn = keep;
    // O refresh token é rotacionado a cada renovação: sempre salva o novo.
    await _storage.saveRefreshToken(keep ? session.refreshToken : null);
  }

  Future<void> _endSession() async {
    final hadSession = _accessToken != null || _refreshToken != null;
    _accessToken = null;
    _refreshToken = null;
    await _storage.saveRefreshToken(null);
    if (hadSession) onSessionExpired();
  }

  bool _ok(http.Response response) =>
      response.statusCode >= 200 && response.statusCode < 300;

  dynamic _decode(http.Response response) => response.body.isEmpty
      ? null
      : jsonDecode(utf8.decode(response.bodyBytes));

  ApiException _readError(http.Response response) {
    try {
      final error = ErrorDto.fromJson(
        (_decode(response) as Json)['error'] as Json,
      );
      return ApiException(error.code, error.message, error.fields);
    } on Object {
      return ApiException(
        'HTTP_${response.statusCode}',
        'Algo deu errado. Tente novamente.',
      );
    }
  }
}
